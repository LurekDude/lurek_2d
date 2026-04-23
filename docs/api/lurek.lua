---@meta
--- Auto-generated Lurek2D API documentation for LuaCATS.

lurek = {}

---@class lurek.ai
lurek.ai = {}

--- Lua wrapper for [`crate::ai::director::AIDirector`].
---@class AIDirector
local AIDirector = {}

--- Returns or performs ambient intensity.
---@return number
function AIDirector:ambientIntensity() end

--- Returns or performs loot factor.
---@return number
function AIDirector:lootFactor() end

--- Returns or performs phase.
---@return string
function AIDirector:phase() end

--- Pushes a gameplay event with the given intensity to the director for awareness analysis.
---@param intensity any
---@return nil
function AIDirector:pushEvent(intensity) end

--- Resets or clears the state.
---@return nil
function AIDirector:reset() end

--- Sets the global narrative tension level (0â€“1 scale).
---@param value any
---@return nil
function AIDirector:setTension(value) end

--- Returns or performs spawn rate factor.
---@return number
function AIDirector:spawnRateFactor() end

--- Returns or performs tension.
---@return number
function AIDirector:tension() end

--- Advances the simulation by one time step.
---@param dt any
---@return nil
function AIDirector:update(dt) end

--- Lua wrapper for [`crate::ai::lod::AILod`].
---@class AILod
local AILod = {}

--- Returns or performs should update.
---@param tier any
---@param frame any
---@return boolean
function AILod:shouldUpdate(tier, frame) end

--- Returns or performs tier count.
---@return integer
function AILod:tierCount() end

--- Returns or performs tier name.
---@param tier any
---@return string
function AILod:tierName(tier) end

--- Lua-side wrapper around an [`AIWorld`].
---@class AIWorld
local AIWorld = {}

--- Registers a new named agent and returns its handle.
---@param name any
---@return Agent
function AIWorld:addAgent(name) end

--- Returns the agent handle for the given name, or nil.
---@param name any
---@return nil
function AIWorld:getAgent(name) end

--- Returns the number of registered agents.
---@return integer
function AIWorld:getAgentCount() end

--- Returns a snapshot of the world-level blackboard.
---@return Blackboard
function AIWorld:getGlobalBlackboard() end

--- Removes an agent by its userdata handle.
---@param agent any
---@return nil
function AIWorld:removeAgent(agent) end

--- Returns the type name of this object.
---@return string
function AIWorld:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function AIWorld:typeOf(name) end

--- Advances all agents by dt seconds, then invokes any custom-model callbacks.
---@param dt any
---@return nil
function AIWorld:update(dt) end

--- Lua-side wrapper for an agent accessed by name through the owning world.
---@class Agent
local Agent = {}

--- Adds a tag to this agent.
---@param tag any
---@return nil
function Agent:addTag(tag) end

--- Returns the agent's local blackboard.
---@return Blackboard
function Agent:getBlackboard() end

--- Returns the name of the current decision model.
---@return string
function Agent:getDecisionModel() end

--- Returns the maximum steering force cap.
---@return number
function Agent:getMaxForce() end

--- Returns the maximum speed cap.
---@return number
function Agent:getMaxSpeed() end

--- Returns the agent's registered name.
---@return string
function Agent:getName() end

--- Returns the agent's current position.
---@return number
function Agent:getPosition() end

--- Returns the agent's scheduling priority.
---@return integer
function Agent:getPriority() end

--- Returns the agent's current velocity.
---@return number
function Agent:getVelocity() end

--- Returns true if the agent has the given tag.
---@param tag any
---@return boolean
function Agent:hasTag(tag) end

--- Removes a tag from this agent.
---@param tag any
---@return nil
function Agent:removeTag(tag) end

--- Installs a Lua-driven decision model on this agent.
---@param callback any
---@return nil
function Agent:setCustomModel(callback) end

--- Sets the active decision model.
---@param model any
---@return nil
function Agent:setDecisionModel(model) end

--- Sets the maximum steering force cap.
---@param v any
---@return nil
function Agent:setMaxForce(v) end

--- Sets the maximum speed cap.
---@param v any
---@return nil
function Agent:setMaxSpeed(v) end

--- Sets the agent's world-space position.
---@param x any
---@param y any
---@return nil
function Agent:setPosition(x, y) end

--- Sets the scheduling priority (higher = earlier).
---@param p any
---@return nil
function Agent:setPriority(p) end

--- Sets the agent's velocity vector.
---@param x any
---@param y any
---@return nil
function Agent:setVelocity(x, y) end

--- Returns the type name of this object.
---@return string
function Agent:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function Agent:typeOf(name) end

--- Lua-side wrapper around a [`BTNode`].
---@class BTNode
local BTNode = {}

--- Adds a child node (Selector, Sequence, or Parallel only).
---@param child_ud any
---@return nil
function BTNode:addChild(child_ud) end

--- Returns the number of direct children.
---@return integer
function BTNode:getChildCount() end

--- Returns the repeat count, or 0 if not a Repeater.
---@return integer
function BTNode:getCount() end

--- Returns the node type as a string.
---@return string
function BTNode:getNodeType() end

--- Resets all running-child memos and repeater counters.
---@return nil
function BTNode:reset() end

--- Sets the single child of a decorator node.
---@param child_ud any
---@return nil
function BTNode:setChild(child_ud) end

--- Sets the repeat count for a Repeater node.
---@param n any
---@return nil
function BTNode:setCount(n) end

--- Sets the failure policy for a Parallel node.
---@param policy any
---@return nil
function BTNode:setFailurePolicy(policy) end

--- Sets the success policy for a Parallel node.
---@param policy any
---@return nil
function BTNode:setSuccessPolicy(policy) end

--- Returns the type name of this object.
---@return string
function BTNode:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function BTNode:typeOf(name) end

--- Lua wrapper for [`crate::ai::bandit::Bandit`].
---@class Bandit
local Bandit = {}

--- Returns or performs arm count.
---@return integer
function Bandit:armCount() end

--- Returns or performs best arm.
---@return integer
function Bandit:bestArm() end

--- Resets or clears the state.
---@return nil
function Bandit:reset() end

--- Returns or performs select.
---@return integer
function Bandit:select() end

--- Returns or performs total pulls.
---@return integer
function Bandit:totalPulls() end

--- Advances the simulation by one time step.
---@param idx any
---@param reward any
---@return nil
function Bandit:update(idx, reward) end

--- Lua-side wrapper around a [`BehaviorTree`].
---@class BehaviorTree
local BehaviorTree = {}

--- Returns a diagnostic snapshot of this behavior tree.
---@return table
function BehaviorTree:getDebugState() end

--- Returns the status from the last tick.
---@return string
function BehaviorTree:getLastStatus() end

--- Sets the root node of this behavior tree.
---@param node_ud any
---@return nil
function BehaviorTree:setRoot(node_ud) end

--- Returns the type name of this object.
---@return string
function BehaviorTree:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function BehaviorTree:typeOf(name) end

--- Lua-side wrapper around a [`Blackboard`].
---@class Blackboard
local Blackboard = {}

--- Removes all local entries.
---@return nil
function Blackboard:clear() end

--- Returns all local keys as a table.
---@return table
function Blackboard:getKeys() end

--- Returns the number of local entries.
---@return integer
function Blackboard:getSize() end

--- Returns true if a value exists under the key.
---@param key any
---@return boolean
function Blackboard:has(key) end

--- Removes the entry at key.
---@param key any
---@return nil
function Blackboard:remove(key) end

--- Stores a boolean under the given key.
---@param key any
---@param value any
---@return nil
function Blackboard:setBool(key, value) end

--- Stores a number under the given key.
---@param key any
---@param value any
---@return nil
function Blackboard:setNumber(key, value) end

--- Stores a string under the given key.
---@param key any
---@param value any
---@return nil
function Blackboard:setString(key, value) end

--- Returns the type name of this object.
---@return string
function Blackboard:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function Blackboard:typeOf(name) end

--- Lua-side wrapper around a [`CommandQueue`].
---@class CommandQueue
local CommandQueue = {}

--- Cancels the front command if it is interruptible.
---@return boolean
function CommandQueue:cancelCurrent() end

--- Discards all queued commands.
---@return nil
function CommandQueue:clear() end

--- Returns the number of queued commands.
---@return integer
function CommandQueue:getCount() end

--- Returns the target coordinates of the front command.
---@return number
function CommandQueue:getCurrentTarget() end

--- Returns the kind of the front command, or nil.
---@return string?
function CommandQueue:getCurrentType() end

--- Returns true if there are no queued commands.
---@return boolean
function CommandQueue:isEmpty() end

--- Returns the type name of this object.
---@return string
function CommandQueue:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function CommandQueue:typeOf(name) end

--- Lua wrapper for [`crate::ai::context_steering::ContextSteering`].
---@class ContextSteering
local ContextSteering = {}

--- Registers a rectangular region this agent must avoid.
---@param min_x any
---@param min_y any
---@param max_x any
---@param max_y any
---@param margin any
---@param weight any
---@return nil
function ContextSteering:addAvoidBounds(min_x, min_y, max_x, max_y, margin, weight) end

--- Adds a wander behavior with jitter and weight to the context steering evaluator.
---@param jitter any
---@param weight any
---@return nil
function ContextSteering:addWander(jitter, weight) end

--- Returns or performs chosen magnitude.
---@return number
function ContextSteering:chosenMagnitude() end

--- Resets or clears the behaviors.
---@return nil
function ContextSteering:clearBehaviors() end

--- Returns or performs slot count.
---@return integer
function ContextSteering:slotCount() end

--- Lua wrapper for [`crate::ai::emotion::EmotionModel`].
---@class EmotionModel
local EmotionModel = {}

--- Returns or performs dominant.
---@return string|nil
function EmotionModel:dominant() end

--- Returns the current float value of this emotion dimension.
---@param name any
---@return number
function EmotionModel:get(name) end

--- Returns `true` if the emotion dimension is currently active and above threshold.
---@param name any
---@return boolean
function EmotionModel:isActive(name) end

--- Resets or clears the state.
---@return nil
function EmotionModel:reset() end

--- Returns or performs trigger.
---@param name any
---@param amount any
---@return nil
function EmotionModel:trigger(name, amount) end

--- Advances the simulation by one time step.
---@param dt any
---@return nil
function EmotionModel:update(dt) end

--- Lua-side wrapper around a [`GOAPPlanner`].
---@class GOAPPlanner
local GOAPPlanner = {}

--- Returns the number of registered actions.
---@return integer
function GOAPPlanner:getActionCount() end

--- Returns the number of registered goals.
---@return integer
function GOAPPlanner:getGoalCount() end

--- Returns the maximum A* planning iterations.
---@return integer
function GOAPPlanner:getMaxIterations() end

--- Sets the maximum A* planning iterations (0 = unlimited).
---@param n any
---@return nil
function GOAPPlanner:setMaxIterations(n) end

--- Returns the type name of this object.
---@return string
function GOAPPlanner:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function GOAPPlanner:typeOf(name) end

--- Lua wrapper for [`crate::ai::genetic::GeneticAlgorithm`].
---@class GeneticAlgorithm
local GeneticAlgorithm = {}

--- Returns or performs best genes.
---@return table
function GeneticAlgorithm:bestGenes() end

--- Runs one generation of the evolutionary algorithm.
---@return nil
function GeneticAlgorithm:evolve() end

--- Returns or performs generation.
---@return integer
function GeneticAlgorithm:generation() end

--- Returns the chromosome as an ordered table of gene values.
---@param idx any
---@return table
function GeneticAlgorithm:getGenes(idx) end

--- Returns or performs pop size.
---@return integer
function GeneticAlgorithm:popSize() end

--- Sets the fitness score used by the genetic algorithm selection step.
---@param idx any
---@param fitness any
---@return nil
function GeneticAlgorithm:setFitness(idx, fitness) end

--- Lua wrapper for [`crate::ai::htn::HTNDomain`].
---@class HTNDomain
local HTNDomain = {}

--- Registers a primitive HTN task with a direct operator function.
---@param name any
---@param preconds any
---@param effects any
---@param clears any
---@return nil
function HTNDomain:addPrimitive(name, preconds, effects, clears) end

--- Returns or performs task count.
---@return integer
function HTNDomain:taskCount() end

--- Lua-side wrapper around an [`InfluenceMap`].
---@class InfluenceMap
local InfluenceMap = {}

--- Adds a named influence layer.
---@param name any
---@return nil
function InfluenceMap:addLayer(name) end

--- Removes all influence values from every layer in the map.
---@return nil
function InfluenceMap:clearAll() end

--- Clears all influence in a layer.
---@param layer any
---@return nil
function InfluenceMap:clearLayer(layer) end

--- Multiplies all influences by a decay factor.
---@param layer any
---@param factor any
---@return nil
function InfluenceMap:decay(layer, factor) end

--- Returns the cell size in world units.
---@return number
function InfluenceMap:getCellSize() end

--- Returns the influence map height in grid cells.
---@return integer
function InfluenceMap:getHeight() end

--- Returns the world-space position of the maximum value.
---@param layer any
---@return number
function InfluenceMap:getMaxPosition(layer) end

--- Returns the world-space position of the minimum value.
---@param layer any
---@return number
function InfluenceMap:getMinPosition(layer) end

--- Returns the influence map width in grid cells.
---@return integer
function InfluenceMap:getWidth() end

--- Returns true if the named layer exists.
---@param name any
---@return boolean
function InfluenceMap:hasLayer(name) end

--- Returns the type name of this object.
---@return string
function InfluenceMap:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function InfluenceMap:typeOf(name) end

--- Lua wrapper for [`crate::ai::needs::NeedSystem`].
---@class NeedSystem
local NeedSystem = {}

--- Registers a new need with the specified name, urgency, and decay rate in the system.
---@param name any
---@param decay_rate any
---@param urgency_threshold any
---@param urgency_factor any
---@return nil
function NeedSystem:addNeed(name, decay_rate, urgency_threshold, urgency_factor) end

--- Returns or performs most urgent.
---@return string|nil
function NeedSystem:mostUrgent() end

--- Returns or performs satisfy.
---@param name any
---@param amount any
---@return nil
function NeedSystem:satisfy(name, amount) end

--- Advances the simulation by one time step.
---@param dt any
---@return nil
function NeedSystem:update(dt) end

--- Returns or performs value of.
---@param name any
---@return number
function NeedSystem:valueOf(name) end

--- Lua wrapper for [`crate::ai::neural_net::NeuralNet`].
---@class NeuralNet
local NeuralNet = {}

--- Returns or performs forward.
---@param input any
---@return table
function NeuralNet:forward(input) end

--- Returns a flat table of all connection weight values in the network.
---@return table
function NeuralNet:getWeights() end

--- Returns or performs layer count.
---@return integer
function NeuralNet:layerCount() end

--- Returns or performs param count.
---@return integer
function NeuralNet:paramCount() end

--- Overwrites all connection weights with values from a flat table.
---@param weights any
---@return boolean
function NeuralNet:setWeights(weights) end

--- Lua wrapper for [`crate::ai::neuroevolution::Neuroevolution`].
---@class Neuroevolution
local Neuroevolution = {}

--- Returns or performs best fitness.
---@return number
function Neuroevolution:bestFitness() end

--- Returns or performs best network.
---@return nil
function Neuroevolution:bestNetwork() end

--- Returns or performs chromosome to net.
---@param idx any
---@return nil
function Neuroevolution:chromosomeToNet(idx) end

--- Runs one generation of the evolutionary algorithm.
---@return nil
function Neuroevolution:evolve() end

--- Returns or performs generation.
---@return integer
function Neuroevolution:generation() end

--- Returns or performs pop size.
---@return integer
function Neuroevolution:popSize() end

--- Sets the fitness score used by the genetic algorithm selection step.
---@param idx any
---@param fitness any
---@return nil
function Neuroevolution:setFitness(idx, fitness) end

--- Lua wrapper for [`crate::ai::orca::ORCASolver`].
---@class ORCASolver
local ORCASolver = {}

--- Returns or performs agent count.
---@return integer
function ORCASolver:agentCount() end

--- Computes and returns the result.
---@param dt any
---@return nil
function ORCASolver:compute(dt) end

--- Returns the safe velocity.
---@param idx any
---@return number
function ORCASolver:getSafeVelocity(idx) end

--- Sets the agent's current world-space position for ORCA velocity computation.
---@param idx any
---@param x any
---@param y any
---@return nil
function ORCASolver:setPosition(idx, x, y) end

--- Lua-side wrapper around a [`QLearner`].
---@class QLearner
local QLearner = {}

--- Returns the greedy-best action for the state (1-based).
---@param state any
---@return integer
function QLearner:bestAction(state) end

--- Selects an action using epsilon-greedy policy (1-based).
---@param state any
---@return integer
function QLearner:chooseAction(state) end

--- Restores the Q-table from a JSON string.
---@param json any
---@return nil
function QLearner:deserialize(json) end

--- Ends the current episode, applying epsilon decay.
---@return nil
function QLearner:endEpisode() end

--- Returns the number of discrete actions.
---@return integer
function QLearner:getActionCount() end

--- Returns the current discount factor.
---@return number
function QLearner:getDiscountFactor() end

--- Returns the number of completed episodes.
---@return integer
function QLearner:getEpisodeCount() end

--- Returns the epsilon decay multiplier.
---@return number
function QLearner:getExplorationDecay() end

--- Returns the current exploration rate.
---@return number
function QLearner:getExplorationRate() end

--- Returns the current learning rate.
---@return number
function QLearner:getLearningRate() end

--- Returns the Q-value for a state-action pair (1-based).
---@param state any
---@param action any
---@return number
function QLearner:getQValue(state, action) end

--- Returns the number of discrete states.
---@return integer
function QLearner:getStateCount() end

--- Serializes the Q-table to a JSON string.
---@return string
function QLearner:serialize() end

--- Sets the discount factor gamma.
---@param v any
---@return nil
function QLearner:setDiscountFactor(v) end

--- Sets the epsilon decay multiplier.
---@param v any
---@return nil
function QLearner:setExplorationDecay(v) end

--- Sets the exploration rate epsilon.
---@param v any
---@return nil
function QLearner:setExplorationRate(v) end

--- Sets the learning rate alpha.
---@param v any
---@return nil
function QLearner:setLearningRate(v) end

--- Returns the type name of this object.
---@return string
function QLearner:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function QLearner:typeOf(name) end

--- Lua-side wrapper around a [`Squad`].
---@class Squad
local Squad = {}

--- Adds an agent by name to this squad.
---@param name any
---@return nil
function Squad:addMember(name) end

--- Returns the squad's shared blackboard.
---@return Blackboard
function Squad:getBlackboard() end

--- Returns the current formation type name.
---@return string
function Squad:getFormation() end

--- Returns the formation spacing in world units.
---@return number
function Squad:getFormationSpacing() end

--- Returns the leader name, or nil.
---@return string?
function Squad:getLeader() end

--- Returns the number of squad members.
---@return integer
function Squad:getMemberCount() end

--- Returns the member names as a table.
---@return table
function Squad:getMembers() end

--- Returns the unique name string assigned to this squad.
---@return string
function Squad:getName() end

--- Removes an agent by name from this squad.
---@param name any
---@return nil
function Squad:removeMember(name) end

--- Sets the squad leader by name.
---@param name any
---@return nil
function Squad:setLeader(name) end

--- Returns the type name of this object.
---@return string
function Squad:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function Squad:typeOf(name) end

--- Lua-side wrapper around a [`StateMachine`].
---@class StateMachine
local StateMachine = {}

--- Registers a named state with optional lifecycle callbacks.
---@param name any
---@param opts any
---@return nil
function StateMachine:addState(name, opts) end

--- Forces a transition to the named state.
---@param name any
---@return nil
function StateMachine:forceState(name) end

--- Returns the current state name, or nil.
---@return string?
function StateMachine:getCurrentState() end

--- Returns seconds spent in the current state.
---@return number
function StateMachine:getTimeInState() end

--- Sets the FSM's initial state; must be called before the first update.
---@param name any
---@return nil
function StateMachine:setInitialState(name) end

--- Returns the type name of this object.
---@return string
function StateMachine:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function StateMachine:typeOf(name) end

--- Lua-side wrapper around a [`SteeringManager`].
---@class SteeringManager
local SteeringManager = {}

--- Enables or disables spatial-hash bucketing for neighbourhood queries.
---@param enabled any
---@return nil
function SteeringManager:enableSpatialHash(enabled) end

--- Returns the number of active behaviors.
---@return integer
function SteeringManager:getBehaviorCount() end

--- Returns the current combination mode.
---@return string
function SteeringManager:getCombineMode() end

--- Returns the last computed steering force.
---@return number
function SteeringManager:getLastSteering() end

--- Sets the force combination mode.
---@param mode any
---@return nil
function SteeringManager:setCombineMode(mode) end

--- Sets the cell size used by the spatial-hash neighbourhood search.
---@param size any
---@return nil
function SteeringManager:setSpatialHashCellSize(size) end

--- Returns the type name of this object.
---@return string
function SteeringManager:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function SteeringManager:typeOf(name) end

--- Lua wrapper for [`crate::ai::perception::StimulusWorld`].
---@class StimulusWorld
local StimulusWorld = {}

--- Resets or clears the state.
---@return nil
function StimulusWorld:clear() end

--- Removes the specified item.
---@param id any
---@return boolean
function StimulusWorld:remove(id) end

--- Advances the simulation by one time step.
---@param dt any
---@return nil
function StimulusWorld:update(dt) end

--- Lua wrapper for [`crate::ai::strategy::StrategyAI`].
---@class StrategyAI
local StrategyAI = {}

--- Returns or performs active goal.
---@return string|nil
function StrategyAI:activeGoal() end

--- Adds a strategic goal with priority score to the planner for future evaluation.
---@param name any
---@return nil
function StrategyAI:addGoal(name) end

--- Adds a string tag to the strategy AI instance for goal filtering and categorization.
---@param tag any
---@return nil
function StrategyAI:addTag(tag) end

--- Returns or performs force evaluate.
---@param scorer_fn any
---@return nil
function StrategyAI:forceEvaluate(scorer_fn) end

--- Removes the specified tag.
---@param tag any
---@return nil
function StrategyAI:removeTag(tag) end

--- Returns or performs time until next.
---@return number
function StrategyAI:timeUntilNext() end

--- Advances the simulation by one time step.
---@param dt any
---@param scorer_fn any
---@return nil
function StrategyAI:update(dt, scorer_fn) end

--- Lua wrapper for [`crate::ai::traits::TraitProfile`].
---@class TraitProfile
local TraitProfile = {}

--- Returns or performs archetype.
---@return string|nil
function TraitProfile:archetype() end

--- Returns the current float value of this emotion dimension.
---@param name any
---@return number
function TraitProfile:get(name) end

--- Returns the unmodified base value of this trait before modifiers.
---@param name any
---@return number
function TraitProfile:getBase(name) end

--- Returns true if a item is present.
---@param name any
---@return boolean
function TraitProfile:has(name) end

--- Removes the specified modifiers.
---@param source any
---@return nil
function TraitProfile:removeModifiers(source) end

--- Sets the base value of this trait, replacing any previous base.
---@param name any
---@param value any
---@return nil
function TraitProfile:set(name, value) end

--- Returns or performs trait count.
---@return number
function TraitProfile:traitCount() end

--- Advances the simulation by one time step.
---@param dt any
---@return nil
function TraitProfile:update(dt) end

--- Lua-side wrapper around a [`UtilityAI`].
---@class UtilityAI
local UtilityAI = {}

--- Evaluates all actions and returns the best action name, or nil.
---@return string?
function UtilityAI:evaluate() end

--- Returns the number of registered actions.
---@return integer
function UtilityAI:getActionCount() end

--- Returns the name of the last chosen action, or nil.
---@return string?
function UtilityAI:getLastAction() end

--- Returns the type name of this object.
---@return string
function UtilityAI:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function UtilityAI:typeOf(name) end

--- Creates a new AI pacing director with default config.
---@return AIDirector
function lurek.ai.newAIDirector() end

--- Creates a new AI LOD controller with default 3-tier config.
---@return AILod
function lurek.ai.newAILod() end

--- Creates a BT action leaf with a Lua callback.
---@param callback any
---@return BTNode
function lurek.ai.newAction(callback) end

--- Creates a new multi-armed bandit.
---@param arm_count any
---@param strategy any
---@param epsilon any
---@param seed any
---@return Bandit
function lurek.ai.newBandit(arm_count, strategy, epsilon, seed) end

--- Creates a new behavior tree.
---@return BehaviorTree
function lurek.ai.newBehaviorTree() end

--- Creates a new standalone blackboard.
---@return Blackboard
function lurek.ai.newBlackboard() end

--- Creates an RTS-style command queue.
---@return CommandQueue
function lurek.ai.newCommandQueue() end

--- Creates a BT condition leaf with a Lua predicate.
---@param callback any
---@return BTNode
function lurek.ai.newCondition(callback) end

--- Creates a new context steering controller.
---@param slots any
---@return ContextSteering
function lurek.ai.newContextSteering(slots) end

--- Creates a new affective emotion model.
---@return EmotionModel
function lurek.ai.newEmotionModel() end

--- Creates a new GOAP planning solver.
---@return GOAPPlanner
function lurek.ai.newGOAPPlanner() end

--- Creates a new genetic algorithm.
---@param pop_size any
---@param gene_count any
---@param seed any
---@return GeneticAlgorithm
function lurek.ai.newGeneticAlgorithm(pop_size, gene_count, seed) end

--- Creates a BT Guard decorator. The predicate is evaluated before each tick;
---@param predicate any
---@param child_ud any
---@return BTNode
function lurek.ai.newGuard(predicate, child_ud) end

--- Creates a new Hierarchical Task Network domain.
---@return HTNDomain
function lurek.ai.newHTNDomain() end

--- Creates a multi-layer influence map grid.
---@param w any
---@param h any
---@param cs any
---@return InfluenceMap
function lurek.ai.newInfluenceMap(w, h, cs) end

--- Creates a BT inverter decorator.
---@return BTNode
function lurek.ai.newInverter() end

--- Creates a new Monte Carlo Tree Search engine.
---@param iters any
---@param uct_c any
---@param depth any
---@param seed any
---@return MCTSEngine
function lurek.ai.newMCTSEngine(iters, uct_c, depth, seed) end

--- Creates a new motivational need system.
---@return NeedSystem
function lurek.ai.newNeedSystem() end

--- Creates a new feedforward neural network (inference only).
---@return NeuralNet
function lurek.ai.newNeuralNet() end

--- Creates a neuroevolution trainer (GA for neural network weights).
---@param layer_spec any
---@param pop_size any
---@param seed any
---@return Neuroevolution
function lurek.ai.newNeuroevolution(layer_spec, pop_size, seed) end

--- Creates a new ORCA crowd avoidance solver.
---@param time_horizon any
---@return ORCASolver
function lurek.ai.newORCASolver(time_horizon) end

--- Creates a BT parallel node with optional policies.
---@param sp? any (optional)
---@param fp? any (optional)
---@return BTNode
function lurek.ai.newParallel(sp, fp) end

--- Creates a tabular Q-learner.
---@param sc any
---@param ac any
---@return QLearner
function lurek.ai.newQLearner(sc, ac) end

--- Creates a BT repeater decorator.
---@param count? any (optional)
---@return BTNode
function lurek.ai.newRepeater(count) end

--- Creates a BT selector node.
---@return BTNode
function lurek.ai.newSelector() end

--- Creates a BT sequence node.
---@return BTNode
function lurek.ai.newSequence() end

--- Creates a named squad for formation positioning.
---@param name any
---@return Squad
function lurek.ai.newSquad(name) end

--- Creates a new finite state machine.
---@return StateMachine
function lurek.ai.newStateMachine() end

--- Creates a new steering behavior manager.
---@return SteeringManager
function lurek.ai.newSteeringManager() end

--- Creates a new stimulus perception world.
---@return StimulusWorld
function lurek.ai.newStimulusWorld() end

--- Creates a new throttled strategy AI.
---@param update_interval any
---@return StrategyAI
function lurek.ai.newStrategyAI(update_interval) end

--- Creates a BT succeeder decorator.
---@return BTNode
function lurek.ai.newSucceeder() end

--- Creates a new personality trait profile.
---@return TraitProfile
function lurek.ai.newTraitProfile() end

--- Creates a new utility AI evaluator.
---@return UtilityAI
function lurek.ai.newUtilityAI() end

--- Creates a new AI world container.
---@return AIWorld
function lurek.ai.newWorld() end

---@class lurek.animation
lurek.animation = {}

--- Lua-side wrapper around an [`AnimCurve`].
---@class AnimCurve
local AnimCurve = {}

--- Inserts a keyframe at the given time. If a keyframe at the same time already
---@param t any
---@param v any
---@return nil
function AnimCurve:addKeyframe(t, v) end

--- Removes all keyframes from this animation curve, resetting it to empty.
---@return nil
function AnimCurve:clear() end

--- Returns the interpolated value at the given time using the curve's easing.
---@param t any
---@return number
function AnimCurve:eval(t) end

--- Returns the number of keyframes currently stored.
---@return integer
function AnimCurve:keyframeCount() end

--- Set a custom Lua easing function for this curve.
---@param func any
---@return nil
function AnimCurve:setCustomEasing(func) end

--- Sets the easing kind applied between all keyframe segments.
---@param mode any
---@return nil
function AnimCurve:setEasing(mode) end

--- Lua-side wrapper around an [`AnimStateMachine`] FSM controller.
---@class AnimStateMachine
local AnimStateMachine = {}

--- Immediately jumps to the named state, bypassing transition conditions.
---@param name any
---@return boolean
function AnimStateMachine:forceState(name) end

--- Returns the source quad for the current animation frame, or nil.
---@return table?
function AnimStateMachine:getQuad() end

--- Returns the name of the currently active state.
---@return string
function AnimStateMachine:getState() end

--- Sets an FSM parameter value (number, boolean, or integer supported).
---@param name any
---@param value any
---@return nil
function AnimStateMachine:setParam(name, value) end

--- Advances the FSM by `dt` seconds, evaluating transitions.
---@param dt any
---@return nil
function AnimStateMachine:update(dt) end

--- Lua-side wrapper around an [`AnimSyncGroup`].
---@class AnimSyncGroup
local AnimSyncGroup = {}

--- Adds an animation handle to the group.
---@param handle any
---@return nil
function AnimSyncGroup:add(handle) end

--- Removes all animation handles from the group.
---@return nil
function AnimSyncGroup:clear() end

--- Returns the number of animations currently in the group.
---@return integer
function AnimSyncGroup:memberCount() end

--- Removes an animation handle from the group.
---@param handle any
---@return nil
function AnimSyncGroup:remove(handle) end

--- Lua-side wrapper around an [`Animation`] controller.
---@class Animation
local Animation = {}

--- Adds a single frame to the frame pool by source rectangle.
---@param x any
---@param y any
---@param w any
---@param h any
---@return integer
function Animation:addFrame(x, y, w, h) end

--- Renders the current animation frame into a new ImageData (white bg, blue frame rect).
---@param w any
---@param h any
---@return ImageData
function Animation:drawToImage(w, h) end

--- Returns the two quads and blend factor during a crossfade, or nil when not blending.
---@return table?
function Animation:getBlendState() end

--- Returns the name of the currently playing clip, or nil.
---@return string?
function Animation:getClip() end

--- Returns the number of registered clips.
---@return integer
function Animation:getClipCount() end

--- Returns the current position within the active clip (0-based).
---@return integer
function Animation:getCurrentFrame() end

--- Returns the total number of frames in the frame pool.
---@return integer
function Animation:getFrameCount() end

--- Returns the source quad (x, y, w, h) for the current frame, or nil.
---@return table?
function Animation:getQuad() end

--- Returns the playback speed multiplier.
---@return number
function Animation:getSpeed() end

--- Returns true if the current clip is set to loop.
---@return boolean
function Animation:isLooping() end

--- Returns true if a clip is currently playing.
---@return boolean
function Animation:isPlaying() end

--- Pauses playback at the current frame.
---@return nil
function Animation:pause() end

--- Starts playback of the named clip.
---@param name any
---@return boolean
function Animation:play(name) end

--- Drains and returns all pending animation events as a table.
---@return table
function Animation:pollEvents() end

--- Resumes playback from the current frame.
---@return nil
function Animation:resume() end

--- Sets the playback position within the current clip.
---@param index any
---@return nil
function Animation:setFrame(index) end

--- Sets the playback speed multiplier.
---@param speed any
---@return nil
function Animation:setSpeed(speed) end

--- Stops playback and resets to frame 0.
---@return nil
function Animation:stop() end

--- Advances the animation by dt seconds.
---@param dt any
---@return nil
function Animation:update(dt) end

--- Lua-side wrapper around a [`BlendLayerSet`] blend layer compositor.
---@class BlendLayerSet
local BlendLayerSet = {}

--- Returns the blend weight of a named layer, or nil if not found.
---@param name any
---@return number?
function BlendLayerSet:getWeight(name) end

--- Returns the number of blend layers.
---@return integer
function BlendLayerSet:len() end

--- Returns an ordered array of layer info tables: {name, clip_name, weight, bones}.
---@return table
function BlendLayerSet:listLayers() end

--- Removes a blend layer by name.
---@param name any
---@return boolean
function BlendLayerSet:removeLayer(name) end

--- Replaces the bone mask of a layer.
---@param name any
---@param bones any
---@return boolean
function BlendLayerSet:setMask(name, bones) end

--- Sets the blend weight of a named layer (clamped to [0, 1]).
---@param name any
---@param weight any
---@return boolean
function BlendLayerSet:setWeight(name, weight) end

--- Parses an Aseprite JSON export string and builds an Animation with clips and frames.
---@param json_str any
---@return table|nil
function lurek.animation.fromAseprite(json_str) end

--- Creates a new, empty Animation controller.
---@return Animation
function lurek.animation.new() end

--- Creates a new empty [`BlendLayerSet`] for compositing multiple animation clips.
---@return BlendLayerSet
function lurek.animation.newBlendLayerSet() end

--- Creates a new empty [`AnimCurve`] with linear interpolation.
---@return AnimCurve
function lurek.animation.newCurve() end

--- Creates an animation FSM from an Animation controller and an initial state name.
---@param anim_ud any
---@param initial any
---@return AnimStateMachine
function lurek.animation.newStateMachine(anim_ud, initial) end

--- Creates a new empty [`AnimSyncGroup`].
---@return AnimSyncGroup
function lurek.animation.newSyncGroup() end

---@class lurek.audio
lurek.audio = {}

--- Lua-side wrapper for an audio bus resource.
---@class Bus
local Bus = {}

--- Removes the ducking target from this bus, restoring the target bus
---@return nil
function Bus:clearDuck() end

--- Returns the unique name string assigned to this audio bus.
---@return string
function Bus:getName() end

--- Returns the average peak amplitude of all sources currently on this bus.
---@return nil
function Bus:getPeak() end

--- Returns the bus pitch multiplier.
---@return number
function Bus:getPitch() end

--- Returns the current volume multiplier applied to all sources on this bus.
---@return number
function Bus:getVolume() end

--- Returns true if this bus is paused.
---@return boolean
function Bus:isPaused() end

--- Pauses all sources on this bus.
---@return nil
function Bus:pause() end

--- Resumes all sources on this bus.
---@return nil
function Bus:resume() end

--- Sets the pitch multiplier for all sources on this bus.
---@param pitch any
---@return nil
function Bus:setPitch(pitch) end

--- Sets the volume for all sources on this bus.
---@param vol any
---@return nil
function Bus:setVolume(vol) end

--- Returns the type name of this object.
---@return string
function Bus:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function Bus:typeOf(name) end

--- Lua-side wrapper for a streaming audio decoder.
---@class Decoder
local Decoder = {}

--- Decodes the next chunk of samples, or nil at EOF.
---@return SoundData
function Decoder:decode() end

--- Returns the per-sample bit depth of this decoded audio stream.
---@return integer
function Decoder:getBitDepth() end

--- Returns the number of audio channels.
---@return integer
function Decoder:getChannelCount() end

--- Returns the total duration in seconds.
---@return number
function Decoder:getDuration() end

--- Returns the sample rate in Hz.
---@return integer
function Decoder:getSampleRate() end

--- Returns true if seeking is supported.
---@return boolean
function Decoder:isSeekable() end

--- Releases the decoder (no-op).
---@return nil
function Decoder:release() end

--- Rewinds to the beginning.
---@return nil
function Decoder:rewind() end

--- Seeks to a time offset in seconds.
---@param offset any
---@return nil
function Decoder:seek(offset) end

--- Returns the current position in seconds.
---@return number
function Decoder:tell() end

--- Lua-side wrapper for the MIDI player.
---@class MidiPlayer
local MidiPlayer = {}

--- Returns the assigned bus, or nil.
---@return Bus
function MidiPlayer:getBus() end

--- Returns the number of MIDI channels.
---@return integer
function MidiPlayer:getChannelCount() end

--- Returns the GM instrument for a MIDI channel (1-indexed).
---@param ch any
---@return integer
function MidiPlayer:getChannelInstrument(ch) end

--- Returns the volume for a MIDI channel (1-indexed).
---@param ch any
---@return number
function MidiPlayer:getChannelVolume(ch) end

--- Returns the PCM output channel count (1 = mono, 2 = stereo).
---@return integer
function MidiPlayer:getChannels() end

--- Returns the total MIDI duration in seconds.
---@return number
function MidiPlayer:getDuration() end

--- Returns the file path of the loaded MIDI, or nil.
---@return string
function MidiPlayer:getFilePath() end

--- Returns the total note count in the MIDI sequence.
---@return integer
function MidiPlayer:getNoteCount() end

--- Returns the original MIDI file tempo in BPM.
---@return number
function MidiPlayer:getOriginalTempo() end

--- Returns the PCM output sample rate in Hz.
---@return integer
function MidiPlayer:getSampleRate() end

--- Returns the SoundFont file path, or nil (stub).
---@return string
function MidiPlayer:getSoundFontPath() end

--- Returns the current tempo in BPM.
---@return number
function MidiPlayer:getTempo() end

--- Returns the current tempo scale factor.
---@return number
function MidiPlayer:getTempoScale() end

--- Returns the PPQ resolution from the MIDI header.
---@return integer
function MidiPlayer:getTicksPerBeat() end

--- Returns the number of tracks in the MIDI sequence.
---@return integer
function MidiPlayer:getTrackCount() end

--- Returns the name of a MIDI track (1-indexed), or nil.
---@param idx any
---@return string
function MidiPlayer:getTrackName(idx) end

--- Returns the current MIDI volume.
---@return number
function MidiPlayer:getVolume() end

--- Returns true if a MIDI channel is muted (1-indexed).
---@param ch any
---@return boolean
function MidiPlayer:isChannelMuted(ch) end

--- Returns true if a MIDI sequence is loaded.
---@return boolean
function MidiPlayer:isLoaded() end

--- Returns true if looping is enabled.
---@return boolean
function MidiPlayer:isLooping() end

--- Returns true if MIDI playback is paused.
---@return boolean
function MidiPlayer:isPaused() end

--- Returns true if MIDI is currently playing.
---@return boolean
function MidiPlayer:isPlaying() end

--- Returns true if a track is muted (1-indexed).
---@param idx any
---@return boolean
function MidiPlayer:isTrackMuted(idx) end

--- Loads a MIDI file from the given path.
---@param path any
---@return boolean
function MidiPlayer:load(path) end

--- Loads MIDI data from a Lua string.
---@param data string
---@return boolean
function MidiPlayer:loadData(data) end

--- Pauses the MIDI sequence at the current position; resume with `play()`.
---@return nil
function MidiPlayer:pause() end

--- Starts or resumes MIDI sequence playback from the current position.
---@return nil
function MidiPlayer:play() end

--- Seeks to a time position in seconds.
---@param secs any
---@return nil
function MidiPlayer:seek(secs) end

--- Routes MIDI output through a bus (or nil to clear).
---@param bus_val any
---@return nil
function MidiPlayer:setBus(bus_val) end

--- Mutes or unmutes a MIDI channel (1-indexed).
---@param ch any
---@param muted any
---@return nil
function MidiPlayer:setChannelMuted(ch, muted) end

--- Sets volume for a MIDI channel (1-indexed).
---@param ch any
---@param vol any
---@return nil
function MidiPlayer:setChannelVolume(ch, vol) end

--- Sets the PCM output channel count (clamped 1â€“2).
---@param channels any
---@return nil
function MidiPlayer:setChannels(channels) end

--- Enables or disables looping.
---@param looping any
---@return nil
function MidiPlayer:setLooping(looping) end

--- Registers a playback-end callback (stub).
---@param cb any
---@return nil
function MidiPlayer:setOnEnd(cb) end

--- Registers a note-off callback (stub).
---@param cb any
---@return nil
function MidiPlayer:setOnNoteOff(cb) end

--- Registers a note-on callback (stub).
---@param cb any
---@return nil
function MidiPlayer:setOnNoteOn(cb) end

--- Sets the PCM output sample rate in Hz (clamped 8000â€“192000).
---@param rate any
---@return nil
function MidiPlayer:setSampleRate(rate) end

--- Loads a SoundFont file into this player (stub).
---@param path any
---@return nil
function MidiPlayer:setSoundFont(path) end

--- Sets playback tempo in BPM.
---@param bpm any
---@return nil
function MidiPlayer:setTempo(bpm) end

--- Sets the tempo scale factor (1.0 = original speed).
---@param scale any
---@return nil
function MidiPlayer:setTempoScale(scale) end

--- Mutes or unmutes a track (1-indexed).
---@param idx any
---@param muted any
---@return nil
function MidiPlayer:setTrackMuted(idx, muted) end

--- Sets MIDI playback volume.
---@param vol any
---@return nil
function MidiPlayer:setVolume(vol) end

--- Solos a MIDI channel (1-indexed).
---@param ch any
---@return nil
function MidiPlayer:soloChannel(ch) end

--- Stops MIDI playback and resets the playhead to the beginning.
---@return nil
function MidiPlayer:stop() end

--- Returns the current playback position in seconds.
---@return number
function MidiPlayer:tell() end

--- Returns the type name of this object.
---@return string
function MidiPlayer:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function MidiPlayer:typeOf(name) end

--- Clears solo on all channels.
---@return nil
function MidiPlayer:unsoloAll() end

--- Reverts to the built-in default SoundFont (stub).
---@return nil
function MidiPlayer:useDefaultSoundFont() end

--- Lua-side wrapper for a polyphonic [`crate::audio::SoundPool`].
---@class SoundPool
local SoundPool = {}

--- Returns the total number of voices in this pool.
---@return integer
function SoundPool:getVoiceCount() end

--- Plays the next available voice and returns its SoundKey as an integer.
---@return integer
function SoundPool:play() end

--- Releases all voices from the mixer and invalidates this pool.
---@return nil
function SoundPool:release() end

--- Routes all voices through the named bus.
---@param name any
---@return nil
function SoundPool:setBus(name) end

--- Sets the volume for all voices in this pool.
---@param vol any
---@return nil
function SoundPool:setVolume(vol) end

--- Stops all voices in this pool.
---@return nil
function SoundPool:stopAll() end

--- Returns the type name of this object.
---@return string
function SoundPool:type() end

--- Returns true if the type name matches.
---@param name any
---@return boolean
function SoundPool:typeOf(name) end

--- Lua-side wrapper for an audio source resource.
---@class Source
local Source = {}

--- Removes any active filter from this source.
---@return nil
function Source:clearFilter() end

--- Creates an independent copy of this source.
---@return Source
function Source:clone() end

--- Fades in from silence over the given duration in seconds.
---@param dur any
---@return nil
function Source:fadeIn(dur) end

--- Returns the total duration in seconds.
---@return number
function Source:getDuration() end

--- Returns the current fade-in duration in seconds.
---@return number
function Source:getFadeIn() end

--- Returns the high-pass filter cutoff frequency.
---@return number
function Source:getHighpass() end

--- Returns the low-pass filter cutoff frequency.
---@return number
function Source:getLowpass() end

--- Returns the current stereo panning value.
---@return number
function Source:getPan() end

--- Returns the current pitch multiplier.
---@return number
function Source:getPitch() end

--- Returns the source type ("static" or "stream").
---@return string
function Source:getType() end

--- Returns the current volume multiplier.
---@return number
function Source:getVolume() end

--- Returns true if looping is enabled.
---@return boolean
function Source:isLooping() end

--- Returns true if playback is paused.
---@return boolean
function Source:isPaused() end

--- Returns true if currently playing.
---@return boolean
function Source:isPlaying() end

--- Returns true if playback has stopped.
---@return boolean
function Source:isStopped() end

--- Pauses playback at the current position.
---@return nil
function Source:pause() end

--- Starts or resumes playback.
---@return nil
function Source:play() end

--- Resumes playback from the paused position.
---@return nil
function Source:resume() end

--- Seeks to a time position in seconds.
---@param pos any
---@return nil
function Source:seek(pos) end

--- Applies a high-pass filter at the given cutoff frequency.
---@param cutoff_hz any
---@return nil
function Source:setHighpass(cutoff_hz) end

--- Enables or disables looping playback.
---@param looping any
---@return nil
function Source:setLooping(looping) end

--- Applies a low-pass filter at the given cutoff frequency.
---@param cutoff_hz any
---@return nil
function Source:setLowpass(cutoff_hz) end

--- Sets stereo panning (-1.0 left to 1.0 right).
---@param pan any
---@return nil
function Source:setPan(pan) end

--- Sets the pitch multiplier (1.0 = normal).
---@param pitch any
---@return nil
function Source:setPitch(pitch) end

--- Sets playback volume (0.0 = silent, 1.0 = full).
---@param vol any
---@return nil
function Source:setVolume(vol) end

--- Stops playback and resets seek position.
---@return nil
function Source:stop() end

--- Returns the current playback position in seconds.
---@return number
function Source:tell() end

---@class mlua
local mlua = {}

--- Get the bit depth.
---@return integer
function mlua:getBitDepth() end

--- Get the number of channels.
---@return integer
function mlua:getChannelCount() end

--- Get the audio duration in seconds.
---@return number
function mlua:getDuration() end

--- Get a specific sample by index.
---@param index any
---@return number
function mlua:getSample(index) end

--- Get the total number of samples.
---@return integer
function mlua:getSampleCount() end

--- Get the sample rate.
---@return integer
function mlua:getSampleRate() end

--- Set a specific sample by index.
---@param index any
---@param value any
---@return nil
function mlua:setSample(index, value) end

--- Adds a DSP effect to a bus.
---@param bus_name any
---@param effect_type_str any
---@param params? any (optional)
---@return integer
function lurek.audio.add_effect(bus_name, effect_type_str, params) end

--- Applies a bandpass filter (high-pass then low-pass) to a SoundData in-place.
---@param sd_ud any
---@param low_hz any
---@param high_hz any
---@return nil
function lurek.audio.applyBandpass(sd_ud, low_hz, high_hz) end

--- Scales every sample by gain (clamped to [-1, 1]).
---@param sd_ud any
---@param gain any
---@return nil
function lurek.audio.applyGain(sd_ud, gain) end

--- Applies a first-order IIR high-pass filter to a SoundData in-place.
---@param sd_ud any
---@param cutoff_hz any
---@return nil
function lurek.audio.applyHighpass(sd_ud, cutoff_hz) end

--- Applies a first-order IIR low-pass filter to a SoundData in-place.
---@param sd_ud any
---@param cutoff_hz any
---@return nil
function lurek.audio.applyLowpass(sd_ud, cutoff_hz) end

--- Removes any active filter from a source.
---@param id_val any
---@return nil
function lurek.audio.clearFilter(id_val) end

--- Unloads the active SoundFont.
---@return nil
function lurek.audio.clearMidiSoundFont() end

--- Clears any random pitch range on a source, restoring fixed pitch.
---@param src_ud any
---@return nil
function lurek.audio.clearRandomPitch(src_ud) end

--- Creates an independent copy of a source.
---@param id_val any
---@return Source
function lurek.audio.clone(id_val) end

--- Creates a bus by name (functional style).
---@param name any
---@param parent_name? any (optional)
---@return nil
function lurek.audio.create_bus(name, parent_name) end

--- Crossfades from one source to another over a duration.
---@param from_ud any
---@param to_ud any
---@param duration any
---@return nil
function lurek.audio.crossfade(from_ud, to_ud, duration) end

--- Fades a source in from silence over the given duration.
---@param id_val any
---@param dur any
---@return nil
function lurek.audio.fadeIn(id_val, dur) end

--- Returns the number of currently playing sources.
---@return integer
function lurek.audio.getActiveSourceCount() end

--- Returns the peak signal level of the named bus (stub: always 0.0).
---@param bus_name any
---@return number
function lurek.audio.getBusPeak(bus_name) end

--- Returns the RMS signal level of the named bus (stub: always 0.0).
---@param bus_name any
---@return number
function lurek.audio.getBusRms(bus_name) end

--- Returns the current distance model name.
---@return string
function lurek.audio.getDistanceModel() end

--- Returns the current Doppler scale.
---@return number
function lurek.audio.getDopplerScale() end

--- Returns the total duration of a source in seconds.
---@param id_val any
---@return number
function lurek.audio.getDuration(id_val) end

--- Returns the fade-in duration of a source.
---@param id_val any
---@return number
function lurek.audio.getFadeIn(id_val) end

--- Returns the free buffer slots in a queueable source.
---@param qsource_id any
---@return integer
function lurek.audio.getFreeBufferCount(qsource_id) end

--- Returns the high-pass filter cutoff of a source.
---@param id_val any
---@return number
function lurek.audio.getHighpass(id_val) end

--- Returns the 3D listener position (x, y, z).
---@return number
function lurek.audio.getListener() end

--- Returns the 2D listener position (x, y).
---@return number
function lurek.audio.getListener2D() end

--- Returns the low-pass filter cutoff of a source.
---@param id_val any
---@return number
function lurek.audio.getLowpass(id_val) end

--- Returns the global master volume.
---@return number
function lurek.audio.getMasterVolume() end

--- Returns the maximum number of simultaneous sources.
---@return integer
function lurek.audio.getMaxSources() end

--- Returns the stored master peak meter level.
---@return table|nil
function lurek.audio.getMeter() end

--- Returns the 6-component orientation of a source.
---@param id_val any
---@return table|nil
function lurek.audio.getOrientation(id_val) end

--- Returns the source stereo panning.
---@param id_val any
---@return number
function lurek.audio.getPan(id_val) end

--- Returns the source pitch multiplier.
---@param id_val any
---@return number
function lurek.audio.getPitch(id_val) end

--- Returns the current audio output device name.
---@return string
function lurek.audio.getPlaybackDevice() end

--- Returns a table of available audio output device names.
---@return table
function lurek.audio.getPlaybackDevices() end

--- Returns the 3D position of a source (x, y, z).
---@param id_val any
---@return number
function lurek.audio.getPosition(id_val) end

--- Returns the bus a source is assigned to, or nil.
---@param id_val any
---@return Bus
function lurek.audio.getSourceBus(id_val) end

--- Returns the total number of registered sources.
---@return integer
function lurek.audio.getSourceCount() end

--- Returns the type string ("static" or "stream") of a source.
---@param id_val any
---@return string
function lurek.audio.getSourceType(id_val) end

--- Returns the current stereo width for a source.
---@param src_ud any
---@return number
function lurek.audio.getStereoWidth(src_ud) end

--- Returns the velocity of a source (x, y, z).
---@param id_val any
---@return number
function lurek.audio.getVelocity(id_val) end

--- Returns the source volume.
---@param id_val any
---@return number
function lurek.audio.getVolume(id_val) end

--- Returns true if a SoundFont is loaded.
---@return boolean
function lurek.audio.hasMidiSoundFont() end

--- Returns true if looping is enabled.
---@param id_val any
---@return boolean
function lurek.audio.isLooping(id_val) end

--- Returns true if the source is paused.
---@param id_val any
---@return boolean
function lurek.audio.isPaused(id_val) end

--- Returns true if the source is playing.
---@param id_val any
---@return boolean
function lurek.audio.isPlaying(id_val) end

--- Returns true if the source is stopped.
---@param id_val any
---@return boolean
function lurek.audio.isStopped(id_val) end

--- Additively mixes another SoundData into the destination in-place.
---@param dest_ud any
---@param src_ud any
---@return nil
function lurek.audio.mixInto(dest_ud, src_ud) end

--- Creates a named audio bus for grouping sources.
---@param name any
---@return Bus
function lurek.audio.newBus(name) end

--- Creates a streaming audio decoder.
---@param source any
---@param buffersize? any (optional)
---@return Decoder
function lurek.audio.newDecoder(source, buffersize) end

--- Creates a MIDI player, optionally loading a file.
---@param path? any (optional)
---@return MidiPlayer
function lurek.audio.newMidiPlayer(path) end

--- Creates a polyphonic sound pool for the given file with N simultaneous voices.
---@param file_path any
---@param voice_count any
---@return SoundPool
function lurek.audio.newPool(file_path, voice_count) end

--- Creates a queueable source for manual PCM buffering.
---@param sample_rate integer
---@param bit_depth integer
---@param channels integer
---@param buffer_count integer
---@return integer
function lurek.audio.newQueueableSource(sample_rate, bit_depth, channels, buffer_count) end

--- Generate a mono sawtooth-wave SoundData buffer.
---@param freq any
---@param duration any
---@param sample_rate any
---@param amplitude any
---@return SoundData
function lurek.audio.newSawtoothWave(freq, duration, sample_rate, amplitude) end

--- Generate a mono sine-wave SoundData buffer.
---@param freq any
---@param duration any
---@param sample_rate any
---@param amplitude any
---@return SoundData
function lurek.audio.newSineWave(freq, duration, sample_rate, amplitude) end

--- Creates a SoundData from a file or as a silent buffer.
---@param args any
---@return SoundData
function lurek.audio.newSoundData(args) end

--- Loads an audio file and returns a Source handle.
---@param args any
---@return Source
function lurek.audio.newSource(args) end

--- Generate a mono square-wave SoundData buffer.
---@param freq any
---@param duration any
---@param sample_rate any
---@param amplitude any
---@return SoundData
function lurek.audio.newSquareWave(freq, duration, sample_rate, amplitude) end

--- Generate a mono triangle-wave SoundData buffer.
---@param freq any
---@param duration any
---@param sample_rate any
---@param amplitude any
---@return SoundData
function lurek.audio.newTriangleWave(freq, duration, sample_rate, amplitude) end

--- Generate a reproducible white-noise SoundData buffer.
---@param duration any
---@param sample_rate any
---@param amplitude any
---@param seed any
---@return SoundData
function lurek.audio.newWhiteNoise(duration, sample_rate, amplitude, seed) end

--- Normalizes a WAV file peak amplitude to target_level and writes output.
---@param input any
---@param output any
---@param target any
---@return nil
function lurek.audio.normalizeFile(input, output, target) end

--- Pauses playback at the current position.
---@param id_val any
---@return nil
function lurek.audio.pause(id_val) end

--- Pauses all currently playing sources.
---@return nil
function lurek.audio.pauseAll() end

--- Plays a source, with optional bus routing via options table.
---@param id_val any
---@param options? any (optional)
---@return integer
function lurek.audio.play(id_val, options) end

--- Plays the source in a continuous loop.
---@param id_val any
---@return nil
function lurek.audio.playLooping(id_val) end

--- Starts playback of a queueable source.
---@param qsource_id any
---@return nil
function lurek.audio.playQueueable(qsource_id) end

--- Applies a DSP effect chain to a WAV file and writes output.
---@param input any
---@param output any
---@param effects_tbl any
---@return nil
function lurek.audio.processOffline(input, output, effects_tbl) end

--- Pushes a SoundData buffer into a queueable source.
---@param qsource_id any
---@param sd any
---@return nil
function lurek.audio.queueSource(qsource_id, sd) end

--- Releases a source and frees its memory.
---@param id_val any
---@return boolean
function lurek.audio.release(id_val) end

--- Removes a DSP effect from a bus.
---@param bus_name any
---@param effect_id any
---@return boolean
function lurek.audio.remove_effect(bus_name, effect_id) end

--- Resumes playback from pause.
---@param id_val any
---@return nil
function lurek.audio.resume(id_val) end

--- Resumes all paused sources.
---@return nil
function lurek.audio.resumeAll() end

--- Saves a SoundData as a 16-bit PCM WAV file at the given path.
---@param sd_ud any
---@param filename any
---@return nil
function lurek.audio.saveWAV(sd_ud, filename) end

--- Seeks to a time position in seconds.
---@param id_val any
---@param pos any
---@return nil
function lurek.audio.seek(id_val, pos) end

--- Sets the distance attenuation model.
---@param model any
---@return nil
function lurek.audio.setDistanceModel(model) end

--- Sets the global Doppler effect scale.
---@param scale any
---@return nil
function lurek.audio.setDopplerScale(scale) end

--- Applies a high-pass filter to a source.
---@param id_val any
---@param cutoff_hz any
---@return nil
function lurek.audio.setHighpass(id_val, cutoff_hz) end

--- Sets the 3D listener position.
---@param x any
---@param y any
---@param z? any (optional)
---@return nil
function lurek.audio.setListener(x, y, z) end

--- Sets the 2D listener position for spatial audio.
---@param x any
---@param y any
---@return nil
function lurek.audio.setListener2D(x, y) end

--- Enables or disables looping.
---@param id_val any
---@param looping any
---@return nil
function lurek.audio.setLooping(id_val, looping) end

--- Applies a low-pass filter to a source.
---@param id_val any
---@param cutoff_hz any
---@return nil
function lurek.audio.setLowpass(id_val, cutoff_hz) end

--- Sets the global master volume.
---@param vol any
---@return nil
function lurek.audio.setMasterVolume(vol) end

--- Sets the master peak meter level (0.0â€“1.0).
---@param level any
---@return nil
function lurek.audio.setMeter(level) end

--- Sets the global SoundFont for MIDI synthesis.
---@param path any
---@return nil
function lurek.audio.setMidiSoundFont(path) end

--- Sets the 6-component orientation of a source.
---@param id_val any
---@param fx any
---@param fy any
---@param fz any
---@param ux any
---@param uy any
---@param uz any
---@return nil
function lurek.audio.setOrientation(id_val, fx, fy, fz, ux, uy, uz) end

--- Sets stereo panning (-1.0 left to 1.0 right).
---@param id_val any
---@param pan any
---@return nil
function lurek.audio.setPan(id_val, pan) end

--- Sets source pitch multiplier.
---@param id_val any
---@param pitch any
---@return nil
function lurek.audio.setPitch(id_val, pitch) end

--- Selects an audio output device by name.
---@param name any
---@return nil
function lurek.audio.setPlaybackDevice(name) end

--- Sets the 3D position of a source.
---@param id_val any
---@param x any
---@param y any
---@param z? any (optional)
---@return nil
function lurek.audio.setPosition(id_val, x, y, z) end

--- Sets a random pitch range applied each time the source is played.
---@param src_ud any
---@param min any
---@param max any
---@return nil
function lurek.audio.setRandomPitch(src_ud, min, max) end

--- Assigns a source to a bus.
---@param id_val any
---@param bus_val any
---@return nil
function lurek.audio.setSourceBus(id_val, bus_val) end

--- Sets the stereo width multiplier for a source (1.0 = normal, 0.0 = mono).
---@param src_ud any
---@param width any
---@return nil
function lurek.audio.setStereoWidth(src_ud, width) end

--- Sets the velocity of a source for Doppler.
---@param id_val any
---@param x any
---@param y any
---@param z? any (optional)
---@return nil
function lurek.audio.setVelocity(id_val, x, y, z) end

--- Sets source playback volume.
---@param id_val any
---@param vol any
---@return nil
function lurek.audio.setVolume(id_val, vol) end

--- Sets a bus volume by name.
---@param name any
---@param volume any
---@return nil
function lurek.audio.set_bus_volume(name, volume) end

--- Sets a parameter on a DSP effect.
---@param bus_name any
---@param effect_id any
---@param param_name any
---@param value any
---@return boolean
function lurek.audio.set_effect_param(bus_name, effect_id, param_name, value) end

--- Renders a time-frequency spectrogram of a WAV file to a PNG image.
---@param input any
---@param output any
---@param width any
---@param height any
---@return nil
function lurek.audio.spectrogramToPng(input, output, width, height) end

--- Stops playback and resets seek position.
---@param id_val any
---@return nil
function lurek.audio.stop(id_val) end

--- Stops all currently playing sources.
---@return nil
function lurek.audio.stopAll() end

--- Stops a queueable source and drains its buffers.
---@param qsource_id any
---@return nil
function lurek.audio.stopQueueable(qsource_id) end

--- Returns the current playback position in seconds.
---@param id_val any
---@return number
function lurek.audio.tell(id_val) end

--- Renders the waveform of a WAV file to a PNG image.
---@param input any
---@param output any
---@param width any
---@param height any
---@return nil
function lurek.audio.waveformToPng(input, output, width, height) end

---@class lurek.simulator
lurek.simulator = {}

--- Returns the name of the active script, or nil if idle.
---@return string?
function lurek.simulator.getCurrentScript() end

--- Returns the index of the next step to be dispatched.
---@return integer
function lurek.simulator.getCurrentStep() end

--- Returns seconds elapsed since playback started.
---@return number
function lurek.simulator.getElapsedTime() end

--- Returns the current playback speed multiplier (default 1.0).
---@return number
function lurek.simulator.getPlaybackSpeed() end

--- Returns an array of all registered script names.
---@return table
function lurek.simulator.getScripts() end

--- Returns the total number of steps in the active script.
---@return integer
function lurek.simulator.getStepCount() end

--- Returns the step limit for the named script, or nil if not found.
---@param name any
---@return integer?
function lurek.simulator.getStepLimit(name) end

--- Returns true if a macro with the given name has been saved.
---@param name any
---@return boolean
function lurek.simulator.hasMacro(name) end

--- Returns true if a script with the given name is registered.
---@param name any
---@return boolean
function lurek.simulator.hasScript(name) end

--- Returns true if all steps in the active script have been dispatched.
---@return boolean
function lurek.simulator.isComplete() end

--- Returns whether the highlight overlay hint is active.
---@return boolean
function lurek.simulator.isHighlightMode() end

--- Returns true if playback is currently paused.
---@return boolean
function lurek.simulator.isPaused() end

--- Returns true if the simulator is actively playing a script.
---@return boolean
function lurek.simulator.isRunning() end

--- Returns an array of all saved macro names.
---@return table
function lurek.simulator.listMacros() end

--- Loads a named script from a Lua data table containing a steps array.
---@param name any
---@param data any
---@return nil
function lurek.simulator.load(name, data) end

--- Parses a TOML string and registers it as a named script.
---@param name any
---@param toml_str any
---@return nil
function lurek.simulator.loadFromToml(name, toml_str) end

--- Pauses playback at the current step position.
---@return nil
function lurek.simulator.pause() end

--- Loads and starts playback of a previously saved macro.
---@param name any
---@return nil
function lurek.simulator.playMacro(name) end

--- Resumes playback from a paused position.
---@return nil
function lurek.simulator.resume() end

--- Saves a currently-loaded script under a macro name for fast replay.
---@param macro_name any
---@param script_name any
---@return nil
function lurek.simulator.saveMacro(macro_name, script_name) end

--- Enables or disables the highlight overlay hint.
---@param enable any
---@return nil
function lurek.simulator.setHighlightMode(enable) end

--- Sets the dt multiplier for script playback (0.5 = half speed, 2.0 = double).
---@param factor any
---@return nil
function lurek.simulator.setPlaybackSpeed(factor) end

--- Sets the step limit for the named script (clamped to 1..MAX_STEPS).
---@param name any
---@param n any
---@return boolean
function lurek.simulator.setStepLimit(name, n) end

--- Starts playback of the named script from the beginning.
---@param name any
---@return nil
function lurek.simulator.start(name) end

--- Stops playback and resets the simulator to idle.
---@return nil
function lurek.simulator.stop() end

--- Removes a loaded script by name, returning true if it existed.
---@param name any
---@return boolean
function lurek.simulator.unload(name) end

--- Advances the playback clock by `dt` seconds, dispatching due steps.
---@param dt any
---@return nil
function lurek.simulator.update(dt) end

--- Pauses playback advancement until predicate() returns true or timeout seconds elapse.
---@param predicate any
---@param timeout any
---@return nil
function lurek.simulator.waitUntil(predicate, timeout) end

---@class lurek.camera
lurek.camera = {}

--- Lua-side wrapper around a [`Camera2D`] instance.
---@class Camera2D
local Camera2D = {}

--- Removes all parallax factor overrides.
---@return nil
function Camera2D:clearParallaxFactors() end

--- Clears the follow target so the camera stops tracking.
---@return nil
function Camera2D:clearTarget() end

--- Returns the current sway x, y world-space offset.
---@return number
function Camera2D:getEffectOffset() end

--- Returns the current zoom level including zoom pulse and breathing deltas.
---@return number
function Camera2D:getEffectiveZoom() end

--- Returns the parallax factor for the named layer, or `1.0` if unset.
---@param layer any
---@return number
function Camera2D:getParallaxFactor(layer) end

--- Returns the camera's world-space position as x, y.
---@return number
function Camera2D:getPosition() end

--- Returns the rotation in radians.
---@return number
function Camera2D:getRotation() end

--- Returns the current viewport as x, y, w, h.
---@return number
function Camera2D:getViewport() end

--- Returns the visible world area as x, y, w, h.
---@return number
function Camera2D:getVisibleArea() end

--- Returns the current zoom factor.
---@return number
function Camera2D:getZoom() end

--- Returns true if the breathing effect is currently active.
---@return boolean
function Camera2D:isBreathing() end

--- Returns true if the sway effect is currently active.
---@return boolean
function Camera2D:isSway() end

--- Instantly moves the camera to look at the given position.
---@param x any
---@param y any
---@return nil
function Camera2D:lookAt(x, y) end

--- Translates the camera by dx, dy in world space.
---@param dx any
---@param dy any
---@return nil
function Camera2D:move(dx, dy) end

--- Returns the fractional progress `[0, 1]` of the active path, or
---@return number
function Camera2D:pathProgress() end

--- Removes previously set world-space bounds.
---@return nil
function Camera2D:removeBounds() end

--- Sets the dead zone half-extents for camera follow.
---@param w any
---@param h any
---@return nil
function Camera2D:setDeadZone(w, h) end

--- Sets the follow smooth interpolation speed (0.0 = instant snap).
---@param speed any
---@return nil
function Camera2D:setFollowSmooth(speed) end

--- Sets the look-ahead multiplier for follow prediction.
---@param mul any
---@return nil
function Camera2D:setLookAhead(mul) end

--- Sets the camera's world-space position.
---@param x any
---@param y any
---@return nil
function Camera2D:setPosition(x, y) end

--- Sets the rotation in radians.
---@param r any
---@return nil
function Camera2D:setRotation(r) end

--- Sets the follow target position.
---@param x any
---@param y any
---@return nil
function Camera2D:setTarget(x, y) end

--- Sets the uniform zoom factor (1.0 = natural size).
---@param zoom any
---@return nil
function Camera2D:setZoom(zoom) end

--- Starts a screen-shake effect.
---@param intensity any
---@param duration any
---@return nil
function Camera2D:shake(intensity, duration) end

--- Stops the active breathing effect.
---@return nil
function Camera2D:stopBreathing() end

--- Cancels the active camera path animation.
---@return nil
function Camera2D:stopPath() end

--- Stops the active sway effect immediately.
---@return nil
function Camera2D:stopSway() end

--- Cancels the active zoom tween.
---@return nil
function Camera2D:stopZoom() end

--- Converts world coordinates to screen coordinates.
---@param wx any
---@param wy any
---@return number
function Camera2D:toScreen(wx, wy) end

--- Converts screen coordinates to world coordinates.
---@param sx any
---@param sy any
---@return number
function Camera2D:toWorld(sx, sy) end

--- Advances the camera simulation by dt seconds.
---@param dt any
---@return nil
function Camera2D:update(dt) end

--- Advances the path animation by `dt` seconds and applies the
---@param dt any
---@return boolean
function Camera2D:updatePath(dt) end

--- Advances the zoom tween by `dt` seconds and applies the resulting
---@param dt any
---@return boolean
function Camera2D:updateZoom(dt) end

--- Triggers a momentary zoom-in that decays back via a sine envelope.
---@param amplitude any
---@param duration any
---@return nil
function Camera2D:zoomPulse(amplitude, duration) end

--- Smoothly tweens the camera zoom from its current level to
---@param target_zoom any
---@param duration any
---@return nil
function Camera2D:zoomTo(target_zoom, duration) end

--- Creates a new Camera2D with the given viewport dimensions.
---@param vw any
---@param vh any
function lurek.camera.new(vw, vh) end

---@class lurek.compute
lurek.compute = {}

--- Lua-side wrapper around [`NdArray`].
---@class Array
local Array = {}

--- Element-wise absolute value.
---@return Array
function Array:abs() end

--- Returns true if all elements are nonzero.
---@return boolean
function Array:all() end

--- Returns true if any element is nonzero.
---@return boolean
function Array:any() end

--- Returns the 1-based flat index of the maximum element.
---@return integer
function Array:argmax() end

--- Returns the 1-based flat index of the minimum element.
---@return integer
function Array:argmin() end

--- Bitwise AND of two Int32 arrays.
---@param other any
---@return Array
function Array:bitwiseAnd(other) end

--- Bitwise left shift of an Int32 array.
---@param amount any
---@return Array
function Array:bitwiseLShift(amount) end

--- Bitwise NOT of an Int32 array.
---@return Array
function Array:bitwiseNot() end

--- Bitwise OR of two Int32 arrays.
---@param other any
---@return Array
function Array:bitwiseOr(other) end

--- Bitwise right shift of an Int32 array.
---@param amount any
---@return Array
function Array:bitwiseRShift(amount) end

--- Bitwise XOR of two Int32 arrays.
---@param other any
---@return Array
function Array:bitwiseXor(other) end

--- Clamps each element to the given range.
---@param min any
---@param max any
---@return Array
function Array:clamp(min, max) end

--- Returns a deep copy of this array.
---@return Array
function Array:clone() end

--- 1D convolution with a kernel array (full output).
---@param kernel any
---@return Array
function Array:convolve1d(kernel) end

--- 2D convolution with zero-padding.
---@param kernel any
---@return Array
function Array:convolve2D(kernel) end

--- 1D cross-correlation with a template array (valid output).
---@param template any
---@return Array
function Array:correlate1d(template) end

--- Returns the count of nonzero elements.
---@return integer
function Array:countNonZero() end

--- Population covariance with another 1D array.
---@param other any
---@return number
function Array:covariance(other) end

--- Signed 2D cross product with another length-2 array.
---@param other any
---@return number
function Array:cross2d(other) end

--- Cumulative sum of all elements (flattened).
---@return Array
function Array:cumsum() end

--- Discrete difference applied `order` times.
---@param order? any (optional)
---@return Array
function Array:diff(order) end

--- Morphological dilation with a diamond structuring element.
---@param radius any
---@return Array
function Array:dilate(radius) end

--- Dot product of two 1D arrays.
---@param other any
---@return number
function Array:dot(other) end

--- Morphological erosion with a diamond structuring element.
---@param radius any
---@return Array
function Array:erode(radius) end

--- Evaluate a Lua expression string element-wise, returning a new Array.
---@param expr any
---@return Array
function Array:eval(expr) end

--- Fills all elements with the given value in-place.
---@param val any
---@return nil
function Array:fill(val) end

--- Returns the element at the given 1-based indices.
---@param args any
---@return number
function Array:get(args) end

--- Returns the element data type name.
---@return string
function Array:getDataType() end

--- Returns the number of dimensions.
---@return integer
function Array:getDimensions() end

--- Returns the shape as a table of dimension sizes.
---@return table
function Array:getShape() end

--- Returns the total number of elements.
---@return integer
function Array:getSize() end

--- Returns false (CPU arrays only).
---@return boolean
function Array:isOnGPU() end

--- Solve AÂ·x = b where this array is A (square [n,n]) and b is a 1D vector.
---@param b any
---@return Array
function Array:linsolve(b) end

--- Decomposes this square matrix into L and U factors with partial pivoting.
---@return table
function Array:luDecompose() end

--- Apply a Lua callback element-wise, returning a new Array of the same shape.
---@param func any
---@return Array
function Array:map(func) end

--- Matrix multiplication of two 2D arrays.
---@param other any
---@return Array
function Array:matmul(other) end

--- Maximum of all elements, or along an axis (1-based).
---@param axis? any (optional)
---@return nil
function Array:max(axis) end

--- Mean of all elements, or along an axis (1-based).
---@param axis? any (optional)
---@return nil
function Array:mean(axis) end

--- Minimum of all elements, or along an axis (1-based).
---@param axis? any (optional)
---@return nil
function Array:min(axis) end

--- Returns a new Array with every element negated (multiplied by â’1).
---@return Array
function Array:neg() end

--- Linearly rescale values to [out_min, out_max].
---@param lo any
---@param hi any
---@return Array
function Array:normalizeRange(lo, hi) end

--- L2-normalise a 1D vector.
---@return Array
function Array:normalizeVec() end

--- Outer product of two 1D vectors â†’ 2D array [m, n].
---@param other any
---@return Array
function Array:outer(other) end

--- Pearson correlation coefficient with another 1D array.
---@param other any
---@return number
function Array:pearsonCorr(other) end

--- Compute the p-th percentile (0â€“100).
---@param p any
---@return number
function Array:percentile(p) end

--- Raises each element to a scalar exponent.
---@param exp any
---@return Array
function Array:pow(exp) end

--- Fold the array left-to-right with an accumulator.
---@param func any
---@param init any
---@return number
function Array:reduce(func, init) end

--- Returns a new array with the given shape and the same data.
---@param shape any
---@return Array
function Array:reshape(shape) end

--- Running accumulation — like reduce but returns every intermediate result.
---@param func any
---@param init any
---@return Array
function Array:scan(func, init) end

--- Sets the element at the given 1-based indices to a value.
---@param args any
---@return nil
function Array:set(args) end

--- Apply Sobel edge detection to a 2D array. Returns {gx=Array, gy=Array}.
---@return table
function Array:sobel() end

--- Element-wise square root.
---@return Array
function Array:sqrt() end

--- Sum of all elements, or along an axis (1-based).
---@param axis? any (optional)
---@return nil
function Array:sum(axis) end

--- Returns a mask array with 1.0 where elements >= val, else 0.0.
---@param val any
---@return Array
function Array:threshold(val) end

--- Returns all elements as a flat table of numbers.
---@return table
function Array:toTable() end

--- Apply this 2Ă—2 or 3Ă—3 matrix to an [N,2] points array.
---@param pts any
---@return Array
function Array:transformPoints(pts) end

--- Returns the transposed 2D array.
---@return Array
function Array:transpose() end

--- Returns the type name "Array".
---@return string
function Array:type() end

--- Returns true when the given name matches "Array" or a parent type.
---@param name any
---@return boolean
function Array:typeOf(name) end

--- Standardise values to zero mean and unit variance.
---@return Array
function Array:zscore() end

--- Creates a 3Ă—3 homogeneous affine matrix.
---@param tx any
---@param ty any
---@param angle_rad any
---@param sx any
---@param sy any
---@return Array
function lurek.compute.affine2d(tx, ty, angle_rad, sx, sy) end

--- Computes the discrete Fourier transform of a 1D real-valued sample array.
---@param samples any
---@return table
function lurek.compute.fft(samples) end

--- Returns the magnitude spectrum `|X[k]|` of a real-valued sample array.
---@param samples any
---@return table
function lurek.compute.fftMagnitude(samples) end

--- Creates an array from a Lua table of numbers with optional shape and dtype.
---@param data any
---@param shape? any (optional)
---@param dtype? any (optional)
---@return Array
function lurek.compute.fromTable(data, shape, dtype) end

--- Creates a sizeĂ—size Gaussian kernel array.
---@param size any
---@param sigma any
---@return Array
function lurek.compute.gaussianKernel(size, sigma) end

--- Computes the inverse discrete Fourier transform.
---@param freqs any
---@return table
function lurek.compute.ifft(freqs) end

--- Creates a zero-initialized array with the given shape and optional dtype.
---@param shape any
---@param dtype? any (optional)
---@return Array
function lurek.compute.newArray(shape, dtype) end

--- Creates a one-filled array with the given shape and optional dtype.
---@param shape any
---@param dtype? any (optional)
---@return Array
function lurek.compute.ones(shape, dtype) end

--- Creates a 1D array from start to stop with optional step and dtype.
---@param start any
---@param stop any
---@param step? any (optional)
---@param dtype? any (optional)
---@return Array
function lurek.compute.range(start, stop, step, dtype) end

--- Creates a 2Ă—2 rotation matrix for the given angle in radians.
---@param angle_rad any
---@return Array
function lurek.compute.rotate2dMatrix(angle_rad) end

--- Creates a zero-filled array with the given shape and optional dtype.
---@param shape any
---@param dtype? any (optional)
---@return Array
function lurek.compute.zeros(shape, dtype) end

---@class lurek.data
lurek.data = {}

--- Access structured binary data efficiently without copying.
---@class DataView
local DataView = {}

--- Reads a 64-bit float at the given offset.
---@param offset any
---@return number
function DataView:getDouble(offset) end

--- Reads a 32-bit float at the given offset.
---@param offset any
---@return number
function DataView:getFloat(offset) end

--- Reads a signed 16-bit integer at the given offset.
---@param offset any
---@return integer
function DataView:getInt16(offset) end

--- Reads a signed 32-bit integer at the given offset.
---@param offset any
---@return integer
function DataView:getInt32(offset) end

--- Reads a signed 8-bit integer at the given offset.
---@param offset any
---@return integer
function DataView:getInt8(offset) end

--- Returns the size of this view in bytes.
---@return integer
function DataView:getSize() end

--- Reads an unsigned 16-bit integer at the given offset.
---@param offset any
---@return integer
function DataView:getUInt16(offset) end

--- Reads an unsigned 32-bit integer at the given offset.
---@param offset any
---@return integer
function DataView:getUInt32(offset) end

--- Reads an unsigned 8-bit integer at the given offset.
---@param offset any
---@return integer
function DataView:getUInt8(offset) end

--- Write-cursor wrapper for the `lurek.data` module.
---@class DataWriter
local DataWriter = {}

--- Returns the total buffer length.
---@return integer
function DataWriter:len() end

--- Moves the write cursor to the given position.
---@param pos any
function DataWriter:seek(pos) end

--- Returns the current write cursor position.
---@return integer
function DataWriter:tell() end

--- Returns the buffer contents as a Lua string.
---@return string
function DataWriter:toBytes() end

--- Writes raw bytes from a Lua string.
---@param value string
function DataWriter:writeBytes(value) end

--- Writes a 32-bit LE float.
---@param v any
function DataWriter:writeF32LE(v) end

--- Writes a 64-bit LE float.
---@param v any
function DataWriter:writeF64LE(v) end

--- Writes a signed 16-bit LE integer.
---@param v any
function DataWriter:writeI16LE(v) end

--- Writes a signed 32-bit LE integer.
---@param v any
function DataWriter:writeI32LE(v) end

--- Writes a signed 8-bit integer.
---@param v any
function DataWriter:writeI8(v) end

--- Writes a length-prefixed UTF-8 string (4-byte LE length + bytes).
---@param s any
function DataWriter:writeString(s) end

--- Writes an unsigned 16-bit BE integer.
---@param v any
function DataWriter:writeU16BE(v) end

--- Writes an unsigned 16-bit LE integer.
---@param v any
function DataWriter:writeU16LE(v) end

--- Writes an unsigned 32-bit LE integer.
---@param v any
function DataWriter:writeU32LE(v) end

--- Writes an unsigned 8-bit integer.
---@param v any
function DataWriter:writeU8(v) end

--- Lua-side fixed-capacity ring buffer that holds any Lua value.
---@class RingBuffer
local RingBuffer = {}

--- Returns the maximum number of elements the buffer can hold.
---@return integer
function RingBuffer:capacity() end

--- Removes all elements from the buffer, releasing their registry entries.
---@return nil
function RingBuffer:clear() end

--- Returns true if the buffer contains no elements.
---@return boolean
function RingBuffer:isEmpty() end

--- Returns the number of elements currently in the buffer.
---@return integer
function RingBuffer:len() end

--- Returns the oldest element without removing it, or nil if empty.
---@return table|nil
function RingBuffer:peek() end

--- Returns the newest element without removing it, or nil if empty.
---@return table|nil
function RingBuffer:peekNewest() end

--- Removes and returns the oldest element, or nil if the buffer is empty.
---@return table|nil
function RingBuffer:pop() end

--- Pushes a value onto the ring buffer.
---@param value any
---@return boolean
function RingBuffer:push(value) end

--- Returns all elements as an array table ordered oldest-first.
---@return table
function RingBuffer:toTable() end

---@class mlua
local mlua = {}

--- Clone the ByteData.
---@return ByteData
function mlua:clone() end

--- Get a byte at the specified offset.
---@param offset any
---@return integer
function mlua:getByte(offset) end

--- Get the size.
---@return integer
function mlua:getSize() end

--- Get the string representation.
---@return string
function mlua:getString() end

--- Set a byte at the specified offset.
---@param offset any
---@param value any
---@return nil
function mlua:setByte(offset, value) end

--- Compresses data using the given algorithm (deflate, gzip, lz4).
---@param format_str any
---@param raw_data any
---@param level? any (optional)
---@return string
function lurek.data.compress(format_str, raw_data, level) end

--- Returns the CRC-32 checksum of the input data as an integer.
---@param raw_data any
---@return integer
function lurek.data.crc32(raw_data) end

--- Decodes encoded text back to binary (base64, hex).
---@param format_str any
---@param encoded any
---@return string
function lurek.data.decode(format_str, encoded) end

--- Decompresses data using the given algorithm (deflate, gzip, lz4).
---@param format_str any
---@param compressed any
---@return string
function lurek.data.decompress(format_str, compressed) end

--- Encodes binary data using the given format (base64, hex).
---@param format_str any
---@param raw_data any
---@return string
function lurek.data.encode(format_str, raw_data) end

--- Encodes a Lua table into a TOML string.
---@param tbl any
---@return string
function lurek.data.encodeToml(tbl) end

--- Deserializes a MessagePack binary string back into a Lua value.
---@param bytes any
---@return table|nil
function lurek.data.fromMsgPack(bytes) end

--- Returns the number of bytes the given format and values would occupy.
---@param fmt any
---@param vals any
---@return integer
function lurek.data.getPackedSize(fmt, vals) end

--- Returns the cryptographic hash of the input (md5, sha1, sha256, sha512).
---@param algo_str any
---@param raw_data any
---@return string
function lurek.data.hash(algo_str, raw_data) end

--- Creates a read-only windowed view into a byte string.
---@param raw any
---@param offset? any (optional)
---@param size? any (optional)
---@return DataView
function lurek.data.newDataView(raw, offset, size) end

--- Creates a fixed-capacity ring buffer that can store any Lua value.
---@param capacity any
---@return RingBuffer
function lurek.data.newRingBuffer(capacity) end

--- Creates a new write-cursor for building binary data.
---@return DataWriter
function lurek.data.newWriter() end

--- Packs values into a binary byte string using the format string.
---@param fmt any
---@param vals any
---@return string
function lurek.data.pack(fmt, vals) end

--- Parses a TOML string into a Lua table.
---@param text any
---@return table
function lurek.data.parseToml(text) end

--- Reads values using the Lurek2D Binary Pack Format.
---@param fmt any
---@param raw any
---@param offset? any (optional)
---@return table|nil
function lurek.data.read(fmt, raw, offset) end

--- Returns the byte size of a Lurek2D Binary Pack Format string.
---@param fmt any
---@return integer
function lurek.data.size(fmt) end

--- Serializes a Lua value (table, string, number, boolean, or nil) to MessagePack binary.
---@param value any
---@return string
function lurek.data.toMsgPack(value) end

--- Unpacks values from a binary byte string, returning values followed by next offset.
---@param fmt any
---@param raw any
---@param offset? any (optional)
---@return table|nil
function lurek.data.unpack(fmt, raw, offset) end

--- Writes values using the Lurek2D Binary Pack Format.
---@param fmt any
---@param vals any
---@return string
function lurek.data.write(fmt, vals) end

---@class lurek.dataframe
lurek.dataframe = {}

--- Lua-side wrapper around a shared [`DataFrame`].
---@class DataFrame
local DataFrame = {}

--- Adds a row from an optional table of name-value pairs, returns 1-based index.
---@param row_tbl? any (optional)
---@return integer
function DataFrame:addRow(row_tbl) end

--- Add multiple rows at once from a table of row tables.
---@param rows any
---@return nil
function DataFrame:addRowBatch(rows) end

--- Returns a deep copy of this DataFrame.
---@return DataFrame
function DataFrame:clone() end

--- Returns a table of column names.
---@return table
function DataFrame:columns() end

--- Compute a correlation matrix for all numeric columns.
---@return DataFrame
function DataFrame:correlationMatrix() end

--- Returns the row count (alias for nrows).
---@return integer
function DataFrame:count() end

--- Counts distinct values in a column, returns a DataFrame with value and count columns.
---@param col any
---@return DataFrame
function DataFrame:countBy(col) end

--- Returns descriptive statistics for all numeric columns.
---@return DataFrame
function DataFrame:describe() end

--- Removes rows where the given column is nil, returns a new DataFrame.
---@param col any
---@return DataFrame
function DataFrame:dropNil(col) end

--- Shannon entropy (bits) of the value distribution in a column.
---@param col any
---@return number
function DataFrame:entropy(col) end

--- Replaces nil values in a column with the given value.
---@param col any
---@param val any
---@return nil
function DataFrame:fillNil(col, val) end

--- Returns all values in a column as a table.
---@param col any
---@return table
function DataFrame:getColumn(col) end

--- Return a numeric column as a Lua array of numbers (nils → 0/nan).
---@param col any
---@return table
function DataFrame:getColumnAsF64(col) end

--- Returns a row as a table of name-value pairs.
---@param row any
---@return table
function DataFrame:getRow(row) end

--- Returns a single cell value.
---@param row any
---@param col any
---@return LuaValue
function DataFrame:getValue(row, col) end

--- Groups rows by column value, returns a table of DataFrames keyed by value.
---@param col any
---@return table
function DataFrame:groupBy(col) end

--- Groups rows by column value, returns a GroupedFrame object supporting aggregate().
---@param col any
---@return GroupedFrame
function DataFrame:groupByObj(col) end

--- Returns the first n rows (default 5).
---@param n? any (optional)
---@return DataFrame
function DataFrame:head(n) end

--- Returns the maximum numeric value in a column.
---@param col any
---@return number
function DataFrame:max(col) end

--- Returns the mean of numeric values in a column.
---@param col any
---@return number
function DataFrame:mean(col) end

--- Returns the median of numeric values in a column.
---@param col any
---@return number
function DataFrame:median(col) end

--- Appends rows from another DataFrame in-place.
---@param other any
---@return nil
function DataFrame:merge(other) end

--- Returns the minimum numeric value in a column.
---@param col any
---@return number
function DataFrame:min(col) end

--- Return the most frequent value in a column (nil if empty).
---@param col any
---@return table|nil
function DataFrame:modeVal(col) end

--- Returns the number of columns.
---@return integer
function DataFrame:ncols() end

--- Returns the number of rows.
---@return integer
function DataFrame:nrows() end

--- Executes a SQL query against this DataFrame.
---@param sql_str any
---@return DataFrame
function DataFrame:query(sql_str) end

--- Removes a column by name or index.
---@param col any
---@return nil
function DataFrame:removeColumn(col) end

--- Removes a row by 1-based index.
---@param row any
---@return nil
function DataFrame:removeRow(row) end

--- Renames the column `old_name` to `new_name` in this DataFrame.
---@param col any
---@param new_name any
---@return nil
function DataFrame:rename(col, new_name) end

--- Returns a random sample of n rows.
---@param n any
---@param seed? any (optional)
---@return DataFrame
function DataFrame:sample(n, seed) end

--- Selects a subset of columns, returns a new DataFrame.
---@param cols any
---@return DataFrame
function DataFrame:select(cols) end

--- Set a numeric column from a Lua array of numbers.
---@param col any
---@param values any
---@return nil
function DataFrame:setColumnFromF64(col, values) end

--- Returns rows from start to end (1-based, inclusive).
---@param start any
---@param end any
---@return DataFrame
function DataFrame:slice(start, end) end

--- Returns the population standard deviation of numeric values in a column.
---@param col any
---@return number
function DataFrame:stddev(col) end

--- Returns the sum of numeric values in a column.
---@param col any
---@return number
function DataFrame:sum(col) end

--- Returns the last n rows (default 5).
---@param n? any (optional)
---@return DataFrame
function DataFrame:tail(n) end

--- Serializes this DataFrame to a binary LVDF string.
---@param lua Lua
---@return string
function DataFrame:toBinary(lua) end

--- Serializes this DataFrame to a CSV string.
---@return string
function DataFrame:toCSV() end

--- Serializes this DataFrame to a JSON string.
---@return string
function DataFrame:toJSON() end

--- Returns a formatted string table representation.
---@return string
function DataFrame:toString() end

--- Converts this DataFrame to a Lua table of row tables.
---@return table
function DataFrame:toTable() end

--- Returns the type name of this object.
---@return string
function DataFrame:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function DataFrame:typeOf(name) end

--- Returns unique values in a column as a table.
---@param col any
---@return table
function DataFrame:unique(col) end

--- Returns the population variance of numeric values in a column.
---@param col any
---@return number
function DataFrame:variance(col) end

--- Returns a new DataFrame with an additional computed column named `col_name`.
---@param col_name any
---@param expr any
---@return DataFrame
function DataFrame:withEval(col_name, expr) end

--- Lua-side wrapper around a shared [`Database`].
---@class Database
local Database = {}

--- Drops every table from this in-memory database, leaving it empty.
---@return nil
function Database:clear() end

--- Returns a copy of a table by name, or nil if not found.
---@param name any
---@return nil
function Database:getTable(name) end

--- Returns true if a table with the given name exists.
---@param name any
---@return boolean
function Database:hasTable(name) end

--- Returns a table of all table names.
---@return table
function Database:listTables() end

--- Merges all tables from another Database into this one.
---@param other any
---@return nil
function Database:merge(other) end

--- Executes a SQL query against the database tables.
---@param sql_str any
---@return DataFrame
function Database:query(sql_str) end

--- Drops the named table from this in-memory database if it exists.
---@param name any
---@return nil
function Database:removeTable(name) end

--- Returns the number of tables.
---@return integer
function Database:tableCount() end

--- Serializes all tables to a JSON object string.
---@return string
function Database:toJSON() end

--- Returns the type name of this object.
---@return string
function Database:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function Database:typeOf(name) end

--- Lua-side wrapper around a grouped result from [`DataFrame::group_by`].
---@class GroupedFrame
local GroupedFrame = {}

--- Apply a Lua function to aggregate a column's values per group.
---@param col_name any
---@param func any
---@return DataFrame
function GroupedFrame:aggregate(col_name, func) end

--- Thin Lua wrapper around a [`VecFrame`]: typed-column vectorized DataFrame.
---@class VecFrame
local VecFrame = {}

--- Return a new VecFrame containing only the rows where mask[i] is true.
---@param mask_tbl any
---@return VecFrame
function VecFrame:applyMask(mask_tbl) end

--- Apply absolute value to every element of a Float64 column.
---@param col any
function VecFrame:colAbs(col) end

--- Add a scalar to every element of a Float64 column.
---@param col any
---@param val any
function VecFrame:colAdd(col, val) end

--- Cast a column to a new dtype: "float64", "int64", or "text".
---@param col any
---@param dtype any
function VecFrame:colCast(col, dtype) end

--- Apply ceiling to every element of a Float64 column.
---@param col any
function VecFrame:colCeil(col) end

--- Divide every element of a Float64 column by a scalar.
---@param col any
---@param val any
function VecFrame:colDiv(col, val) end

--- Apply floor to every element of a Float64 column.
---@param col any
function VecFrame:colFloor(col) end

--- Multiply every element of a Float64 column by a scalar.
---@param col any
---@param val any
function VecFrame:colMul(col, val) end

--- Negate every element of a Float64 column.
---@param col any
function VecFrame:colNeg(col) end

--- Apply square root to every element of a Float64 column.
---@param col any
function VecFrame:colSqrt(col) end

--- Subtract a scalar from every element of a Float64 column.
---@param col any
---@param val any
function VecFrame:colSub(col, val) end

--- Return the dtype name of a column: "float64", "int64", "bool", or "text".
---@param col any
---@return string|nil
function VecFrame:colType(col) end

--- Return a table of column names.
---@return table
function VecFrame:columns() end

--- Return the number of columns.
---@return integer
function VecFrame:ncols() end

--- Return the number of rows.
---@return integer
function VecFrame:nrows() end

--- Reduce multiple columns in parallel, returning {col → value} table.
---@param cols_tbl any
---@param op any
---@return table
function VecFrame:parReduce(cols_tbl, op) end

--- Reduce an entire numeric column to a single value.
---@param col any
---@param op any
---@return number|nil
function VecFrame:reduce(col, op) end

--- Convert this VecFrame back to a DataFrame.
---@return DataFrame
function VecFrame:toDataFrame() end

--- Returns the type name of this object.
---@return string
function VecFrame:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function VecFrame:typeOf(name) end

--- Deserializes a binary LVDF string into a DataFrame.
---@param s any
---@return DataFrame
function lurek.dataframe.fromBinary(s) end

--- Parses a CSV string into a DataFrame.
---@param s any
---@return DataFrame
function lurek.dataframe.fromCSV(s) end

--- Parses a JSON string into a DataFrame.
---@param s any
---@return DataFrame
function lurek.dataframe.fromJSON(s) end

--- Creates a DataFrame from an array of row tables.
---@param rows any
---@return DataFrame
function lurek.dataframe.fromTable(rows) end

--- Converts a VecFrame back to a DataFrame.
---@param vf any
---@return DataFrame
function lurek.dataframe.fromVec(vf) end

--- Creates a new empty DataFrame.
---@return DataFrame
function lurek.dataframe.newDataFrame() end

--- Creates a new empty Database.
---@return Database
function lurek.dataframe.newDatabase() end

--- Generates a DataFrame with random data from column definitions.
---@param defs_tbl any
---@param n any
---@param seed? any (optional)
---@return DataFrame
function lurek.dataframe.random(defs_tbl, n, seed) end

--- Converts a DataFrame to a VecFrame for vectorized column operations.
---@param df any
---@return VecFrame
function lurek.dataframe.toVec(df) end

---@class lurek.debugbridge
lurek.debugbridge = {}

--- Broadcasts a JSON event to all connected clients.
---@param event any
---@param json_data any
function lurek.debugbridge.broadcast(event, json_data) end

--- Captures a print message and broadcasts it to connected clients.
---@param msg any
---@param source? any (optional)
---@param line? any (optional)
function lurek.debugbridge.capturePrint(msg, source, line) end

--- Clears the print history.
function lurek.debugbridge.clearPrintHistory() end

--- Returns the number of connected TCP clients.
---@return integer
function lurek.debugbridge.getClientCount() end

--- Returns performance statistics.
---@return table
function lurek.debugbridge.getPerformance() end

--- Returns the server port (0 if not running).
---@return integer
function lurek.debugbridge.getPort() end

--- Returns the print history.
---@param count? any (optional)
---@return table
function lurek.debugbridge.getPrintHistory(count) end

--- Returns whether the server is currently running.
---@return bool
function lurek.debugbridge.isRunning() end

--- Returns whether a screenshot is currently requested.
---@return bool
function lurek.debugbridge.isScreenshotRequested() end

--- Poll for pending Lua-dependent requests from TCP clients.
---@return table|nil
function lurek.debugbridge.poll() end

--- Flags a screenshot request for the next frame.
---@param scale? any (optional)
function lurek.debugbridge.requestScreenshot(scale) end

--- Sets the maximum print history size.
---@param max any
function lurek.debugbridge.setMaxPrintHistory(max) end

--- Start the TCP debug server on 127.0.0.1:port.
---@param port? any (optional)
---@return boolean
function lurek.debugbridge.start(port) end

--- Stop the TCP debug server and close all connections.
function lurek.debugbridge.stop() end

---@class lurek.devtools
lurek.devtools = {}

--- Lua-side handle for a per-path file watcher.
---@class FileWatcher
local FileWatcher = {}

--- Removes the stored `onChanged` callback and stops future notifications.
---@return nil
function FileWatcher:cancel() end

--- Polls the watcher. If the file has changed since the last call, fires the
---@return boolean
function FileWatcher:check() end

--- Returns the watched path string.
---@return string
function FileWatcher:getPath() end

--- Registers a callback invoked (with no arguments) when the watched path changes.
---@param func any
---@return nil
function FileWatcher:onChanged(func) end

--- Lua-side wrapper around a [`ReplConsole`] interactive evaluator.
---@class ReplConsole
local ReplConsole = {}

--- Clears the REPL history buffer.
---@return nil
function ReplConsole:clear() end

--- Evaluates a Lua snippet and records the input in history.
---@param code any
---@return string
function ReplConsole:eval(code) end

--- Returns an ordered array of past inputs (oldest first).
---@return table
function ReplConsole:history() end

--- Returns the number of history entries.
---@return integer
function ReplConsole:len() end

--- Discards all accumulated log entries from the in-memory devtools log buffer.
---@return nil
function lurek.devtools.clearLog() end

--- Clears all watched paths.
---@return nil
function lurek.devtools.clearWatches() end

--- Evaluates a Lua string and returns (success, results...).
---@param code any
---@return boolean
function lurek.devtools.eval(code) end

--- Registers a named live watch. The getter function is called on demand to sample a value.
---@param name any
---@param getter any
---@param category? any (optional)
---@return integer
function lurek.devtools.exposeWatch(name, getter, category) end

--- Returns the Lua call stack as a table of frames.
---@param max_depth? any (optional)
---@return table
function lurek.devtools.getCallStack(max_depth) end

--- Returns the raw frame-time sample array.
---@return table
function lurek.devtools.getFrameHistory() end

--- Returns the current frame-history buffer capacity.
---@return integer
function lurek.devtools.getFrameHistorySize() end

--- Returns a table of computed frame statistics.
---@return table
function lurek.devtools.getFrameStats() end

--- Returns whether console log output is enabled.
---@return boolean
function lurek.devtools.getLogConsole() end

--- Returns the current log file path.
---@return string
function lurek.devtools.getLogFile() end

--- Returns recent log entries as an array of tables.
---@param count? any (optional)
---@return table
function lurek.devtools.getLogHistory(count) end

--- Returns the current minimum log level.
---@return string
function lurek.devtools.getLogLevel() end

--- Returns zone data table for a specific frame (0 or nil = most recent).
---@param frame? any (optional)
---@return table
function lurek.devtools.getProfileData(frame) end

--- Returns the number of retained profile frames.
---@return integer
function lurek.devtools.getProfileFrameCount() end

--- Returns the file watch poll interval in seconds.
---@return number
function lurek.devtools.getWatchInterval() end

--- Returns an array of all watched paths.
---@return table
function lurek.devtools.getWatchedPaths() end

--- Calls all registered watch getters and returns a table of {name, category, value} records.
---@return table
function lurek.devtools.getWatches() end

--- Returns whether the console is considered open.
---@return boolean
function lurek.devtools.isConsoleOpen() end

--- Returns whether the profiler is enabled.
---@return boolean
function lurek.devtools.isProfilingEnabled() end

--- Logs a message at the given level.
---@param level any
---@param message any
---@return nil
function lurek.devtools.log(level, message) end

--- Creates a standalone per-path file watcher. Call `:check()` once per frame
---@param path any
---@return FileWatcher
function lurek.devtools.newFileWatcher(path) end

--- Creates an interactive Lua REPL console with a bounded history buffer.
---@param max_history? any (optional)
---@return ReplConsole
function lurek.devtools.newRepl(max_history) end

--- Opens the console window (updates the console flag; returns true).
---@return boolean
function lurek.devtools.openConsole() end

--- Seals the current frame of profiling data.
---@return nil
function lurek.devtools.profileFrame() end

--- Closes the most recent profiling zone.
---@return nil
function lurek.devtools.profilePop() end

--- Opens a named profiling zone on the stack.
---@param name any
---@return nil
function lurek.devtools.profilePush(name) end

--- Returns a flat summary table of all recorded profiler zones across all stored
---@return table
function lurek.devtools.profilerReport() end

--- Records a frame-time sample (call each frame with delta time in seconds).
---@param dt_val any
---@return nil
function lurek.devtools.recordFrameTime(dt_val) end

--- Removes a watch by the id returned from exposeWatch. Returns true if removed.
---@param id any
---@return boolean
function lurek.devtools.removeWatch(id) end

--- Clears all profiling data and resets the zone stack.
---@return nil
function lurek.devtools.resetProfile() end

--- Polls all watched paths and returns paths whose mtime changed.
---@return table
function lurek.devtools.scan() end

--- Sets the frame-history buffer capacity (clamped 10-10000).
---@param size any
---@return nil
function lurek.devtools.setFrameHistorySize(size) end

--- Enables or disables console log output.
---@param enabled any
---@return nil
function lurek.devtools.setLogConsole(enabled) end

--- Sets the log file path (empty string disables file output).
---@param path any
---@return nil
function lurek.devtools.setLogFile(path) end

--- Sets the minimum log level.
---@param level any
---@return nil
function lurek.devtools.setLogLevel(level) end

--- Enables or disables the profiler.
---@param enabled any
---@return nil
function lurek.devtools.setProfilingEnabled(enabled) end

--- Sets the file watch poll interval in seconds.
---@param interval any
---@return nil
function lurek.devtools.setWatchInterval(interval) end

--- Takes a structured snapshot of all watches + frame stats + last profile frame.
---@return table
function lurek.devtools.snapshot() end

--- Removes a file path from the watch list.
---@param path any
---@return boolean
function lurek.devtools.unwatch(path) end

--- Adds a file path to the watch list. Returns false if already watched.
---@param path any
---@return boolean
function lurek.devtools.watch(path) end

---@class lurek.docs
lurek.docs = {}

--- Wraps a catalog snapshot of API entries for Lua access.
---@class ApiCatalog
local ApiCatalog = {}

--- Returns the number of entries, optionally scoped to a module.
---@param module? any (optional)
---@return integer
function ApiCatalog:entryCount(module) end

--- Returns a new catalog containing only entries for which predicate returns true.
---@param predicate any
---@return ApiCatalog
function ApiCatalog:filter(predicate) end

--- Returns all entries, optionally filtered to a single module.
---@param module? any (optional)
---@return table
function ApiCatalog:getEntries(module) end

--- Returns a single entry by qualified name, or nil.
---@param qualified_name any
---@return nil
function ApiCatalog:getEntry(qualified_name) end

--- Returns a sorted list of module names present in the catalog.
---@return table
function ApiCatalog:getModules() end

--- Returns entries that are methods of the given type qualified name.
---@param qualified_name any
---@return table
function ApiCatalog:getTypeMethods(qualified_name) end

--- Returns the names of all entries with kind "type" in the given module.
---@param module_name any
---@return table
function ApiCatalog:getTypes(module_name) end

--- Returns a new catalog that is the union of this and another catalog, with other overriding duplicates.
---@param other any
---@return ApiCatalog
function ApiCatalog:merge(other) end

--- Returns a table of entries whose name, qualified name, or description contains query.
---@param query any
---@return table
function ApiCatalog:search(query) end

--- Serialises the catalog to a pretty-printed JSON string.
---@return string
function ApiCatalog:toJSON() end

--- Converts the catalog to a plain Lua table array.
---@return table
function ApiCatalog:toTable() end

--- Wraps a single doc entry for Lua access.
---@class DocEntry
local DocEntry = {}

--- Returns the deprecation message, or nil.
---@return string?
function DocEntry:getDeprecated() end

--- Returns the human-readable description text for this documentation entry.
---@return string
function DocEntry:getDescription() end

--- Returns the example snippet, or nil.
---@return string?
function DocEntry:getExample() end

--- Returns the kind tag for this entry (e.g. `'function'`, `'method'`, `'class'`).
---@return string
function DocEntry:getKind() end

--- Returns the Lua module name this entry belongs to (e.g. `'lurek.math'`).
---@return string
function DocEntry:getModule() end

--- Returns the symbol name for this documentation entry.
---@return string
function DocEntry:getName() end

--- Returns the parameters as a table of `{name, type, description, optional, default?}` records.
---@return table
function DocEntry:getParameters() end

--- Returns the qualified name.
---@return string
function DocEntry:getQualifiedName() end

--- Returns the return values as a table of `{type, description}` records.
---@return table
function DocEntry:getReturns() end

--- Returns the quality score in [0,1].
---@return number
function DocEntry:getScore() end

--- Returns the since version string, or nil.
---@return string?
function DocEntry:getSince() end

--- Returns true when the entry has a non-empty description.
---@return boolean
function DocEntry:hasDescription() end

--- Returns true when the entry has an example snippet.
---@return boolean
function DocEntry:hasExample() end

--- Returns true when the entry has at least one parameter.
---@return boolean
function DocEntry:hasParameters() end

--- Returns true when the entry declares at least one return type.
---@return boolean
function DocEntry:hasReturnType() end

--- Wraps documentation quality metrics for Lua access.
---@class QualityReport
local QualityReport = {}

--- Returns up to count entries with the highest quality scores.
---@param count? any (optional)
---@return table
function QualityReport:getBest(count) end

--- Returns entries whose grade exactly matches the given letter grade.
---@param grade any
---@return table
function QualityReport:getByGrade(grade) end

--- Returns the letter grade for the overall score.
---@return string
function QualityReport:getGrade() end

--- Returns a table mapping module name to its average quality score.
---@return table
function QualityReport:getModuleScores() end

--- Returns the overall quality score in [0,1].
---@return number
function QualityReport:getOverallScore() end

--- Returns a multi-line human-readable summary of quality by module.
---@return string
function QualityReport:getSummary() end

--- Returns up to count entries with the lowest quality scores.
---@param count? any (optional)
---@return table
function QualityReport:getWorst(count) end

--- Serialises the quality report to a pretty-printed JSON string.
---@return string
function QualityReport:toJSON() end

--- Converts the quality report to a plain Lua table.
---@return table
function QualityReport:toTable() end

--- Lua wrapper for a runtime data-validation schema.
---@class Schema
local Schema = {}

--- Validates data and throws a Lua error on failure with all error messages joined.
---@param data any
---@return nil
function Schema:assert(data) end

--- Returns true when the data passes all schema rules.
---@param data any
---@return boolean
function Schema:check(data) end

--- Returns a table of declared field names.
---@return table
function Schema:getFields() end

--- Returns the name identifier of this API schema group.
---@return string
function Schema:getName() end

--- Validates a Lua table against the schema.
---@param data any
---@return nil
function Schema:validate(data) end

--- Wraps a validation report for Lua access.
---@class ValidationReport
local ValidationReport = {}

--- Returns the list of qualified names whose catalog entry is incomplete.
---@return table
function ValidationReport:getIncomplete() end

--- Returns the list of qualified names present in the live API but missing from the catalog.
---@return table
function ValidationReport:getMissing() end

--- Returns the list of qualified names in the catalog that are not present in the live API.
---@return table
function ValidationReport:getPhantom() end

--- Returns a single-line summary of the validation results.
---@return string
function ValidationReport:getSummary() end

--- Returns the count of incomplete entries.
---@return integer
function ValidationReport:incompleteCount() end

--- Returns true when the report has no missing entries.
---@return boolean
function ValidationReport:isValid() end

--- Returns the count of missing entries.
---@return integer
function ValidationReport:missingCount() end

--- Returns the count of phantom entries.
---@return integer
function ValidationReport:phantomCount() end

--- Serialises the report to a pretty-printed JSON string.
---@return string
function ValidationReport:toJSON() end

--- Converts the report to a plain Lua table.
---@return table
function ValidationReport:toTable() end

--- Compare catalog entries against source files in a directory for staleness.
---@param catalog_ud any
---@param source_dir any
---@return table
function lurek.docs.checkStaleness(catalog_ud, source_dir) end

--- Return (documented_count, total_live_count) coverage tuple.
---@param catalog_ud? any (optional)
---@return integer
function lurek.docs.coverage(catalog_ud) end

--- Return (documented_count, total_live_count) for a single module.
---@param module_name any
---@param catalog_ud? any (optional)
---@return integer
function lurek.docs.coverageModule(module_name, catalog_ud) end

--- Inject or update a description for a named API entry.
---@param qualified_name any
---@param description any
function lurek.docs.describe(qualified_name, description) end

--- Export completions.json, hover.json, and signatures.json to a directory.
---@param catalog_ud any
---@param output_dir any
function lurek.docs.exportAll(catalog_ud, output_dir) end

--- Export a one-line-per-function plain-text cheatsheet.
---@param catalog_ud any
---@param path any
function lurek.docs.exportCheatsheet(catalog_ud, path) end

--- Export VS Code IntelliSense completions JSON to a file.
---@param catalog_ud any
---@param path any
function lurek.docs.exportCompletions(catalog_ud, path) end

--- Export VS Code hover JSON to a file.
---@param catalog_ud any
---@param path any
function lurek.docs.exportHover(catalog_ud, path) end

--- Export a Markdown API reference file.
---@param catalog_ud any
---@param path any
function lurek.docs.exportMarkdown(catalog_ud, path) end

--- Export VS Code signature-help JSON to a file.
---@param catalog_ud any
---@param path any
function lurek.docs.exportSignatures(catalog_ud, path) end

--- Return the current internal catalog as an ApiCatalog userdata.
function lurek.docs.getCatalog() end

--- Load all .toml files in a directory and merge into a single ApiCatalog.
---@param directory any
---@return ApiCatalog
function lurek.docs.loadAll(directory) end

--- Load a TOML doc file into an ApiCatalog.
---@param path any
---@return ApiCatalog
function lurek.docs.loadToml(path) end

--- Calculate quality metrics for a catalog or the internal catalog.
---@param catalog_ud? any (optional)
---@return table
function lurek.docs.quality(catalog_ud) end

--- Calculate quality metrics for a single module.
---@param module_name any
---@param catalog_ud? any (optional)
---@return table
function lurek.docs.qualityModule(module_name, catalog_ud) end

--- Walks the live lurek.* Lua table and returns a structured reflection of all
---@param ns? any (optional)
---@return table
function lurek.docs.reflectLive(ns) end

--- Reflects any Lua table, returning a structure describing its keys,
---@param tbl any
---@param name? any (optional)
---@return table
function lurek.docs.reflectTable(tbl, name) end

--- Clear all entries from the internal catalog.
function lurek.docs.resetCatalog() end

--- Scan the lurek.* namespace to build an API catalog from live bindings.
---@param opts? any (optional)
---@return ApiCatalog
function lurek.docs.scan(opts) end

--- Scan a single module's bindings.
---@param module_name any
---@return ApiCatalog
function lurek.docs.scanModule(module_name) end

--- Creates a Schema validator from a rules table.
---@param rules any
---@param name? any (optional)
---@return userdata
function lurek.docs.schema(rules, name) end

--- Set the parameter metadata for a catalog entry.
---@param qualified_name any
---@param params any
function lurek.docs.setParamInfo(qualified_name, params) end

--- Set the return type metadata for a catalog entry.
---@param qualified_name any
---@param returns any
function lurek.docs.setReturnInfo(qualified_name, returns) end

--- Validate catalog completeness against the live lurek.* bindings.
---@param catalog_ud? any (optional)
---@return ValidationReport
function lurek.docs.validate(catalog_ud) end

--- Validate a single module against the live lurek.<module>.* bindings.
---@param module_name any
---@param catalog_ud? any (optional)
---@return ValidationReport
function lurek.docs.validateModule(module_name, catalog_ud) end

---@class lurek.ecs
lurek.ecs = {}

--- Lua-side wrapper around a [`Universe`] ECS world.
---@class Universe
local Universe = {}

--- Attaches a string tag to an entity.
---@param id any
---@param tag any
---@return nil
function Universe:addTag(id, tag) end

--- Adds a bitmap tag to an entity.
---@param id any
---@param name any
---@return nil
function Universe:bitmapTag(id, name) end

--- Removes a bitmap tag from an entity.
---@param id any
---@param name any
---@return nil
function Universe:bitmapUntag(id, name) end

--- Removes all entities, components, tags, layers, and systems. Blueprints are preserved.
---@return nil
function Universe:clear() end

--- Removes all directed named relationships of type `name` from entity `from`.
---@param from any
---@param name any
---@return nil
function Universe:clearRelations(from, name) end

--- Defines a bitmap tag name, returning its bit index.
---@param name any
---@return integer
function Universe:defineTag(name) end

--- Restores entity state from a snapshot produced by serialize().
---@param snapshot any
---@return nil
function Universe:deserialize(snapshot) end

--- Emits a named event to all systems that implement the handler, in priority order.
---@param args any
---@return nil
function Universe:emit(args) end

--- Dispatches all pending component-add and component-remove events to registered callbacks.
---@return nil
function Universe:flushObservers() end

--- Returns the component value for an entity, or nil if missing.
---@param id any
---@param name any
---@return table
function Universe:get(id, name) end

--- Returns the bit index for a bitmap tag name, or nil if undefined.
---@param name any
---@return integer?
function Universe:getBitmapTagBit(name) end

--- Returns a deep copy of a blueprint's component table, or nil.
---@param name any
---@return table
function Universe:getBlueprintComponents(name) end

--- Returns all direct child entity IDs.
---@param parent_id any
---@return table
function Universe:getChildren(parent_id) end

--- Returns all component names for an entity.
---@param id any
---@return table
function Universe:getComponents(id) end

--- Returns all alive entity IDs.
---@return table
function Universe:getEntities() end

--- Returns all alive entities on a specific layer.
---@param layer any
---@return table
function Universe:getEntitiesByLayer(layer) end

--- Returns all alive entities with the given string tag.
---@param tag any
---@return table
function Universe:getEntitiesByTag(tag) end

--- Returns all alive entities sorted by layer then ID.
---@return table
function Universe:getEntitiesSorted() end

--- Returns the number of alive entities.
---@return integer
function Universe:getEntityCount() end

--- Returns the layer for an entity, defaulting to zero.
---@param id any
---@return integer
function Universe:getLayer(id) end

--- Returns the parent entity ID, or nil if unparented.
---@param child_id any
---@return integer?
function Universe:getParent(child_id) end

--- Returns all entity IDs reachable from `from` via the named relationship.
---@param from any
---@param name any
---@return table
function Universe:getRelated(from, name) end

--- Returns the number of registered systems.
---@return integer
function Universe:getSystemCount() end

--- Returns all string tags for an entity.
---@param id any
---@return table
function Universe:getTags(id) end

--- Returns true if the entity has the named component.
---@param id any
---@param name any
---@return boolean
function Universe:has(id, name) end

--- Returns true if the entity has the given bitmap tag.
---@param id any
---@param name any
---@return boolean
function Universe:hasBitmapTag(id, name) end

--- Returns true if a blueprint with the given name exists.
---@param name any
---@return boolean
function Universe:hasBlueprint(name) end

--- Returns true if the entity carries the given tag.
---@param id any
---@param tag any
---@return boolean
function Universe:hasTag(id, tag) end

--- Returns true if the entity ID is currently alive.
---@param id any
---@return boolean
function Universe:isAlive(id) end

--- Destroys the entity with the given ID, freeing its slot for reuse.
---@param id any
---@return nil
function Universe:kill(id) end

--- Kills an entity and all its descendants recursively.
---@param id any
---@return nil
function Universe:killRecursive(id) end

--- Returns all defined blueprint names.
---@return table
function Universe:listBlueprints() end

--- Returns entity IDs that have all listed component names.
---@param args any
---@return table
function Universe:query(args) end

--- Returns all alive entities with all of the listed bitmap tags.
---@param names any
---@return table
function Universe:queryBitmapAll(names) end

--- Returns all alive entities with any of the listed bitmap tags.
---@param names any
---@return table
function Universe:queryBitmapAny(names) end

--- Returns all alive entities with the given bitmap tag.
---@param name any
---@return table
function Universe:queryBitmapTag(name) end

--- Releases all universe state, equivalent to clear.
---@return nil
function Universe:release() end

--- Removes a component from an entity.
---@param id any
---@param name any
---@return nil
function Universe:remove(id, name) end

--- Removes a blueprint definition.
---@param name any
---@return nil
function Universe:removeBlueprint(name) end

--- Removes a system table from the universe.
---@param system any
---@return nil
function Universe:removeSystem(system) end

--- Removes a string tag from an entity.
---@param id any
---@param tag any
---@return nil
function Universe:removeTag(id, tag) end

--- Calls render(system, world) on each registered system in priority order.
---@return nil
function Universe:render() end

--- Serializes all alive entities to a Lua table snapshot.
---@return table
function Universe:serialize() end

--- Sets the layer for an entity.
---@param id any
---@param layer any
---@return nil
function Universe:setLayer(id, layer) end

--- Creates a new entity and returns its packed ID.
---@return integer
function Universe:spawn() end

--- Calls update(system, world, dt) on each registered system in priority order.
---@param dt any
---@return nil
function Universe:update(dt) end

--- Creates a new empty ECS universe.
---@return Universe
function lurek.ecs.newUniverse() end

---@class lurek.effect
lurek.effect = {}

--- Lua-side wrapper around [`ImageEffect`].
---@class ImageEffect
local ImageEffect = {}

--- Creates a new effect by type name, appends it, and returns the shared PostFxEffect.
---@param name any
---@return PostFxEffect
function ImageEffect:addEffect(name) end

--- Removes all effects from the chain (alias for clearEffects).
---@return nil
function ImageEffect:clear() end

--- Removes all effects from the chain.
---@return nil
function ImageEffect:clearEffects() end

--- Returns a deep copy of this ImageEffect chain.
---@return ImageEffect
function ImageEffect:clone() end

--- Returns the number of effects in the chain.
---@return integer
function ImageEffect:effectCount() end

--- Returns the effect at the given 1-based index or with the given type name.
---@param key any
---@return nil
function ImageEffect:getEffect(key) end

--- Returns the number of effects in the chain (alias for effectCount).
---@return integer
function ImageEffect:getEffectCount() end

--- Removes the effect at the given 0-based index from the chain.
---@param idx any
---@return boolean
function ImageEffect:removeByIndex(idx) end

--- Removes the first effect matching the given type name.
---@param name any
---@return boolean
function ImageEffect:removeByName(name) end

--- Removes the effect at the given 1-based index or with the given type name.
---@param key any
---@return boolean
function ImageEffect:removeEffect(key) end

--- Stub: no-op serialisation placeholder.
---@return boolean
function ImageEffect:save() end

--- Returns the type name "ImageEffect".
---@return string
function ImageEffect:type() end

--- Returns true when the given name matches "ImageEffect" or a parent type.
---@param name any
---@return boolean
function ImageEffect:typeOf(name) end

--- Lua-side wrapper around [`Overlay`].
---@class Overlay
local Overlay = {}

--- Resets all effect subsystems to their default inactive state.
---@return nil
function Overlay:clear() end

--- Renders the effect state (flash, fade, effects) to a CPU ImageData.
---@param w any
---@param h any
---@return ImageData
function Overlay:drawToImage(w, h) end

--- Returns the current ambient tint as r, g, b, a components.
---@return number
function Overlay:getAmbientColor() end

--- Returns the current cloud shadow instance count.
---@return integer
function Overlay:getCloudCount() end

--- Returns the current cloud shadow opacity.
---@return number
function Overlay:getCloudOpacity() end

--- Returns the current cloud shadow scale.
---@return number
function Overlay:getCloudScale() end

--- Returns the current cloud shadow scroll speed.
---@return number
function Overlay:getCloudSpeed() end

--- Returns the effect width and height.
---@return integer
function Overlay:getDimensions() end

--- Returns the current film-grain intensity.
---@return number
function Overlay:getFilmGrainIntensity() end

--- Returns the current flash overlay alpha value.
---@return number
function Overlay:getFlashAlpha() end

--- Returns the current fog tint as r, g, b, a components.
---@return number
function Overlay:getFogColor() end

--- Returns the current fog density.
---@return number
function Overlay:getFogDensity() end

--- Returns the current heat-haze distortion intensity.
---@return number
function Overlay:getHeatHazeIntensity() end

--- Returns the effect height.
---@return integer
function Overlay:getHeight() end

--- Returns the current lightning overlay alpha value.
---@return number
function Overlay:getLightningAlpha() end

--- Returns the lightning flash tint as r, g, b, a components.
---@return number
function Overlay:getLightningColor() end

--- Returns the current shake displacement as x, y.
---@return number
function Overlay:getShakeOffset() end

--- Returns the current simulated time-of-day (0â€“24).
---@return number
function Overlay:getTimeOfDay() end

--- Returns the current vignette strength.
---@return number
function Overlay:getVignetteStrength() end

--- Returns a table describing the current water overlay state.
---@return table
function Overlay:getWater() end

--- Returns the name of the current weather type.
---@return string
function Overlay:getWeather() end

--- Returns the current weather intensity.
---@return number
function Overlay:getWeatherIntensity() end

--- Returns the effect width.
---@return integer
function Overlay:getWidth() end

--- Returns the current wind direction in radians.
---@return number
function Overlay:getWindDirection() end

--- Returns the current wind speed.
---@return number
function Overlay:getWindSpeed() end

--- Returns true if any effect subsystem is currently active.
---@return boolean
function Overlay:isActive() end

--- Returns whether the ambient light layer is active.
---@return boolean
function Overlay:isAmbientEnabled() end

--- Returns whether cloud shadows are active.
---@return boolean
function Overlay:isCloudShadowsEnabled() end

--- Returns true while a fade effect is in progress.
---@return boolean
function Overlay:isFading() end

--- Returns whether the film-grain layer is active.
---@return boolean
function Overlay:isFilmGrainEnabled() end

--- Returns true while a flash effect is in progress.
---@return boolean
function Overlay:isFlashing() end

--- Returns whether the fog layer is active.
---@return boolean
function Overlay:isFogEnabled() end

--- Returns whether the heat-haze layer is active.
---@return boolean
function Overlay:isHeatHazeEnabled() end

--- Returns true while a shake effect is in progress.
---@return boolean
function Overlay:isShaking() end

--- Returns whether the vignette layer is active.
---@return boolean
function Overlay:isVignetteEnabled() end

--- Returns whether the weather particle system is active.
---@return boolean
function Overlay:isWeatherEnabled() end

--- Emits GPU render commands for all active overlay effects (flash, fade, lightning, vignette).
---@return nil
function Overlay:render() end

--- Resizes the effect to match new window dimensions.
---@param w any
---@param h any
---@return nil
function Overlay:resize(w, h) end

--- Enables or disables the ambient light layer.
---@param v any
---@return nil
function Overlay:setAmbientEnabled(v) end

--- Sets the number of cloud shadow instances to render.
---@param v any
---@return nil
function Overlay:setCloudCount(v) end

--- Sets the opacity of cloud shadows (0.0 = invisible, 1.0 = fully dark).
---@param v any
---@return nil
function Overlay:setCloudOpacity(v) end

--- Sets the scale multiplier applied to each cloud shadow.
---@param v any
---@return nil
function Overlay:setCloudScale(v) end

--- Enables or disables scrolling cloud-shadow projection.
---@param v any
---@return nil
function Overlay:setCloudShadows(v) end

--- Sets the horizontal scroll speed of cloud shadows in pixels per second.
---@param v any
---@return nil
function Overlay:setCloudSpeed(v) end

--- Assigns a custom shader name to the effect, or clears it when `nil` is passed.
---@param name? any (optional)
---@return nil
function Overlay:setCustomShader(name) end

--- Enables or disables the film-grain noise layer.
---@param v any
---@return nil
function Overlay:setFilmGrainEnabled(v) end

--- Sets the film-grain noise intensity (0.0â€“1.0).
---@param v any
---@return nil
function Overlay:setFilmGrainIntensity(v) end

--- Sets the fog density (0.0 = clear, 1.0 = fully opaque).
---@param v any
---@return nil
function Overlay:setFogDensity(v) end

--- Enables or disables the fog layer.
---@param v any
---@return nil
function Overlay:setFogEnabled(v) end

--- Enables or disables the heat-haze distortion layer.
---@param v any
---@return nil
function Overlay:setHeatHazeEnabled(v) end

--- Sets the heat-haze distortion intensity (0.0â€“1.0).
---@param v any
---@return nil
function Overlay:setHeatHazeIntensity(v) end

--- Sets the simulated time-of-day (0â€“24) which drives ambient colour.
---@param v any
---@return nil
function Overlay:setTimeOfDay(v) end

--- Enables or disables the screen-edge vignette layer.
---@param v any
---@return nil
function Overlay:setVignetteEnabled(v) end

--- Sets the vignette darkening strength (0.0â€“1.0).
---@param v any
---@return nil
function Overlay:setVignetteStrength(v) end

--- Sets the active weather type by name ("none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen").
---@param name any
---@return nil
function Overlay:setWeather(name) end

--- Enables or disables the weather particle system.
---@param v any
---@return nil
function Overlay:setWeatherEnabled(v) end

--- Sets the particle spawn rate multiplier (0.0â€“1.0).
---@param v any
---@return nil
function Overlay:setWeatherIntensity(v) end

--- Sets the wind direction in radians (0 = right, Ď€/2 = down).
---@param v any
---@return nil
function Overlay:setWindDirection(v) end

--- Sets the wind speed applied to weather particles in units per second.
---@param v any
---@return nil
function Overlay:setWindSpeed(v) end

--- Triggers a camera shake; duration defaults to 0.5 s.
---@param intensity any
---@param dur? any (optional)
---@return nil
function Overlay:shake(intensity, dur) end

--- Triggers a lightning flash effect.
---@return nil
function Overlay:triggerLightning() end

--- Returns the type name of this object ("Overlay").
---@return string
function Overlay:type() end

--- Returns true if this object is of the given type ("Object" or "Overlay").
---@param name any
---@return boolean
function Overlay:typeOf(name) end

--- Advances all effect subsystems by the given delta time.
---@param dt any
---@return nil
function Overlay:update(dt) end

--- Lua-side wrapper around [`PostFxEffect`].
---@class PostFxEffect
local PostFxEffect = {}

--- Disables auto-injection of common uniforms into shader slot p[3].
---@return nil
function PostFxEffect:disableAutoUniforms() end

--- Enables auto-injection of common uniforms into shader slot p[3] each frame.
---@return nil
function PostFxEffect:enableAutoUniforms() end

--- Returns the type name of this effect (alias for getTypeName).
---@return string
function PostFxEffect:getEffectType() end

--- Returns a list of all parameter names on this effect.
---@return table
function PostFxEffect:getParameterNames() end

--- Returns the type name of this effect (alias for getTypeName).
---@return string
function PostFxEffect:getType() end

--- Returns the display name of this effect type.
---@return string
function PostFxEffect:getTypeName() end

--- Returns true if the named parameter exists on this effect.
---@param name any
---@return boolean
function PostFxEffect:hasParameter(name) end

--- Returns whether auto-uniform injection is enabled for this effect.
---@return boolean
function PostFxEffect:isAutoUniforms() end

--- Returns true if this is a built-in effect, false if custom.
---@return boolean
function PostFxEffect:isBuiltIn() end

--- Returns whether this effect is currently active.
---@return boolean
function PostFxEffect:isEnabled() end

--- Sets the brightness parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setBrightness(v) end

--- Sets the contrast parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setContrast(v) end

--- Enables or disables this effect.
---@param enabled any
---@return nil
function PostFxEffect:setEnabled(enabled) end

--- Sets the intensity parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setIntensity(v) end

--- Sets the offset parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setOffset(v) end

--- Sets a named float parameter on this effect.
---@param name any
---@param value any
---@return nil
function PostFxEffect:setParameter(name, value) end

--- Sets the radius parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setRadius(v) end

--- Sets the saturation parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setSaturation(v) end

--- Sets the scanline strength parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setScanlineStrength(v) end

--- Sets the strength parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setStrength(v) end

--- Sets the threshold parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setThreshold(v) end

--- Returns the type name "PostFxEffect".
---@return string
function PostFxEffect:type() end

--- Returns true when the given name matches "PostFxEffect" or a parent type.
---@param name any
---@return boolean
function PostFxEffect:typeOf(name) end

--- Lua-side wrapper around [`PostFxStack`].
---@class PostFxStack
local PostFxStack = {}

--- Appends a PostFxEffect to the end of the pipeline.
---@param effect_ud any
---@return nil
function PostFxStack:add(effect_ud) end

--- Applies all enabled effects in the stack and composites the result to screen.
---@return nil
function PostFxStack:apply() end

--- Begins capturing the scene for post-processing.
---@return nil
function PostFxStack:beginCapture() end

--- Removes all effects from the pipeline.
---@return nil
function PostFxStack:clear() end

--- Resets the feedback intensity to `0.0` (disables feedback).
---@return nil
function PostFxStack:clearFeedback() end

--- Removes duplicate effects from the pipeline, keeping the first occurrence
---@return nil
function PostFxStack:dedup() end

--- Ends scene capture for post-processing.
---@return nil
function PostFxStack:endCapture() end

--- Returns width and height of the render target.
---@return integer
function PostFxStack:getDimensions() end

--- Returns the effect at the given 1-based position, or nil.
---@param index any
---@return nil
function PostFxStack:getEffect(index) end

--- Returns the number of effects in the pipeline.
---@return integer
function PostFxStack:getEffectCount() end

--- Returns a list of currently enabled effect objects.
---@return table
function PostFxStack:getEnabledEffects() end

--- Returns the current feedback loop intensity `[0.0, 1.0]`.
---@return number
function PostFxStack:getFeedback() end

--- Returns the height of the render target.
---@return integer
function PostFxStack:getHeight() end

--- Returns the width of the render target.
---@return integer
function PostFxStack:getWidth() end

--- Returns whether the stack is currently capturing the scene.
---@return boolean
function PostFxStack:isCapturing() end

--- Returns true if the pipeline has no effect slots.
---@return boolean
function PostFxStack:isEmpty() end

--- Returns whether the effect at the given 1-based position is enabled.
---@param position any
---@return boolean
function PostFxStack:isEnabled(position) end

--- Returns the total number of effect slots in the pipeline.
---@return integer
function PostFxStack:len() end

--- Removes the given PostFxEffect from the pipeline.
---@param effect_ud any
---@return boolean
function PostFxStack:remove(effect_ud) end

--- Resizes the render target to the given dimensions.
---@param w any
---@param h any
---@return nil
function PostFxStack:resize(w, h) end

--- Sets the feedback loop intensity. At `0.0` (default) there is no
---@param factor any
---@return nil
function PostFxStack:setFeedback(factor) end

--- Returns the type name "PostFxStack".
---@return string
function PostFxStack:type() end

--- Returns true when the given name matches "PostFxStack" or a parent type.
---@param name any
---@return boolean
function PostFxStack:typeOf(name) end

---@class mlua
local mlua = {}

--- Returns the fill color as four numbers: `r, g, b, a`.
---@return number
function mlua:color() end

--- Returns `true` while the transition is running.
---@return boolean
function mlua:isActive() end

--- Returns `true` after the transition has completed.
---@return boolean
function mlua:isDone() end

--- Returns the transition kind name (`"fade"`, `"wipe"`, `"iris_wipe"`,
---@return string
function mlua:kind() end

--- Starts the transition playing forward (scene fades/wipes out).
---@return nil
function mlua:play() end

--- Returns the fractional progress `[0, 1]` of the transition, taking
---@return number
function mlua:progress() end

--- Starts the transition in reverse (scene fades/wipes in).
---@return nil
function mlua:reverse() end

--- Updates the fill color from `{r, g, b, a?}`.
---@param color table
---@return nil
function mlua:setColor(color) end

--- Type.
---@return table|nil
function mlua:type() end

--- Type of.
---@param name any
---@return table|nil
function mlua:typeOf(name) end

--- Advances the transition by `dt` seconds. Returns `true` while
---@param dt any
---@return boolean
function mlua:update(dt) end

--- Returns the list of all built-in effect type names.
---@return table
function lurek.effect.getEffectTypes() end

--- Returns whether shader error display is currently enabled.
---@return boolean
function lurek.effect.getShaderErrorDisplay() end

--- Creates a custom shader post-processing effect.
---@param shader_id any
---@return PostFxEffect
function lurek.effect.newCustomEffect(shader_id) end

--- Creates a new built-in post-processing effect by type name.
---@param type_name any
---@return PostFxEffect
function lurek.effect.newEffect(type_name) end

--- Creates a new per-image effect chain. Accepts:
---@param args any
---@return ImageEffect
function lurek.effect.newImageEffect(args) end

--- Creates a new screen overlay controller for weather, flash, shake, and fade effects.
---@param w? any (optional)
---@param h? any (optional)
---@return Overlay
function lurek.effect.newOverlay(w, h) end

--- Creates a custom-shader post-processing effect (alias for newCustomEffect).
---@param shader_id any
---@return PostFxEffect
function lurek.effect.newPass(shader_id) end

--- Creates a pre-configured effect stack from a named preset.
---@param name any
---@param w? any (optional)
---@param h? any (optional)
---@return PostFxStack
function lurek.effect.newPresetStack(name, w, h) end

--- Creates a new post-processing pipeline stack.
---@param w? any (optional)
---@param h? any (optional)
---@return PostFxStack
function lurek.effect.newStack(w, h) end

--- Creates a new screen-transition controller. `kind` is one of:
---@param kind? any (optional)
---@param duration? any (optional)
---@param color_tbl? any (optional)
---@return ScreenTransition
function lurek.effect.newTransition(kind, duration, color_tbl) end

--- Enables or disables the effect that renders shader compile errors as red text
---@param enabled any
---@return nil
function lurek.effect.setShaderErrorDisplay(enabled) end

---@class lurek.engine
lurek.engine = {}

--- Returns the current measured frames-per-second.
---@return number
function lurek.engine.fps() end

--- Returns the total number of frames processed since engine start.
---@return integer
function lurek.engine.frameCount() end

--- Returns the target frame budget in milliseconds (default: 1000 / 60 â‰ 16.667 ms).
---@return number
function lurek.engine.getFrameBudget() end

--- Returns a table with resident resource memory statistics.
---@return table
function lurek.engine.getResourceStats() end

--- Returns the engine version string (from `Cargo.toml`).
---@return string
function lurek.engine.getVersion() end

--- Returns `true` if the engine was compiled in debug mode.
---@return boolean
function lurek.engine.isDebug() end

--- Returns a table with `lua_bytes` (Lua GC heap usage in bytes) and
---@return table
function lurek.engine.memoryUsage() end

--- Returns a string identifying the host operating system:
---@return string
function lurek.engine.platform() end

--- Sets the maximum resident texture memory budget in bytes.
---@param budget_bytes any
function lurek.engine.setResourceBudget(budget_bytes) end

--- Returns the total engine uptime in seconds (sum of all processed deltas).
---@return number
function lurek.engine.uptime() end

---@class lurek.signal
lurek.signal = {}

--- Lua-side wrapper around a [`Signal`] with registry-stored callbacks.
---@class Signal
local Signal = {}

--- Removes all callbacks for the named event.
---@param name any
---@return integer
function Signal:clear(name) end

--- Removes all callbacks across all events.
---@return integer
function Signal:clearAll() end

--- Emits the named event, calling all registered callbacks with extra arguments.
---@param args any
---@return nil
function Signal:emit(args) end

--- Returns the callback count for the named event.
---@param name any
---@return integer
function Signal:getCount(name) end

--- Returns the total callback count across all events.
---@return integer
function Signal:getTotalCount() end

--- Removes a subscription by handle ID.
---@param handle any
---@return boolean
function Signal:remove(handle) end

--- Returns the type name of this object.
---@return string
function Signal:type() end

--- Returns true if the given type name matches this object's type or any parent type.
---@param name any
---@return boolean
function Signal:typeOf(name) end

--- Discards all pending events in the queue.
---@return nil
function lurek.signal.clear() end

--- Clears all recorded event history.
---@return nil
function lurek.signal.clearHistory() end

--- Enables event history recording, keeping the last `capacity` pushed events.
---@param capacity any
---@return nil
function lurek.signal.enableHistory(capacity) end

--- Pushes an exit event, requesting the engine to stop.
---@param code? any (optional)
---@return nil
function lurek.signal.exit(code) end

--- Moves all buffered deferred events into the main event queue and clears the buffer.
---@return table|nil
function lurek.signal.flushDeferred() end

--- Returns an array of recent events as `{name, args}` tables.
---@return table
function lurek.signal.getHistory() end

--- Creates a new pub-sub Signal dispatcher.
---@return Signal
function lurek.signal.newSignal() end

--- Returns an iterator function that pops events from the queue.
---@return function
function lurek.signal.poll() end

--- Syncs OS-level events into the queue (no-op in Lurek2D push model).
---@return nil
function lurek.signal.pump() end

--- Adds an event item to the end of the event queue for processing.
---@param args any
function lurek.signal.push(args) end

--- Pushes a named event to the deferred buffer; it will not reach the main queue
---@param args any
---@return nil
function lurek.signal.pushDeferred(args) end

--- Alias for `exit()` â€” requests the engine to stop at the end of the current frame.
---@return nil
function lurek.signal.quit() end

--- Requests that the engine restart at the beginning of the next frame.
---@return nil
function lurek.signal.restart() end

--- Blocks until the next event arrives or the optional timeout elapses.
---@param timeout? any (optional)
---@return string?
function lurek.signal.wait(timeout) end

---@class lurek.filesystem
lurek.filesystem = {}

--- Lua-side wrapper around a [`FileData`] buffer.
---@class FileData
local FileData = {}

--- Returns the virtual path this data was loaded from.
---@return string
function FileData:getFilename() end

--- Returns the file size in bytes.
---@return integer
function FileData:getSize() end

--- Returns the file content as a Lua string.
---@return string
function FileData:getString() end

--- Lua-side wrapper around a [`FileHandle`] with interior mutability.
---@class FileHandle
local FileHandle = {}

--- Flushes any pending writes and closes the file handle.
---@return nil
function FileHandle:close() end

--- Flushes all buffered writes to disk without closing the handle.
---@return nil
function FileHandle:flush() end

--- Returns the access mode the file was opened with.
---@return string
function FileHandle:getMode() end

--- Returns the size of the open file in bytes.
---@return integer
function FileHandle:getSize() end

--- Returns whether the read cursor has reached the end of the file.
---@return boolean
function FileHandle:isEOF() end

--- Reads bytes from the file, returning them as a string.
---@param count? any (optional)
---@return string
function FileHandle:read(count) end

--- Reads the next line from the file without the trailing newline.
---@return string?
function FileHandle:readLine() end

--- Seeks the file position to the given byte offset from the start.
---@param pos any
---@return integer
function FileHandle:seek(pos) end

--- Returns the current read/write byte offset from the start of the file.
---@return integer
function FileHandle:tell() end

--- Writes a string to the file and returns the number of bytes written.
---@param data any
---@return integer
function FileHandle:write(data) end

--- Lua userdata wrapper around a [`ZipMount`].
---@class ZipMount
local ZipMount = {}

--- Returns true if `virtual_path` exists inside this ZIP mount.
---@param virtual_path any
---@return boolean
function ZipMount:contains(virtual_path) end

--- Returns a sorted array of all virtual paths exposed by this ZIP mount.
---@return table
function ZipMount:listFiles() end

--- Returns the virtual path prefix this archive was mounted under.
---@return string
function ZipMount:prefix() end

--- Reads a file from the ZIP and returns it as a string of bytes.
---@param virtual_path any
---@return string
function ZipMount:readFile(virtual_path) end

--- Opens the file in append mode and writes the given string at the end.
---@param path any
---@param data any
---@return nil
function lurek.filesystem.append(path, data) end

--- Copies a file within the sandbox.
---@param src any
---@param dst any
---@return nil
function lurek.filesystem.copy(src, dst) end

--- Creates a directory and any missing parent directories in the save area.
---@param path any
---@return nil
function lurek.filesystem.createDirectory(path) end

--- Creates an empty temporary file in the `save/` sandbox and returns its
---@param prefix? any (optional)
---@return string
function lurek.filesystem.createTempFile(prefix) end

--- Returns whether the given file or directory exists.
---@param path any
---@return boolean
function lurek.filesystem.exists(path) end

--- Returns a table containing the names of every file and subdirectory in the given path.
---@param path any
---@return table
function lurek.filesystem.getDirectoryItems(path) end

--- Returns the identity string used to locate the game's save directory.
---@return string
function lurek.filesystem.getIdentity() end

--- Returns a table of metadata for a path, or nil if the path does not exist.
---@param path any
---@return table?
function lurek.filesystem.getInfo(path) end

--- Returns the sandboxed save data directory path.
---@return string
function lurek.filesystem.getSaveDirectory() end

--- Returns the absolute path of the directory the game was loaded from.
---@return string
function lurek.filesystem.getSource() end

--- Returns the current user's home directory path.
---@return string
function lurek.filesystem.getUserDirectory() end

--- Returns the current working directory path.
---@return string
function lurek.filesystem.getWorkingDirectory() end

--- Returns a sorted list of paths matching a simple wildcard pattern.
---@param pattern any
---@return table
function lurek.filesystem.glob(pattern) end

--- Returns whether the given path is a directory.
---@param path any
---@return boolean
function lurek.filesystem.isDirectory(path) end

--- Returns whether the given path is a regular file.
---@param path any
---@return boolean
function lurek.filesystem.isFile(path) end

--- Returns an iterator function over the lines of a text file.
---@param path any
---@return function
function lurek.filesystem.lines(path) end

--- Returns a sorted list of all files under `path`, recursively.
---@param path any
---@return table
function lurek.filesystem.listRecursive(path) end

--- Loads and compiles a Lua file from the VFS, returning it as a callable function.
---@param path any
---@return function
function lurek.filesystem.load(path) end

--- Creates a directory (and any missing parents) relative to the game root.
---@param path any
---@return nil
function lurek.filesystem.mkdir(path) end

--- Mounts a directory at a virtual path inside the game filesystem.
---@param src any
---@param mp any
---@return boolean
function lurek.filesystem.mount(src, mp) end

--- Mounts a ZIP archive at a virtual path prefix, making its contents readable
---@param archive_path any
---@param prefix any
---@return ZipMount
function lurek.filesystem.mountZip(archive_path, prefix) end

--- Moves (renames) a file within the `save/` directory.
---@param src any
---@param dst any
---@return nil
function lurek.filesystem.move(src, dst) end

--- Loads a file from the VFS into a FileData buffer.
---@param path any
---@return FileData
function lurek.filesystem.newFileData(path) end

--- Opens a file and returns a readable/writable file handle.
---@param path any
---@param mode any
---@return FileHandle
function lurek.filesystem.openFile(path, mode) end

--- Polls an async load handle, returning status and optional data.
---@param handle_id any
---@return string|nil
function lurek.filesystem.pollAsync(handle_id) end

--- Polls all watched paths and returns an array of paths that changed since the
---@return table
function lurek.filesystem.pollWatchers() end

--- Reads a text file and returns its contents as a string.
---@param path any
---@return string
function lurek.filesystem.read(path) end

--- Starts loading a file in the background and returns an opaque handle.
---@param path any
---@return integer
function lurek.filesystem.readAsync(path) end

--- Permanently deletes a file or empty directory from the save directory.
---@param path any
---@return nil
function lurek.filesystem.remove(path) end

--- Recursively deletes a directory and all its contents within `save/`.
---@param path any
---@return nil
function lurek.filesystem.removeDir(path) end

--- Sets the identity string that names the game's sandboxed save-data directory.
---@param name any
---@return nil
function lurek.filesystem.setIdentity(name) end

--- Returns lightweight file statistics for the given path.
---@param path any
---@return table
function lurek.filesystem.stat(path) end

--- Resolves a path relative to the game root to an absolute OS path string.
---@param path any
---@return string
function lurek.filesystem.toAbsolutePath(path) end

--- Removes a virtual mount layer by mountpoint.
---@param mp any
---@return boolean
function lurek.filesystem.unmount(mp) end

--- Removes `path` from the polled file-watch list.  No-op if not watched.
---@param path any
---@return nil
function lurek.filesystem.unwatchPath(path) end

--- Adds `path` to the polled file-watch list.
---@param path any
---@return nil
function lurek.filesystem.watchPath(path) end

--- Writes a string to a file in the save directory.
---@param path any
---@param data any
---@return nil
function lurek.filesystem.write(path, data) end

---@class lurek.globe
lurek.globe = {}

--- Lua-accessible handle to a `Globe` inside a `GlobeRegistry`.
---@class Globe
local Globe = {}

--- Adds a province from a table {id, centroid={lat,lon}, vertices={{lat,lon},...},
---@param p any
---@return boolean
function Globe:addProvince(p) end

--- Find the shortest province path from `from_id` to `to_id`.
---@param from_id any
---@param to_id any
---@return table<integer>?
function Globe:findPath(from_id, to_id) end

--- Get the current camera (lat, lon, zoom).
---@return number
function Globe:getCamera() end

--- Returns the current LOD tier as a string: "far", "mid", or "near".
---@return string
function Globe:getLod() end

--- Get a string attribute from a marker.
---@param id any
---@param key any
---@return string?
function Globe:getMarkerAttr(id, key) end

--- Returns the string identifier name assigned to this globe instance.
---@return string
function Globe:getName() end

--- Returns the neighbor IDs of a province.
---@param id any
---@return table<integer>
function Globe:getNeighbors(id) end

--- Gets a string attribute from a province.
---@param id any
---@param key any
---@return string?
function Globe:getProvinceAttr(id, key) end

--- Gets the current simulated time of day for daylight computation.
---@return number
function Globe:getTimeOfDay() end

--- Hide a province for a viewer.
---@param viewer any
---@param id any
function Globe:hideProvince(viewer, id) end

--- Returns true if the province is visible to the viewer.
---@param viewer any
---@param id any
---@return boolean
function Globe:isVisible(viewer, id) end

--- Move a marker to a new lat/lon.
---@param id any
---@param lat any
---@param lon any
function Globe:moveMarker(id, lat, lon) end

--- Pan the orbit camera by delta-latitude and delta-longitude (degrees).
---@param dlat any
---@param dlon any
function Globe:pan(dlat, dlon) end

--- Returns the province ID under screen coordinates, or nil.
---@param sx any
---@param sy any
---@return integer?
function Globe:pick(sx, sy) end

--- Returns (lat, lon) of the screen point on the globe surface, or nil.
---@param sx any
---@param sy any
---@return number?
function Globe:pickLatLon(sx, sy) end

--- Returns the number of provinces.
---@return integer
function Globe:provinceCount() end

--- Removes an arc from the globe map by its unique string identifier.
---@param id any
function Globe:removeArc(id) end

--- Removes a text label from the globe map by its unique string identifier.
---@param id any
function Globe:removeLabel(id) end

--- Removes a texture layer from the globe map by its unique string identifier.
---@param name any
function Globe:removeLayer(name) end

--- Removes a marker from the globe map by its unique string identifier.
---@param id any
---@return boolean
function Globe:removeMarker(id) end

--- Removes a province by ID. Returns true if it existed.
---@param id any
---@return boolean
function Globe:removeProvince(id) end

--- Reveal all provinces for a viewer.
---@param viewer any
function Globe:revealAll(viewer) end

--- Reveal a province for a viewer.
---@param viewer any
---@param id any
function Globe:revealProvince(viewer, id) end

--- Set the faction/viewer whose fog mask filters rendering.
---@param viewer? any (optional)
function Globe:setActiveViewer(viewer) end

--- Enable or disable province border rendering.
---@param show any
function Globe:setBorders(show) end

--- Set the camera position directly.
---@param lat any
---@param lon any
---@param z any
function Globe:setCamera(lat, lon, z) end

--- Updates the visible text content of an existing globe label.
---@param id any
---@param text any
function Globe:setLabelText(id, text) end

--- Sets whether this specific label is visible on the globe.
---@param id any
---@param vis any
function Globe:setLabelVisible(id, vis) end

--- Set layer opacity (0.0–1.0).
---@param name any
---@param alpha any
function Globe:setLayerAlpha(name, alpha) end

--- Sets whether this specific texture layer is visible on the globe.
---@param name any
---@param vis any
function Globe:setLayerVisible(name, vis) end

--- Sets whether this specific marker is visible on the globe.
---@param id any
---@param vis any
function Globe:setMarkerVisible(id, vis) end

--- Set planet rotation (degrees).
---@param deg any
function Globe:setRotation(deg) end

--- Set time of day (0.0–24.0 hours).
---@param t any
function Globe:setTimeOfDay(t) end

--- Advance globe simulation by dt seconds.
---@param dt any
function Globe:update(dt) end

--- Zoom the camera by a multiplier (>1 zooms in, <1 zooms out).
---@param factor any
function Globe:zoom(factor) end

--- Lua-accessible handle to the shared `GlobeRegistry`.
---@class GlobeRegistry
local GlobeRegistry = {}

--- Get an existing globe by name, or nil.
---@param name any
---@return Globe?
function GlobeRegistry:get(name) end

--- Returns a table of all globe names.
---@return table<string>
function GlobeRegistry:names() end

--- Removes a globe from the central registry by its string name.
---@param name any
---@return boolean
function GlobeRegistry:remove(name) end

--- Get an existing globe by name, or nil.
---@param name any
---@return Globe?
function lurek.globe.get(name) end

--- Great-circle distance between two lat/lon points (in unit-sphere radians).
---@param la any
---@param lo any
---@param lb any
---@param lo2 any
---@return number
function lurek.globe.greatCircleDistance(la, lo, lb, lo2) end

--- Great-circle path as a table of {lat, lon} pairs.
---@param la any
---@param lo any
---@param lb any
---@param lo2 any
---@param n any
---@return table<{number
function lurek.globe.greatCirclePath(la, lo, lb, lo2, n) end

--- Convert lat/lon (degrees) to a unit-sphere Cartesian vector {x, y, z}.
---@param lat any
---@param lon any
---@return table
function lurek.globe.latLonToUnit(lat, lon) end

--- Load provinces from a TOML string and create a globe.
---@param name any
---@param toml_src any
---@param spec_tbl? any (optional)
---@return Globe
function lurek.globe.loadFromTOML(name, toml_src, spec_tbl) end

--- Creates a new globe instance with default settings and empty collections.
---@param name any
---@param spec_tbl? any (optional)
---@return Globe
function lurek.globe.new(name, spec_tbl) end

---@class lurek.graph
lurek.graph = {}

--- Lua handle for an edge inside a `Graph`.
---@class Edge
local Edge = {}

--- Adds an item type to the edge allow-list.
---@param t any
---@return nil
function Edge:addAllowedType(t) end

--- Clears the edge allow-list so all item types are permitted.
---@return nil
function Edge:clearAllowedTypes() end

--- Returns the edge capacity (-1 = unlimited).
---@return integer
function Edge:getCapacity() end

--- Returns the cooldown duration in seconds.
---@return number
function Edge:getCooldown() end

--- Returns the source node handle.
---@return Node
function Edge:getFrom() end

--- Returns a table of GraphItem handles currently in transit on this edge.
---@return table
function Edge:getItemsInTransit() end

--- Returns the speed modifier applied to items in transit.
---@return number
function Edge:getSpeedModifier() end

--- Returns items per second this edge can transfer.
---@return number
function Edge:getThroughput() end

--- Returns the destination node handle.
---@return Node
function Edge:getTo() end

--- Returns the travel time in seconds for items on this edge.
---@return number
function Edge:getTravelTime() end

--- Returns the edge type string.
---@return string
function Edge:getType() end

--- Returns the pathfinding weight of this edge.
---@return number
function Edge:getWeight() end

--- Returns true if the edge is active.
---@return boolean
function Edge:isActive() end

--- Returns true if items can travel the edge in either direction.
---@return boolean
function Edge:isBidirectional() end

--- Returns true if the given item type is allowed on this edge.
---@param t any
---@return boolean
function Edge:isItemTypeAllowed(t) end

--- Returns true if the edge is currently on cooldown.
---@return boolean
function Edge:isOnCooldown() end

--- Removes an item type from the edge allow-list.
---@param t any
---@return boolean
function Edge:removeAllowedType(t) end

--- Sets the active state of this edge.
---@param a any
---@return nil
function Edge:setActive(a) end

--- Sets whether items can travel the edge in either direction.
---@param b any
---@return nil
function Edge:setBidirectional(b) end

--- Sets the edge capacity (-1 = unlimited).
---@param c any
---@return nil
function Edge:setCapacity(c) end

--- Sets the cooldown duration in seconds.
---@param c any
---@return nil
function Edge:setCooldown(c) end

--- Sets the speed modifier applied to items in transit.
---@param m any
---@return nil
function Edge:setSpeedModifier(m) end

--- Sets items per second this edge can transfer.
---@param t any
---@return nil
function Edge:setThroughput(t) end

--- Sets the travel time in seconds for items on this edge.
---@param t any
---@return nil
function Edge:setTravelTime(t) end

--- Sets the edge type string.
---@param t any
---@return nil
function Edge:setType(t) end

--- Sets the pathfinding weight of this edge.
---@param w any
---@return nil
function Edge:setWeight(w) end

--- Returns the type name "GraphEdge".
---@return string
function Edge:type() end

--- Returns true when the given name matches "GraphEdge" or a parent type.
---@param name any
---@return boolean
function Edge:typeOf(name) end

--- Lua wrapper around a directed `Graph` with event callback registry.
---@class Graph
local Graph = {}

--- Assigns each node the smallest non-negative integer colour not shared with any
---@return table
function Graph:colorGraph() end

--- Returns weakly connected components as a table of tables of Node handles.
---@return table
function Graph:getComponents() end

--- Returns the number of edges in the graph.
---@return integer
function Graph:getEdgeCount() end

--- Returns a table of all Edge handles.
---@return table
function Graph:getEdges() end

--- Returns the number of items in the graph.
---@return integer
function Graph:getItemCount() end

--- Returns a table of all GraphItem handles.
---@return table
function Graph:getItems() end

--- Returns a table of direct neighbor Node handles.
---@param node_ud any
---@return table
function Graph:getNeighbors(node_ud) end

--- Returns the number of nodes in the graph.
---@return integer
function Graph:getNodeCount() end

--- Returns a table of all Node handles.
---@return table
function Graph:getNodes() end

--- Returns a statistics snapshot table.
---@return table
function Graph:getStats() end

--- Returns true if the graph contains a directed cycle.
---@return boolean
function Graph:hasCycle() end

--- Returns true if the edge exists in the graph.
---@param edge_ud any
---@return boolean
function Graph:hasEdge(edge_ud) end

--- Returns true if the item exists in the graph.
---@param item_ud any
---@return boolean
function Graph:hasItem(item_ud) end

--- Returns true if the node exists in the graph.
---@param node_ud any
---@return boolean
function Graph:hasNode(node_ud) end

--- Returns `true` when the graph can be 2-coloured (bipartite check via BFS).
---@return boolean
function Graph:isBipartite() end

--- Returns edge IDs forming a minimum spanning tree (Kruskal, undirected view).
---@return table
function Graph:mst() end

--- Processes all supply/demand declarations and fires event callbacks.
---@return nil
function Graph:processDemand() end

--- Removes an edge from the graph.
---@param edge_ud any
---@return boolean
function Graph:removeEdge(edge_ud) end

--- Removes an item from the graph entirely.
---@param item_ud any
---@return boolean
function Graph:removeItem(item_ud) end

--- Removes a node from the graph.
---@param node_ud any
---@return boolean
function Graph:removeNode(node_ud) end

--- Runs one discrete simulation step and fires event callbacks.
---@return nil
function Graph:step() end

--- Advances simulation by dt seconds using a parallelised decay phase.
---@param dt any
---@return nil
function Graph:tickParallel(dt) end

--- Returns a topologically sorted table of Node handles, or nil if a cycle exists.
---@return table?
function Graph:topologicalSort() end

--- Returns the type name of this object.
---@return string
function Graph:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function Graph:typeOf(name) end

--- Advances simulation by dt seconds and fires event callbacks.
---@param dt any
---@return nil
function Graph:update(dt) end

--- Lua handle for an item inside a `Graph`.
---@class GraphItem
local GraphItem = {}

--- Returns the decay time in seconds (-1 = immortal).
---@return number
function GraphItem:getDecayTime() end

--- Returns the item position: node userdata if at a node, (edge, progress)
---@return nil
function GraphItem:getPosition() end

--- Returns the item priority.
---@return integer
function GraphItem:getPriority() end

--- Returns the remaining life in seconds.
---@return number
function GraphItem:getRemainingLife() end

--- Returns the item type string.
---@return string
function GraphItem:getType() end

--- Returns true if the item is alive.
---@return boolean
function GraphItem:isAlive() end

--- Marks this graph item as dead so it is removed on the next cleanup pass.
---@return nil
function GraphItem:kill() end

--- Sets the decay time in seconds (-1 = immortal).
---@param t any
---@return nil
function GraphItem:setDecayTime(t) end

--- Sets the scheduling priority; higher values are processed before lower ones.
---@param p any
---@return nil
function GraphItem:setPriority(p) end

--- Sets the item type string.
---@param t any
---@return nil
function GraphItem:setType(t) end

--- Returns the type name of this object.
---@return string
function GraphItem:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function GraphItem:typeOf(name) end

--- Lua handle for a node inside a `Graph`.
---@class Node
local Node = {}

--- Attaches a string tag to this node for fast group queries.
---@param tag any
---@return nil
function Node:addTag(tag) end

--- Removes all conversion rules from this node.
---@return nil
function Node:clearAllConversions() end

--- Removes the conversion rule for the given input type.
---@param in_type any
---@return nil
function Node:clearConversion(in_type) end

--- Removes all demand declarations from this node.
---@return nil
function Node:clearDemands() end

--- Removes all supply declarations from this node.
---@return nil
function Node:clearSupplies() end

--- Removes all tags from this node.
---@return nil
function Node:clearTags() end

--- Pops the next item from the node queue, or nil if empty.
---@return nil
function Node:dequeue() end

--- Pushes an item into the node queue.
---@param item_ud any
---@return boolean
function Node:enqueue(item_ud) end

--- Returns the node capacity (-1 = unlimited).
---@return integer
function Node:getCapacity() end

--- Returns a table of Edge handles connected to this node.
---@param dir? any (optional)
---@return table
function Node:getEdges(dir) end

--- Returns the flow mode as a string.
---@return string
function Node:getFlowMode() end

--- Returns the number of items currently at this node.
---@return integer
function Node:getItemCount() end

--- Returns a table of GraphItem handles at this node.
---@return table
function Node:getItems() end

--- Returns the overflow policy as a string.
---@return string
function Node:getOverflowPolicy() end

--- Returns the processing time in seconds.
---@return number
function Node:getProcessTime() end

--- Returns the pull filter string, or nil if unset.
---@return string?
function Node:getPullFilter() end

--- Returns items per second this node pulls.
---@return number
function Node:getPullRate() end

--- Returns the push filter string, or nil if unset.
---@return string?
function Node:getPushFilter() end

--- Returns items per second this node pushes.
---@return number
function Node:getPushRate() end

--- Returns the queue capacity (-1 = unlimited).
---@return integer
function Node:getQueueCapacity() end

--- Returns the number of items currently in the queue.
---@return integer
function Node:getQueueSize() end

--- Returns a table of tag strings on this node.
---@return table
function Node:getTags() end

--- Returns the node type string.
---@return string
function Node:getType() end

--- Returns true if this node has the given tag.
---@param tag any
---@return boolean
function Node:hasTag(tag) end

--- Returns true if the node is active.
---@return boolean
function Node:isActive() end

--- Returns true if the node has reached its capacity.
---@return boolean
function Node:isFull() end

--- Returns true if the node queue is enabled.
---@return boolean
function Node:isQueueEnabled() end

--- Removes the demand declaration for the given item type.
---@param item_type any
---@return boolean
function Node:removeDemand(item_type) end

--- Removes the supply declaration for the given item type.
---@param item_type any
---@return boolean
function Node:removeSupply(item_type) end

--- Removes a tag from this node.
---@param tag any
---@return boolean
function Node:removeTag(tag) end

--- Sets the active state of this node.
---@param a any
---@return nil
function Node:setActive(a) end

--- Sets the node capacity (-1 = unlimited).
---@param c any
---@return nil
function Node:setCapacity(c) end

--- Sets the flow mode from a string.
---@param m any
---@return nil
function Node:setFlowMode(m) end

--- Sets the overflow policy from a string.
---@param p any
---@return nil
function Node:setOverflowPolicy(p) end

--- Sets the processing time in seconds.
---@param t any
---@return nil
function Node:setProcessTime(t) end

--- Sets the pull filter string, or nil to clear.
---@param f? any (optional)
---@return nil
function Node:setPullFilter(f) end

--- Sets items per second this node pulls.
---@param r any
---@return nil
function Node:setPullRate(r) end

--- Sets the push filter string, or nil to clear.
---@param f? any (optional)
---@return nil
function Node:setPushFilter(f) end

--- Sets items per second this node pushes.
---@param r any
---@return nil
function Node:setPushRate(r) end

--- Sets the queue capacity (-1 = unlimited).
---@param c any
---@return nil
function Node:setQueueCapacity(c) end

--- Enables or disables the node queue.
---@param e any
---@return nil
function Node:setQueueEnabled(e) end

--- Sets the node type string.
---@param t any
---@return nil
function Node:setType(t) end

--- Returns the type name "GraphNode".
---@return string
function Node:type() end

--- Returns true when the given name matches "GraphNode" or a parent type.
---@param name any
---@return boolean
function Node:typeOf(name) end

--- Creates a new empty directed graph for item flow simulation.
---@return Graph
function lurek.graph.newGraph() end

---@class lurek.i18n
lurek.i18n = {}

--- Builds an inverted word index for the active locale. Returns index as {word â†’ {keys}}.
---@return table
function lurek.i18n.buildIndex() end

--- Returns unique first-path-segment category prefixes for all active locale keys.
---@return table
function lurek.i18n.categories() end

--- Formats a Unix timestamp according to the active locale's date order.
---@param timestamp any
---@param fmt? any (optional)
---@return string
function lurek.i18n.formatDate(timestamp, fmt) end

--- Formats a number with locale-aware decimal and thousands separators.
---@param n any
---@param opts? any (optional)
---@return string
function lurek.i18n.formatNumber(n, opts) end

--- Returns all loaded locale codes (alias for getLanguages).
---@return table
function lurek.i18n.getAvailableLanguages() end

--- Returns the base/fallback language.
---@return string
function lurek.i18n.getBase() end

--- Returns the current fallback locale array.
---@return table
function lurek.i18n.getFallbacks() end

--- Returns all known keys for the active locale.
---@return table
function lurek.i18n.getKeys() end

--- Returns the currently active locale code, or nil if unset.
---@return string?
function lurek.i18n.getLanguage() end

--- Returns all loaded locale codes.
---@return table
function lurek.i18n.getLanguages() end

--- Returns an array of all currently loaded locale codes.
---@return table
function lurek.i18n.getLoadedLocales() end

--- Returns whether a key exists in the active locale.
---@param key any
---@return boolean
function lurek.i18n.hasKey(key) end

--- Returns whether a locale has been loaded.
---@param locale any
---@return boolean
function lurek.i18n.hasLanguage(locale) end

--- Interpolates {name} placeholders in a template string.
---@param template any
---@param vars any
---@return string
function lurek.i18n.interpolate(template, vars) end

--- Returns the number of keys loaded in the active locale.
---@return integer
function lurek.i18n.keyCount() end

--- Returns all keys in the active locale whose first path segment matches category.
---@param category any
---@return table
function lurek.i18n.keysInCategory(category) end

--- Loads a language table under the given locale code.
---@param locale any
---@param tbl any
---@return nil
function lurek.i18n.loadTable(locale, tbl) end

--- Merges a flat keyâ†’value table into an existing locale without replacing the whole table.
---@param locale any
---@param entries any
---@return nil
function lurek.i18n.mergeLocale(locale, entries) end

--- Unregisters all onChange callbacks.
---@return nil
function lurek.i18n.offChange() end

--- Registers a callback invoked when setLanguage() is called (alias: onChange).
---@param cb any
---@return nil
function lurek.i18n.onChange(cb) end

--- Registers a callback invoked when setLanguage() is called.
---@param cb any
---@return nil
function lurek.i18n.onLanguageChange(cb) end

--- Returns the CLDR plural category for a number ("one" or "other", etc.).
---@param n any
---@return string
function lurek.i18n.pluralFor(n) end

--- Searches active locale values for a substring query (case-insensitive). Returns {key, value} pairs.
---@param query any
---@param limit? any (optional)
---@return table
function lurek.i18n.search(query, limit) end

--- Searches the provided pre-built index for entries matching all words in query.
---@param index any
---@param query any
---@param limit? any (optional)
---@return table
function lurek.i18n.searchIndexed(index, query, limit) end

--- Sets the base/fallback language (adds it as first fallback).
---@param locale any
---@return nil
function lurek.i18n.setBase(locale) end

--- Sets the ordered list of fallback locale codes tried when a key is missing.
---@param locales any
---@return nil
function lurek.i18n.setFallbacks(locales) end

--- Inserts or overwrites a single key in the given locale.
---@param locale any
---@param key any
---@param value any
---@return nil
function lurek.i18n.setKey(locale, key, value) end

--- Sets the active translation language.
---@param locale any
---@return nil
function lurek.i18n.setLanguage(locale) end

--- Translates a key against the active locale with optional variable
---@param key any
---@param vars? any (optional)
---@param count? any (optional)
---@return string
function lurek.i18n.t(key, vars, count) end

--- Looks up a translation key augmented with a gender suffix.
---@param key any
---@param gender any
---@param vars? any (optional)
---@return string
function lurek.i18n.tGender(key, gender, vars) end

--- Unloads a locale from the catalog.
---@param locale any
---@return boolean
function lurek.i18n.unloadTable(locale) end

---@class lurek.image
lurek.image = {}

--- Lua-side wrapper around [`CompressedImageData`].
---@class CompressedImageData
local CompressedImageData = {}

--- Returns the width and height of the base mip level.
---@return integer
function CompressedImageData:getDimensions() end

--- Returns the compressed format name string.
---@return string
function CompressedImageData:getFormat() end

--- Returns the height of the base mip level in pixels.
---@return integer
function CompressedImageData:getHeight() end

--- Returns the number of mipmap levels stored.
---@return integer
function CompressedImageData:getMipmapCount() end

--- Returns the width of the base mip level in pixels.
---@return integer
function CompressedImageData:getWidth() end

--- Lua-side wrapper around [`LayeredImage`].
---@class LayeredImage
local LayeredImage = {}

--- Appends a new blank transparent layer on top and returns its 1-based index.
---@param name? any (optional)
---@return integer
function LayeredImage:addLayer(name) end

--- Returns the canvas height shared by all layers.
---@return integer
function LayeredImage:getHeight() end

--- Returns a copy of the layer's pixel buffer as an ImageData.
---@param index any
---@return ImageData
function LayeredImage:getLayer(index) end

--- Returns the name of a layer.
---@param index any
---@return string
function LayeredImage:getName(index) end

--- Returns the opacity of a layer in [0.0, 1.0].
---@param index any
---@return number
function LayeredImage:getOpacity(index) end

--- Returns the canvas width shared by all layers.
---@return integer
function LayeredImage:getWidth() end

--- Returns whether a layer is visible.
---@param index any
---@return boolean
function LayeredImage:isVisible(index) end

--- Returns the number of layers in the stack.
---@return integer
function LayeredImage:layerCount() end

--- Flattens all visible layers into a single ImageData using Porter-Duff "over" compositing.
---@return ImageData
function LayeredImage:merge() end

--- Removes the layer at the given 1-based index. Returns true on success.
---@param index any
---@return boolean
function LayeredImage:removeLayer(index) end

--- Saves the layered image to a LIMG binary file at the given path.
---@param path any
---@return nil
function LayeredImage:save(path) end

--- Renames the layer at the given index to the new name string.
---@param index any
---@param name any
---@return boolean
function LayeredImage:setName(index, name) end

--- Sets the opacity of a layer. Value is clamped to [0.0, 1.0].
---@param index any
---@param opacity any
---@return boolean
function LayeredImage:setOpacity(index, opacity) end

--- Shows or hides a layer during compositing.
---@param index any
---@param visible any
---@return boolean
function LayeredImage:setVisible(index, visible) end

--- Swaps two layers by their 1-based indices, changing their compositing order.
---@param a any
---@param b any
---@return boolean
function LayeredImage:swapLayers(a, b) end

--- Lua-side wrapper around [`PaletteLUT`].
---@class PaletteLUT
local PaletteLUT = {}

--- Removes all colour mapping entries.
---@return nil
function PaletteLUT:clear() end

--- Returns the number of colour mapping entries.
---@return integer
function PaletteLUT:getColorCount() end

--- Lua-side wrapper around [`ProvinceGrid`].
---@class ProvinceGrid
local ProvinceGrid = {}

--- Returns an array of adjacency records. Each record is {province_a, province_b, border_pixels}.
---@return table
function ProvinceGrid:adjacencies() end

--- Returns the province ID at pixel coordinates (x, y). Returns 0 for background or out-of-bounds.
---@param x any
---@param y any
---@return integer
function ProvinceGrid:getAt(x, y) end

--- Returns the grid height in pixels.
---@return integer
function ProvinceGrid:getHeight() end

--- Returns the grid width in pixels.
---@return integer
function ProvinceGrid:getWidth() end

--- Returns the number of unique non-zero province IDs detected in the map.
---@return integer
function ProvinceGrid:provinceCount() end

---@class mlua
local mlua = {}

--- Alpha mask.
---@param factor any
---@return nil
function mlua:alphaMask(factor) end

--- Applies a `PaletteLUT` to the image in place, replacing exact colour matches.
---@param lut_ud any
---@return nil
function mlua:applyPaletteLut(lut_ud) end

--- Blur.
---@param radius any
---@return nil
function mlua:blur(radius) end

--- Brightness.
---@param factor any
---@return nil
function mlua:brightness(factor) end

--- Contrast.
---@param factor any
---@return nil
function mlua:contrast(factor) end

--- Crop.
---@param x any
---@param y any
---@param w any
---@param h any
---@return nil
function mlua:crop(x, y, w, h) end

--- Returns the sum of absolute per-channel pixel differences with another ImageData.
---@param other_ud any
---@return integer
function mlua:diff(other_ud) end

--- Encode.
---@param format any
---@return nil
function mlua:encode(format) end

--- Fill.
---@param r any
---@param g any
---@param b any
---@param a any
---@return nil
function mlua:fill(r, g, b, a) end

--- Flip horizontal.
---@return nil
function mlua:flipHorizontal() end

--- Flip vertical.
---@return nil
function mlua:flipVertical() end

--- Gamma.
---@param gamma any
---@return nil
function mlua:gamma(gamma) end

--- Returns the dimensions.
---@return table|nil
function mlua:getDimensions() end

--- Returns the height.
---@return table|nil
function mlua:getHeight() end

--- Returns the pixel.
---@param x any
---@param y any
---@return nil
function mlua:getPixel(x, y) end

--- Returns the string.
---@return table|nil
function mlua:getString() end

--- Returns the width.
---@return table|nil
function mlua:getWidth() end

--- Grayscale.
---@return nil
function mlua:grayscale() end

--- Invert.
---@return nil
function mlua:invert() end

--- Map pixel.
---@param func any
---@return nil
function mlua:mapPixel(func) end

--- Applies a function to every pixel in-place.
---@param func any
---@return nil
function mlua:mapPixels(func) end

--- Noise.
---@param amount any
---@return nil
function mlua:noise(amount) end

--- Posterize.
---@param levels any
---@return nil
function mlua:posterize(levels) end

--- Returns a bilinear-interpolated copy of the image at the given dimensions.
---@param w any
---@param h any
---@return nil
function mlua:resize(w, h) end

--- Resize nearest.
---@param new_w any
---@param new_h any
---@return nil
function mlua:resizeNearest(new_w, new_h) end

--- Rotate90cw.
---@return nil
function mlua:rotate90cw() end

--- Saturation.
---@param factor any
---@return nil
function mlua:saturation(factor) end

--- Sepia.
---@return nil
function mlua:sepia() end

--- Replaces all pixel data from a raw RGBA byte string.
---@param bytes any
---@return nil
function mlua:setRawData(bytes) end

--- Sharpen.
---@return nil
function mlua:sharpen() end

--- Threshold.
---@param value any
---@return nil
function mlua:threshold(value) end

--- Returns true if the file at the given path is a DDS file.
---@param filename any
---@return boolean
function lurek.image.isCompressed(filename) end

--- Loads an ImageData from a LIMG binary file.
---@param filename any
---@return ImageData
function lurek.image.loadImage(filename) end

--- Loads a LayeredImage from a LIMG binary file.
---@param filename any
---@return LayeredImage
function lurek.image.loadLayered(filename) end

--- Loads compressed texture data from a DDS file.
---@param filename any
---@return CompressedImageData
function lurek.image.newCompressedData(filename) end

--- Creates a new blank ImageData or loads one from a file.
---@param args any
---@return ImageData
function lurek.image.newImageData(args) end

--- Creates a new empty LayeredImage canvas with no layers.
---@param width any
---@param height any
---@return LayeredImage
function lurek.image.newLayeredImage(width, height) end

--- Creates a new empty `PaletteLUT` used to remap colours in an image.
---@return PaletteLUT
function lurek.image.newPaletteLut() end

--- Loads a province map PNG and builds an O(1) spatial index with adjacency data.
---@param filename any
---@return ProvinceGrid
function lurek.image.newProvinceGrid(filename) end

--- Saves a flat ImageData to a LIMG binary file at the given path.
---@param img_ud any
---@param filename any
---@return nil
function lurek.image.saveImage(img_ud, filename) end

--- Saves a flat ImageData as a PNG file at the given path.
---@param img_ud any
---@param filename any
---@return nil
function lurek.image.savePNG(img_ud, filename) end

---@class lurek.input
lurek.input = {}

--- Lua-side wrapper for a [`ComboDetector`] with an integrated millisecond clock.
---@class Combo
local Combo = {}

--- Feed a key-press event into the combo detector.
---@param key any
---@return nil
function Combo:feed(key) end

--- Returns the step at the given 1-based index as `{key=..., gap_ms=...}`.
---@param index any
---@return nil
function Combo:getStep(index) end

--- Returns true if the detector is currently mid-sequence.
---@return boolean
function Combo:isInProgress() end

--- Reset the detector to its initial idle state, cancelling any in-progress sequence.
---@return nil
function Combo:reset() end

--- Advance the internal clock by `dt` seconds and check for timeouts.
---@param dt any
---@return nil
function Combo:tick(dt) end

--- Returns the total number of steps in the combo sequence.
---@return integer
function Combo:totalSteps() end

--- Lua-side wrapper around a mouse cursor handle.
---@class Cursor
local Cursor = {}

--- Returns the cursor type as "system" or "custom".
---@return string
function Cursor:getType() end

--- Releases the cursor resource (no-op on desktop).
---@return nil
function Cursor:release() end

--- Lua userdata wrapper for a completed [`crate::input::recorder::InputRecording`].
---@class InputRecording
local InputRecording = {}

--- Returns the number of sparse event frames stored in this recording.
---@return integer
function InputRecording:frameCount() end

--- Serializes this recording to a JSON string for saving to disk.
---@return string
function InputRecording:toJson() end

--- Returns the total frame count when recording was stopped.
---@return integer
function InputRecording:totalFrames() end

--- Advances playback by one frame and returns an array of key/button events for that
---@return table
function lurek.input.advancePlayback() end

--- Maps an action name to one or more key/button names.
---@param action any
---@param keys any
---@return nil
function lurek.input.bind(action, keys) end

--- Removes all action bindings.
---@return nil
function lurek.input.clearBindings() end

--- Returns the current value (-1 to 1) of a gamepad analog axis.
---@param id any
---@param axis any
---@return number
function lurek.input.getAxis(id, axis) end

--- Returns the total number of analog axes on the gamepad.
---@param id any
---@return integer
function lurek.input.getAxisCount(id) end

--- Returns whether background gamepad events are enabled.
---@return boolean
function lurek.input.getBackgroundEvents() end

--- Returns a table mapping each action name to its bound keys.
---@return table
function lurek.input.getBindings() end

--- Returns the total number of buttons on the gamepad.
---@param id any
---@return integer
function lurek.input.getButtonCount(id) end

--- Returns the number of connected gamepads.
---@return integer
function lurek.input.getCount() end

--- Returns the name of the currently active system cursor.
---@return string
function lurek.input.getCursor() end

--- Returns the hardware GUID string of the gamepad.
---@param id any
---@return string
function lurek.input.getGUID(id) end

--- Returns the stored mapping string for the given GUID, or nil.
---@param guid any
---@return string?
function lurek.input.getGamepadMappingString(guid) end

--- Returns the direction string of a hat switch on the gamepad.
---@param id any
---@param hat any
---@return string
function lurek.input.getHat(id, hat) end

--- Returns the number of tracked gamepad slots.
---@return integer
function lurek.input.getJoystickCount() end

--- Returns a list of connected gamepad IDs.
---@return table
function lurek.input.getJoysticks() end

--- Returns the key name for the given hardware scancode.
---@param scancode any
---@return string?
function lurek.input.getKeyFromScancode(scancode) end

--- Returns the human-readable name of a gamepad.
---@param id any
---@return string
function lurek.input.getName(id) end

--- Returns the current playback frame index (0-based).  Returns 0 when not playing.
---@return integer
function lurek.input.getPlaybackFrame() end

--- Returns the current cursor position as (x, y).
---@return number
function lurek.input.getPosition() end

--- Returns the position (x, y) of the touch with the given ID.
---@param id any
---@return number
function lurek.input.getPosition(id) end

--- Returns the pressure (0-1) of the touch with the given ID.
---@param id any
---@return number
function lurek.input.getPressure(id) end

--- Returns whether relative mouse mode is active.
---@return boolean
function lurek.input.getRelativeMode() end

--- Returns the hardware scancode for the given key name.
---@param key any
---@return string?
function lurek.input.getScancodeFromKey(key) end

--- Returns a system cursor object for the named cursor shape.
---@param name any
---@return Cursor
function lurek.input.getSystemCursor(name) end

--- Returns the number of currently active touch points.
---@return integer
function lurek.input.getTouchCount() end

--- Returns a table of active touch points with id, x, y, and pressure fields.
---@return table
function lurek.input.getTouches() end

--- Returns the mouse scroll wheel delta (dx, dy) since last frame.
---@return number
function lurek.input.getWheelDelta() end

--- Returns the current mouse X position in window coordinates.
---@return number
function lurek.input.getX() end

--- Returns the current mouse Y position in window coordinates.
---@return number
function lurek.input.getY() end

--- Returns whether key-repeat is currently enabled.
---@return boolean
function lurek.input.hasKeyRepeat() end

--- Returns whether text input mode is currently active.
---@return boolean
function lurek.input.hasTextInput() end

--- Returns true if any key bound to the action is currently held down.
---@param action any
---@return boolean
function lurek.input.isActionDown(action) end

--- Returns whether the gamepad with the given ID is connected.
---@param id any
---@return boolean
function lurek.input.isConnected(id) end

--- Returns whether cursor customisation is supported on this platform.
---@return boolean
function lurek.input.isCursorSupported() end

--- Returns true if any of the given keys is currently held down.
---@param args any
---@return boolean
function lurek.input.isDown(args) end

--- Returns whether the given mouse button is currently held down.
---@param button any
---@return boolean
function lurek.input.isDown(button) end

--- Returns whether the given button on the gamepad is currently held.
---@param id any
---@param button any
---@return boolean
function lurek.input.isDown(id, button) end

--- Returns whether the joystick at the given slot is a recognized gamepad.
---@param id any
---@return boolean
function lurek.input.isGamepad(id) end

--- Returns whether the mouse cursor is locked to the window.
---@return boolean
function lurek.input.isGrabbed() end

--- Returns whether the named modifier key is currently held.
---@param modifier any
---@return boolean
function lurek.input.isModifierActive(modifier) end

--- Returns true if input playback is currently active.
---@return boolean
function lurek.input.isPlayingBack() end

--- Returns true if input recording is currently active.
---@return boolean
function lurek.input.isRecording() end

--- Returns whether the key with the given scancode is held.
---@param scancode any
---@return boolean
function lurek.input.isScancodeDown(scancode) end

--- Returns whether the gamepad supports haptic vibration.
---@param id any
---@return boolean
function lurek.input.isVibrationSupported(id) end

--- Returns whether the mouse cursor is currently visible.
---@return boolean
function lurek.input.isVisible() end

--- Loads SDL2 GameControllerDB-format mappings from a file.
---@param path any
---@return integer
function lurek.input.loadGamepadMappings(path) end

--- Loads a JSON-encoded recording string for playback.
---@param json any
---@return nil
function lurek.input.loadRecording(json) end

--- Creates a new combo detector from an ordered list of steps.
---@param steps_val any
---@param opts? any (optional)
---@return Combo
function lurek.input.newCombo(steps_val, opts) end

--- Creates a custom mouse cursor from RGBA pixel data.
---@param pixels table
---@param width integer
---@param height integer
---@param hotx? integer? (optional)
---@param hoty? integer? (optional)
---@return Cursor
function lurek.input.newCursor(pixels, width, height, hotx, hoty) end

--- Saves all stored gamepad mappings to a plain-text file.
---@param path any
---@return nil
function lurek.input.saveGamepadMappings(path) end

--- Enable or disable receiving gamepad events when the window is not focused.
---@param enable any
---@return nil
function lurek.input.setBackgroundEvents(enable) end

--- Sets the active mouse cursor from a Cursor handle, name string, or nil to reset.
---@param cursor_val any
---@return nil
function lurek.input.setCursor(cursor_val) end

--- Stores or replaces the SDL2 GameControllerDB mapping string for the given GUID.
---@param guid any
---@param mapping any
---@return nil
function lurek.input.setGamepadMapping(guid, mapping) end

--- Locks or unlocks the mouse cursor to the window.
---@param grabbed any
---@return nil
function lurek.input.setGrabbed(grabbed) end

--- Enables or disables key-repeat events.
---@param enabled any
---@return nil
function lurek.input.setKeyRepeat(enabled) end

--- Moves the mouse cursor to the given window-space position.
---@param x any
---@param y any
---@return nil
function lurek.input.setPosition(x, y) end

--- Enables or disables raw relative mouse motion mode.
---@param relative any
---@return nil
function lurek.input.setRelativeMode(relative) end

--- Enables or disables Unicode text input mode.
---@param enabled any
---@return nil
function lurek.input.setTextInput(enabled) end

--- Triggers haptic rumble (currently a no-op stub).
---@param args any
---@return boolean
function lurek.input.setVibration(args) end

--- Shows or hides the operating-system mouse cursor.
---@param visible any
---@return nil
function lurek.input.setVisible(visible) end

--- Starts playback from the beginning of the loaded recording.
---@return nil
function lurek.input.startPlayback() end

--- Starts capturing input events frame-by-frame.  Clears any previous recording.
---@return nil
function lurek.input.startRecording() end

--- Stops playback immediately.
---@return nil
function lurek.input.stopPlayback() end

--- Stops recording and returns an `InputRecording` userdata, or nil if not recording.
---@return table|nil
function lurek.input.stopRecording() end

--- Removes all key bindings for the given action name.
---@param action any
---@return boolean
function lurek.input.unbind(action) end

--- Requests haptic vibration on a gamepad.
---@param id any
---@param low_freq any
---@param high_freq any
---@param duration_ms any
---@return boolean
function lurek.input.vibrate(id, low_freq, high_freq, duration_ms) end

--- Returns true if any key bound to the action was pressed this frame.
---@param action any
---@return boolean
function lurek.input.wasActionPressed(action) end

--- Was action pressed within.
---@param action any
---@param frames any
---@return boolean
function lurek.input.wasActionPressedWithin(action, frames) end

--- Returns true if any key bound to the action was released this frame.
---@param action any
---@return boolean
function lurek.input.wasActionReleased(action) end

---@class lurek.light
lurek.light = {}

--- Lua-side handle to a light resource stored in [`LightWorld`].
---@class Light
local Light = {}

--- Convenience method to set a flicker effect using amplitude range and
---@param min any
---@param max any
---@param hz any
---@return nil
function Light:addFlicker(min, max, hz) end

--- Removes the cookie texture assignment.
---@return nil
function Light:clearCookie() end

--- Returns the custom attenuation coefficients as (constant, linear, quadratic).
---@return number
function Light:getAttenuation() end

--- Returns the blend mode as a string.
---@return string
function Light:getBlendMode() end

--- Returns the light's tint color as (r, g, b, a).
---@return number
function Light:getColor() end

--- Returns the current cookie texture path, or `nil` if unset.
---@return string?
function Light:getCookie() end

--- Returns the direction angle in radians.
---@return number
function Light:getDirection() end

--- Returns the energy scaling factor.
---@return number
function Light:getEnergy() end

--- Returns the falloff mode as a string.
---@return string
function Light:getFalloff() end

--- Returns the flicker effect speed and strength.
---@return number
function Light:getFlicker() end

--- Returns the group identifier.
---@return integer
function Light:getGroupId() end

--- Returns the inner cone angle in radians.
---@return number
function Light:getInnerAngle() end

--- Returns the brightness multiplier.
---@return number
function Light:getIntensity() end

--- Returns the light interaction bitmask.
---@return integer
function Light:getLightMask() end

--- Returns the geometric light type as a string.
---@return string
function Light:getLightType() end

--- Returns the outer cone angle in radians.
---@return number
function Light:getOuterAngle() end

--- Returns the light's world-space position.
---@return number
function Light:getPosition() end

--- Returns the light's influence radius.
---@return number
function Light:getRadius() end

--- Returns the shadow region color as (r, g, b, a).
---@return number
function Light:getShadowColor() end

--- Returns the shadow edge filter as a string.
---@return string
function Light:getShadowFilter() end

--- Returns the shadow casting bitmask.
---@return integer
function Light:getShadowMask() end

--- Returns the shadow edge smoothing factor.
---@return number
function Light:getShadowSmooth() end

--- Returns whether this light is active.
---@return boolean
function Light:isEnabled() end

--- Returns whether the flicker effect is active.
---@return boolean
function Light:isFlickerEnabled() end

--- Returns whether this light casts shadows.
---@return boolean
function Light:isShadowEnabled() end

--- Returns whether this light handle is still valid.
---@return boolean
function Light:isValid() end

--- Returns whether this light hints at volumetric scattering.
---@return boolean
function Light:isVolumetric() end

--- Removes this light from the world.
---@return nil
function Light:remove() end

--- Sets the custom attenuation coefficients (constant, linear, quadratic).
---@param c any
---@param l any
---@param q any
---@return nil
function Light:setAttenuation(c, l, q) end

--- Sets the blend mode ('add', 'sub', or 'mix').
---@param mode any
---@return nil
function Light:setBlendMode(mode) end

--- Sets the texture path used as a light cookie (mask) for projection.
---@param path any
---@return nil
function Light:setCookie(path) end

--- Sets the direction angle in radians.
---@param dir any
---@return nil
function Light:setDirection(dir) end

--- Sets whether this light is active.
---@param b any
---@return nil
function Light:setEnabled(b) end

--- Sets the energy scaling factor.
---@param e any
---@return nil
function Light:setEnergy(e) end

--- Sets the falloff mode ('linear', 'smooth', or 'constant').
---@param mode any
---@return nil
function Light:setFalloff(mode) end

--- Sets the flicker effect speed and strength (enables flicker).
---@param speed any
---@param strength any
---@return nil
function Light:setFlicker(speed, strength) end

--- Sets whether the flicker effect is active.
---@param b any
---@return nil
function Light:setFlickerEnabled(b) end

--- Sets the group identifier for batch operations.
---@param id any
---@return nil
function Light:setGroupId(id) end

--- Sets the inner cone angle in radians for spot lights.
---@param a any
---@return nil
function Light:setInnerAngle(a) end

--- Sets the brightness multiplier.
---@param i any
---@return nil
function Light:setIntensity(i) end

--- Sets the light interaction bitmask.
---@param mask any
---@return nil
function Light:setLightMask(mask) end

--- Sets the geometric light type ('point', 'directional', or 'spot').
---@param t any
---@return nil
function Light:setLightType(t) end

--- Sets the outer cone angle in radians for spot lights.
---@param a any
---@return nil
function Light:setOuterAngle(a) end

--- Sets the light's world-space position.
---@param x any
---@param y any
---@return nil
function Light:setPosition(x, y) end

--- Sets the light's influence radius.
---@param r any
---@return nil
function Light:setRadius(r) end

--- Sets whether this light casts shadows.
---@param b any
---@return nil
function Light:setShadowEnabled(b) end

--- Sets the shadow edge filter ('none', 'pcf5', or 'pcf13').
---@param filter any
---@return nil
function Light:setShadowFilter(filter) end

--- Sets the shadow casting bitmask.
---@param mask any
---@return nil
function Light:setShadowMask(mask) end

--- Sets the shadow edge smoothing factor.
---@param s any
---@return nil
function Light:setShadowSmooth(s) end

--- Sets whether this light hints at volumetric scattering.
---@param b any
---@return nil
function Light:setVolumetric(b) end

--- Cancels the active light transition.
---@return nil
function Light:stopTransition() end

--- Returns the fractional progress `[0, 1]` of the active transition,
---@return number
function Light:transitionProgress() end

--- Advances the active transition by `dt` seconds and applies the
---@param dt any
---@return boolean
function Light:updateTransition(dt) end

--- Lua-side handle to an occluder resource stored in [`LightWorld`].
---@class Occluder
local Occluder = {}

--- Returns the light interaction bitmask.
---@return integer
function Occluder:getLightMask() end

--- Returns the shadow opacity.
---@return number
function Occluder:getOpacity() end

--- Returns the translation offset as (x, y).
---@return number
function Occluder:getPosition() end

--- Returns the polygon vertices as a flat table {x1,y1,x2,y2,...}.
---@return table
function Occluder:getVertices() end

--- Returns whether this occluder is active.
---@return boolean
function Occluder:isEnabled() end

--- Returns whether this occluder handle is still valid.
---@return boolean
function Occluder:isValid() end

--- Removes this occluder from the world.
---@return nil
function Occluder:remove() end

--- Sets whether this occluder is active.
---@param b any
---@return nil
function Occluder:setEnabled(b) end

--- Sets the light interaction bitmask.
---@param mask any
---@return nil
function Occluder:setLightMask(mask) end

--- Sets the shadow opacity (0.0â€“1.0).
---@param o any
---@return nil
function Occluder:setOpacity(o) end

--- Sets the translation offset applied to all vertices.
---@param x any
---@param y any
---@return nil
function Occluder:setPosition(x, y) end

--- Replaces the polygon vertices from a flat table {x1,y1,x2,y2,...}.
---@param tbl any
---@return nil
function Occluder:setVertices(tbl) end

--- Advances flicker phase for all lights with flicker enabled.
---@param dt any
---@return nil
function lurek.light.advanceFlickers(dt) end

--- Removes all lights and occluders, resets ambient to default.
---@return nil
function lurek.light.clear() end

--- Returns the global ambient light color as (r, g, b, a).
---@return number
function lurek.light.getAmbient() end

--- Returns a list of directional light hints for god-ray rendering.
---@return table
function lurek.light.getGodRayHints() end

--- Returns the number of lights in the given group.
---@param group_id any
---@return integer
function lurek.light.getGroupCount(group_id) end

--- Returns the number of lights in the world.
---@return integer
function lurek.light.getLightCount() end

--- Returns the maximum number of lights processed per frame.
---@return integer
function lurek.light.getMaxLights() end

--- Returns the number of occluders in the world.
---@return integer
function lurek.light.getOccluderCount() end

--- Returns whether the lighting system is active.
---@return boolean
function lurek.light.isEnabled() end

--- Creates a new light at (x, y) with the given radius and optional settings.
---@param x any
---@param y any
---@param radius any
---@param opts? any (optional)
---@return Light
function lurek.light.newLight(x, y, radius, opts) end

--- Creates a new shadow occluder from a vertex table and optional settings.
---@param vtbl any
---@param opts? any (optional)
---@return Occluder
function lurek.light.newOccluder(vtbl, opts) end

--- Sets the global ambient light color.
---@param r any
---@param g any
---@param b any
---@param a? any (optional)
---@return nil
function lurek.light.setAmbient(r, g, b, a) end

--- Sets whether the lighting system is active.
---@param enabled any
---@return nil
function lurek.light.setEnabled(enabled) end

--- Sets the color for all lights in the given group.
---@param group_id any
---@param r any
---@param g any
---@param b any
---@param a? any (optional)
---@return nil
function lurek.light.setGroupColor(group_id, r, g, b, a) end

--- Sets the enabled state for all lights in the given group.
---@param group_id any
---@param enabled any
---@return nil
function lurek.light.setGroupEnabled(group_id, enabled) end

--- Sets the intensity for all lights in the given group.
---@param group_id any
---@param intensity any
---@return nil
function lurek.light.setGroupIntensity(group_id, intensity) end

--- Sets the maximum number of lights processed per frame (clamped 1â€“256).
---@param n any
---@return nil
function lurek.light.setMaxLights(n) end

--- Returns the current ambient light colour as (r, g, b, a).
---@return number
function lurek.light.syncAmbient() end

---@class lurek.log
lurek.log = {}

--- Registers a new output sink. Returns its numeric id.
---@param config any
---@return integer
function lurek.log.addSink(config) end

--- Removes all registered sinks (the default stderr channel is unaffected).
---@return nil
function lurek.log.clearSinks() end

--- Emits a debug-severity log message. Also dispatches to configured sinks.
---@param message any
---@param tag? any (optional)
---@return nil
function lurek.log.debug(message, tag) end

--- Emits a debug structured log message. Shorthand for `struct("debug", ...)`.
---@param message any
---@param fields_tbl any
---@return nil
function lurek.log.debug_fields(message, fields_tbl) end

--- Emits an error-severity log message. Also dispatches to configured sinks.
---@param message any
---@param tag? any (optional)
---@return nil
function lurek.log.error(message, tag) end

--- Emits an error structured log message. Shorthand for `struct("error", ...)`.
---@param message any
---@param fields_tbl any
---@return nil
function lurek.log.error_fields(message, fields_tbl) end

--- Flushes the OS write buffer for a file sink.
---@param id any
---@return nil
function lurek.log.flushFile(id) end

--- Returns the name of the currently active minimum log level.
---@return string
function lurek.log.getLevel() end

--- Emits an info-severity log message. Also dispatches to configured sinks.
---@param message any
---@param tag? any (optional)
---@return nil
function lurek.log.info(message, tag) end

--- Emits an info structured log message. Shorthand for `struct("info", ...)`.
---@param message any
---@param fields_tbl any
---@return nil
function lurek.log.info_fields(message, fields_tbl) end

--- Returns a table describing all registered sinks.
---@return table
function lurek.log.listSinks() end

--- Emits a log message at the specified level. Also dispatches to sinks.
---@param level any
---@param message any
---@param tag? any (optional)
---@return nil
function lurek.log.print(level, message, tag) end

--- Reads entries from a memory sink. If drain=true the buffer is cleared.
---@param id any
---@param drain? any (optional)
---@return table?
function lurek.log.readMemory(id, drain) end

--- Removes a sink by id. Returns true if one was removed.
---@param id any
---@return boolean
function lurek.log.removeSink(id) end

--- Sets the minimum severity level for the default log channel.
---@param level any
---@return nil
function lurek.log.setLevel(level) end

--- Emits a structured log message with key-value fields.
---@param level_str any
---@param message any
---@param fields_tbl any
---@return nil
function lurek.log.struct(level_str, message, fields_tbl) end

--- Emits a warn-severity log message. Also dispatches to configured sinks.
---@param message any
---@param tag? any (optional)
---@return nil
function lurek.log.warn(message, tag) end

--- Emits a warn structured log message. Shorthand for `struct("warn", ...)`.
---@param message any
---@param fields_tbl any
---@return nil
function lurek.log.warn_fields(message, fields_tbl) end

---@class lurek.math
lurek.math = {}

--- Lua-side wrapper around an [`AabbTree`].
---@class AabbTree
local AabbTree = {}

--- Removes all entries from the tree.
---@return nil
function AabbTree:clear() end

--- Returns true if an entry with the given id exists in the tree.
---@param id any
---@return boolean
function AabbTree:contains(id) end

--- Returns true if the tree contains no entries.
---@return boolean
function AabbTree:isEmpty() end

--- Returns the number of entries in the tree.
---@return integer
function AabbTree:len() end

--- Returns the ids of all entries whose AABBs contain the given point.
---@param x any
---@param y any
---@return table
function AabbTree:queryPoint(x, y) end

--- Removes the entry with the given id.
---@param id any
---@return boolean
function AabbTree:remove(id) end

--- Lua-side wrapper around a [`BezierCurve`].
---@class BezierCurve
local BezierCurve = {}

--- Evaluates the curve at parameter t, returning (x, y).
---@param t any
---@return number
function BezierCurve:evaluate(t) end

--- Returns the control point at 1-based index as (x, y), or nil.
---@param index any
---@return nil
function BezierCurve:getControlPoint(index) end

--- Returns the number of control points.
---@return integer
function BezierCurve:getControlPointCount() end

--- Returns a new BezierCurve representing the first derivative.
---@return BezierCurve
function BezierCurve:getDerivative() end

--- Returns the approximate arc length of the curve.
---@return number
function BezierCurve:length() end

--- Removes a control point at 1-based index.
---@param index any
---@return boolean
function BezierCurve:removeControlPoint(index) end

--- Renders the curve as a polyline with the given number of segments.
---@param segments any
---@return table
function BezierCurve:render(segments) end

--- Rotates all control points around a pivot by angle radians.
---@param angle any
---@param ox any
---@param oy any
---@return nil
function BezierCurve:rotate(angle, ox, oy) end

--- Scales all control points around a pivot by factor s.
---@param s any
---@param ox any
---@param oy any
---@return nil
function BezierCurve:scale(s, ox, oy) end

--- Translates all control points by (dx, dy).
---@param dx any
---@param dy any
---@return nil
function BezierCurve:translate(dx, dy) end

--- Lua-side wrapper around a [`CatmullRomSpline`].
---@class CatmullRom
local CatmullRom = {}

--- Appends a control point to the spline.
---@param x any
---@param y any
function CatmullRom:addPoint(x, y) end

--- Number of control points.
---@return integer
function CatmullRom:len() end

--- Removes the control point at `index` (0-based) and returns it.
---@param idx any
---@return number
function CatmullRom:removePoint(idx) end

--- Sample the spline at global t in [0, 1].
---@param t any
---@return number
function CatmullRom:sample(t) end

--- Sample a specific segment at local t in [0, 1].
---@param seg any
---@param t any
---@return number
function CatmullRom:sampleSegment(seg, t) end

--- Lua-side wrapper around a [`Circle`].
---@class Circle
local Circle = {}

--- Returns the axis-aligned bounding box as (min_x, min_y, max_x, max_y).
---@return number
function Circle:aabb() end

--- Returns the area of the circle (π r²).
---@return number
function Circle:area() end

--- Returns true if the point (px, py) lies inside or on the boundary.
---@param px any
---@param py any
---@return boolean
function Circle:contains(px, py) end

--- Returns true if this circle overlaps another circle.
---@param other any
---@return boolean
function Circle:intersects(other) end

--- Returns the circumference of the circle (2 π r).
---@return number
function Circle:perimeter() end

--- Returns the circle radius.
---@return number
function Circle:radius() end

--- Returns the circle centre X.
---@return number
function Circle:x() end

--- Returns the circle centre Y.
---@return number
function Circle:y() end

--- Lua-side wrapper around a [`HermiteSpline`].
---@class Hermite
local Hermite = {}

--- Evaluate the spline at parameter t in [0, 1].
---@param t any
---@return number
function Hermite:sample(t) end

--- Lua-side wrapper around a [`NoiseGenerator`].
---@class NoiseGenerator
local NoiseGenerator = {}

--- Returns the current seed.
---@return integer
function NoiseGenerator:getSeed() end

--- Returns 1D Perlin noise at x.
---@param x any
---@return number
function NoiseGenerator:perlin1d(x) end

--- Returns 2D Perlin noise at (x, y).
---@param x any
---@param y any
---@return number
function NoiseGenerator:perlin2d(x, y) end

--- Returns 3D Perlin noise at (x, y, z).
---@param x any
---@param y any
---@param z any
---@return number
function NoiseGenerator:perlin3d(x, y, z) end

--- Returns 4D Perlin noise at (x, y, z, w).
---@param x any
---@param y any
---@param z any
---@param w any
---@return number
function NoiseGenerator:perlin4d(x, y, z, w) end

--- Sets the seed and rebuilds the permutation table.
---@param seed any
---@return nil
function NoiseGenerator:setSeed(seed) end

--- Returns 1D Simplex noise at x.
---@param x any
---@return number
function NoiseGenerator:simplex1d(x) end

--- Returns 2D Simplex noise at (x, y).
---@param x any
---@param y any
---@return number
function NoiseGenerator:simplex2d(x, y) end

--- Returns 3D Simplex noise at (x, y, z).
---@param x any
---@param y any
---@param z any
---@return number
function NoiseGenerator:simplex3d(x, y, z) end

--- Lua-side wrapper around a [`RandomGenerator`].
---@class RandomGenerator
local RandomGenerator = {}

--- Returns the seed used to initialise this generator.
---@return integer
function RandomGenerator:getSeed() end

--- Serialises the generator state as a string for later restoration.
---@return string
function RandomGenerator:getState() end

--- Returns a uniform random number in [0, 1).
---@return number
function RandomGenerator:random() end

--- Returns a uniform random float in [min, max).
---@param min any
---@param max any
---@return number
function RandomGenerator:randomFloat(min, max) end

--- Returns a uniform random integer in [min, max].
---@param min any
---@param max any
---@return integer
function RandomGenerator:randomInt(min, max) end

--- Sets the seed, fully resetting the generator state.
---@param seed any
---@return nil
function RandomGenerator:setSeed(seed) end

--- Restores the generator state from a previously serialised string.
---@param state any
---@return nil
function RandomGenerator:setState(state) end

--- Lua-side wrapper around a [`SpatialHash`].
---@class SpatialHash
local SpatialHash = {}

--- Removes all registered items from this spatial hash, leaving it empty.
---@return nil
function SpatialHash:clear() end

--- Returns the cell size used to partition the spatial hash grid.
---@return number
function SpatialHash:getCellSize() end

--- Returns the number of items in the hash.
---@return integer
function SpatialHash:getItemCount() end

--- Removes an item by its ID.
---@param id any
---@return nil
function SpatialHash:remove(id) end

--- Lua-side wrapper around a [`Transform`].
---@class Transform
local Transform = {}

--- Returns a copy of this transform.
---@return Transform
function Transform:clone() end

--- Decomposes this transform into translation, rotation, and scale.
---@return number
function Transform:decompose() end

--- Returns the 3x3 matrix as a flat table of 9 numbers (row-major).
---@return table
function Transform:getMatrix() end

--- Returns a new Transform that undoes this transform.
---@return Transform
function Transform:inverse() end

--- Transforms a point from world space back to local space.
---@param x any
---@param y any
---@return number
function Transform:inverseTransformPoint(x, y) end

--- Resets the transform to identity.
---@return nil
function Transform:reset() end

--- Applies a rotation in radians.
---@param angle any
---@return nil
function Transform:rotate(angle) end

--- Applies non-uniform scaling.
---@param sx any
---@param sy? any (optional)
---@return nil
function Transform:scale(sx, sy) end

--- Applies horizontal and vertical shear factors to this transform matrix.
---@param kx any
---@param ky any
---@return nil
function Transform:shear(kx, ky) end

--- Transforms a point from local space to world space.
---@param x any
---@param y any
---@return number
function Transform:transformPoint(x, y) end

--- Applies translation to the transform.
---@param dx any
---@param dy any
---@return nil
function Transform:translate(dx, dy) end

--- Lua-side wrapper around a [`Tween`].
---@class Tween
local Tween = {}

--- Adds a start/target value pair. Returns the 1-based index.
---@param start any
---@param target any
---@return integer
function Tween:addValue(start, target) end

--- Returns all interpolated values as a table.
---@return table
function Tween:getAllValues() end

--- Alias for getTime(). Returns the current clock time.
---@return number
function Tween:getClock() end

--- Returns the tween duration in seconds.
---@return number
function Tween:getDuration() end

--- Returns the easing function name.
---@return string
function Tween:getEasingName() end

--- Returns the current clock time.
---@return number
function Tween:getTime() end

--- Returns the interpolated value at 1-based index, or all values as a
---@param index? any (optional)
---@return nil
function Tween:getValue(index) end

--- Returns the number of values in this tween.
---@return integer
function Tween:getValueCount() end

--- Returns true if the tween has finished.
---@return boolean
function Tween:isComplete() end

--- Resets the tween elapsed time to zero, restarting the animation.
---@return nil
function Tween:reset() end

--- Alias for setTime(). Sets the clock to t, clamped to [0, duration].
---@param t any
---@return nil
function Tween:set(t) end

--- Sets the clock to a specific time, clamped to [0, duration].
---@param t any
---@return nil
function Tween:setTime(t) end

--- Advances the clock by dt seconds. Returns true when complete.
---@param dt any
---@return boolean
function Tween:update(dt) end

--- Lua-side wrapper around a [`Vec2`] value type.
---@class Vec2
local Vec2 = {}

--- Returns the angle of this vector in radians (atan2(y, x)).
---@return number
function Vec2:angle() end

--- Returns the 2D cross product (scalar) with another vector.
---@param other any
---@return number
function Vec2:cross(other) end

--- Returns the Euclidean distance from this vector to another.
---@param other any
---@return number
function Vec2:distance(other) end

--- Returns the dot product with another vector.
---@param other any
---@return number
function Vec2:dot(other) end

--- Returns the Euclidean length of the vector.
---@return number
function Vec2:length() end

--- Returns the squared length of the vector (faster than length).
---@return number
function Vec2:lengthSquared() end

--- Returns a linearly interpolated vector between this and other at parameter t.
---@param other any
---@param t any
---@return nil
function Vec2:lerp(other, t) end

--- Returns a unit-length copy of this vector. Returns zero if length is zero.
---@return nil
function Vec2:normalize() end

--- Compatibility alias for `normalize`.
---@return nil
function Vec2:normalized() end

--- Returns the perpendicular vector (-y, x).
---@return nil
function Vec2:perpendicular() end

--- Reflects this vector off a surface with the given normal.
---@param normal any
---@return Vec2
function Vec2:reflect(normal) end

--- Returns a new vector rotated by the given angle in radians.
---@param angle any
---@return nil
function Vec2:rotate(angle) end

--- Returns the horizontal component of the vector.
---@return number
function Vec2:x() end

--- Returns the vertical component of the vector.
---@return number
function Vec2:y() end

--- Lua-side wrapper around a [`Vec3`] value type.
---@class Vec3
local Vec3 = {}

--- Add another Vec3 and return the result.
---@param other any
---@return nil
function Vec3:add(other) end

--- Cross product with another Vec3.
---@param other any
---@return nil
function Vec3:cross(other) end

--- Euclidean distance to another Vec3.
---@param other any
---@return number
function Vec3:distance(other) end

--- Dot product with another Vec3.
---@param other any
---@return number
function Vec3:dot(other) end

--- Returns the Euclidean length of the vector.
---@return number
function Vec3:length() end

--- Returns the squared Euclidean length (avoids sqrt).
---@return number
function Vec3:lengthSquared() end

--- Linear interpolation towards another Vec3.
---@param other any
---@param t any
---@return nil
function Vec3:lerp(other, t) end

--- Returns a unit-length version of this vector.
---@return nil
function Vec3:normalize() end

--- Scale this vector by a scalar and return the result.
---@param s any
---@return nil
function Vec3:scale(s) end

--- Subtract another Vec3 and return the result.
---@param other any
---@return nil
function Vec3:sub(other) end

--- Compatibility alias for `vec2`.
---@param x any
---@param y any
function lurek.math.Vec2(x, y) end

--- Compatibility alias for `vec3`.
---@param x any
---@param y any
---@param z any
function lurek.math.Vec3(x, y, z) end

--- Creates a new empty AABB tree for efficient broad-phase overlap queries.
---@return AabbTree
function lurek.math.aabbTree() end

--- Returns the absolute value of x.
---@param x any
---@return number
function lurek.math.abs(x) end

--- Returns the arccosine of x, in radians.
---@param x any
---@return number
function lurek.math.acos(x) end

--- Returns the angle in radians from (x1, y1) to (x2, y2).
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@return number
function lurek.math.angleBetween(x1, y1, x2, y2) end

--- Applies a named easing function to progress value t.
---@param name any
---@param t any
---@return number
function lurek.math.applyEasing(name, t) end

--- Returns the arcsine of x, in radians.
---@param x any
---@return number
function lurek.math.asin(x) end

--- Returns the arctangent of x (or atan2(y, x) when two args given).
---@param y any
---@param x? any (optional)
---@return number
function lurek.math.atan(y, x) end

--- Returns atan(y/x) using the signs of both args to determine the quadrant.
---@param y any
---@param x any
---@return number
function lurek.math.atan2(y, x) end

--- Rasterizes a line from (x1,y1) to (x2,y2) using Bresenham's algorithm. Returns a table of {x,y} tables.
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@return table
function lurek.math.bresenham(x1, y1, x2, y2) end

--- Creates a Catmull-Rom spline through the given control points.
---@param points any
---@return CatmullRomSpline
function lurek.math.catmullRom(points) end

--- Returns the smallest integer ≥ x.
---@param x any
---@return number
function lurek.math.ceil(x) end

--- Returns true if the point (px, py) lies inside the circle.
---@param cx any
---@param cy any
---@param r any
---@param px any
---@param py any
---@return boolean
function lurek.math.circleContainsPoint(cx, cy, r, px, py) end

--- Returns true if two circles overlap.
---@param x1 any
---@param y1 any
---@param r1 any
---@param x2 any
---@param y2 any
---@param r2 any
---@return boolean
function lurek.math.circleIntersectsCircle(x1, y1, r1, x2, y2, r2) end

--- Tests an infinite line against a circle. Returns hit, then two optional hit-point pairs.
---@param cx any
---@param cy any
---@param r any
---@param lx1 any
---@param ly1 any
---@param lx2 any
---@param ly2 any
---@return table
function lurek.math.circleIntersectsLine(cx, cy, r, lx1, ly1, lx2, ly2) end

--- Tests a line segment against a circle. Returns hit, then two optional hit-point pairs.
---@param cx any
---@param cy any
---@param r any
---@param sx1 any
---@param sy1 any
---@param sx2 any
---@param sy2 any
---@return table
function lurek.math.circleIntersectsSegment(cx, cy, r, sx1, sy1, sx2, sy2) end

--- Returns x clamped to [lo, hi].
---@param x any
---@param lo any
---@param hi any
---@return number
function lurek.math.clamp(x, lo, hi) end

--- Clamps `v` between `min` and `max`.
---@param v any
---@param min any
---@param max any
---@return number
function lurek.math.clamp(v, min, max) end

--- Returns the closest point on segment (x1,y1)-(x2,y2) to point (px,py).
---@param px any
---@param py any
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@return number
function lurek.math.closestPointOnSegment(px, py, x1, y1, x2, y2) end

--- Computes the convex hull of a flat {x1,y1,...} point list. Returns a flat table.
---@param pts any
---@return table
function lurek.math.convexHull(pts) end

--- Returns the cosine of x (radians).
---@param x any
---@return number
function lurek.math.cos(x) end

--- Converts radians to degrees.
---@param rad any
---@return number
function lurek.math.deg(rad) end

--- Delaunay triangulation of a flat {x1,y1,...} point list. Returns a table of flat 6-number triangle tables.
---@param pts any
---@return table
function lurek.math.delaunayTriangulate(pts) end

--- Returns the Euclidean distance between (x1,y1) and (x2,y2).
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@return number
function lurek.math.distance(x1, y1, x2, y2) end

--- Returns the squared Euclidean distance between (x1,y1) and (x2,y2) (avoids sqrt).
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@return number
function lurek.math.distanceSq(x1, y1, x2, y2) end

--- Returns e raised to the power x.
---@param x any
---@return number
function lurek.math.exp(x) end

--- Returns fractal Brownian motion noise at (x, y).
---@param x number
---@param y number
---@param seed? integer? (optional)
---@param octaves? integer? (optional)
---@param lacunarity? number? (optional)
---@param gain? number? (optional)
---@return number
function lurek.math.fbm(x, y, seed, octaves, lacunarity, gain) end

--- Returns the largest integer ≤ x.
---@param x any
---@return number
function lurek.math.floor(x) end

--- Returns the remainder of x / y (fmod).
---@param x any
---@param y any
---@return number
function lurek.math.fmod(x, y) end

--- Parses a hex color string (#RRGGBB or #RRGGBBAA) into (r, g, b, a) floats.
---@param hex any
---@return number
function lurek.math.fromHex(hex) end

--- Converts a gamma-encoded sRGB value to linear space.
---@param c any
---@return number
function lurek.math.gammaToLinear(c) end

--- Creates a Hermite spline defined by two endpoints and tangents.
---@param p0x any
---@param p0y any
---@param p1x any
---@param p1y any
---@param m0x any
---@param m0y any
---@param m1x any
---@param m1y any
---@return HermiteSpline
function lurek.math.hermite(p0x, p0y, p1x, p1y, m0x, m0y, m1x, m1y) end

--- Converts HSL (h: 0-360, s: 0-1, l: 0-1) to RGBA (r, g, b, a) floats.
---@param h any
---@param s any
---@param l any
---@return number
function lurek.math.hslToRgb(h, s, l) end

--- Back ease-in — overshoots slightly before settling at the target.
---@param t any
---@return number
function lurek.math.inBack(t) end

--- Bounce ease-in — reverse bounce effect that accelerates into the motion.
---@param t any
---@return number
function lurek.math.inBounce(t) end

--- Cubic ease-in — acceleration starts slowly then increases sharply.
---@param t any
---@return number
function lurek.math.inCubic(t) end

--- Elastic ease-in — spring-like overshoot at the beginning of the motion.
---@param t any
---@return number
function lurek.math.inElastic(t) end

--- Exponential ease-in — very slow start that accelerates sharply near the end.
---@param t any
---@return number
function lurek.math.inExpo(t) end

--- Back ease-in-out — overshoot on both ends.
---@param t any
---@return number
function lurek.math.inOutBack(t) end

--- Bounce ease-in-out — bouncing motion on both ends.
---@param t any
---@return number
function lurek.math.inOutBounce(t) end

--- Cubic ease-in-out — slow start and end with fast cubic middle.
---@param t any
---@return number
function lurek.math.inOutCubic(t) end

--- Elastic ease-in-out — spring-like oscillation on both ends.
---@param t any
---@return number
function lurek.math.inOutElastic(t) end

--- Exponential ease-in-out — very slow start and end with an exponential surge.
---@param t any
---@return number
function lurek.math.inOutExpo(t) end

--- Quadratic ease-in-out — slow start, fast middle, slow end.
---@param t any
---@return number
function lurek.math.inOutQuad(t) end

--- Quartic ease-in-out — very slow start and end with a sharp middle peak.
---@param t any
---@return number
function lurek.math.inOutQuart(t) end

--- Sinusoidal ease-in-out — smooth S-curve based on cosine interpolation.
---@param t any
---@return number
function lurek.math.inOutSine(t) end

--- Quadratic ease-in — acceleration that starts at zero and increases.
---@param t any
---@return number
function lurek.math.inQuad(t) end

--- Quartic ease-in — strongly delayed acceleration using a power-of-4 curve.
---@param t any
---@return number
function lurek.math.inQuart(t) end

--- Sinusoidal ease-in — gentle acceleration based on a sine curve.
---@param t any
---@return number
function lurek.math.inSine(t) end

--- Returns the interpolation parameter t for `v` in [a, b].
---@param a any
---@param b any
---@param v any
---@return number
function lurek.math.inverseLerp(a, b, v) end

--- Returns true if the polygon (flat table {x1,y1,...}) is convex.
---@param pts any
---@return boolean
function lurek.math.isConvex(pts) end

--- Linear interpolation between a and b by fraction t.
---@param a any
---@param b any
---@param t any
---@return number
function lurek.math.lerp(a, b, t) end

--- Linear interpolation between two numbers: a + (b - a) * t.
---@param a any
---@param b any
---@param t any
---@return number
function lurek.math.lerp(a, b, t) end

--- Infinite line intersection. Returns (x, y) or (nil, nil) if lines are parallel.
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@param x3 any
---@param y3 any
---@param x4 any
---@param y4 any
---@return table
function lurek.math.lineIntersect(x1, y1, x2, y2, x3, y3, x4, y4) end

--- Linear easing (identity).
---@param t any
---@return number
function lurek.math.linear(t) end

--- Converts a linear-space value to gamma-encoded sRGB.
---@param c any
---@return number
function lurek.math.linearToGamma(c) end

--- Returns the natural log of x, or log base b if b is supplied.
---@param x any
---@param b? any (optional)
---@return number
function lurek.math.log(x, b) end

--- Returns the largest of the supplied numbers.
---@return number
function lurek.math.max() end

--- Returns the smallest of the supplied numbers.
---@return number
function lurek.math.min() end

--- Creates a new BezierCurve from a flat table of coordinates {x1,y1, x2,y2, ...}.
---@param points any
---@return BezierCurve
function lurek.math.newBezierCurve(points) end

--- Creates a new Circle value type with the given centre and radius.
---@param x any
---@param y any
---@param radius any
---@return Circle
function lurek.math.newCircle(x, y, radius) end

--- Creates a new seeded noise generator.
---@param seed? any (optional)
---@return NoiseGenerator
function lurek.math.newNoiseGenerator(seed) end

--- Creates a new random number generator with an optional seed.
---@param seed? any (optional)
---@return RandomGenerator
function lurek.math.newRandomGenerator(seed) end

--- Creates a new SpatialHash with the given cell size.
---@param cell_size any
---@return SpatialHash
function lurek.math.newSpatialHash(cell_size) end

--- Creates a new Transform, optionally initialised from full parameters.
---@param x? number? (optional)
---@param y? number? (optional)
---@param angle? number? (optional)
---@param sx? number? (optional)
---@param sy? number? (optional)
---@param ox? number? (optional)
---@param oy? number? (optional)
---@param kx? number? (optional)
---@param ky? number? (optional)
---@return Transform
function lurek.math.newTransform(x, y, angle, sx, sy, ox, oy, kx, ky) end

--- Creates a new Tween with the given duration and easing name.
---@param duration any
---@param easing_name? any (optional)
---@return Tween
function lurek.math.newTween(duration, easing_name) end

--- Back ease-out — overshoots the target then snaps back into place.
---@param t any
---@return number
function lurek.math.outBack(t) end

--- Bounce ease-out — simulates a ball bouncing against the target value.
---@param t any
---@return number
function lurek.math.outBounce(t) end

--- Cubic ease-out — rapid deceleration using a cubic power curve.
---@param t any
---@return number
function lurek.math.outCubic(t) end

--- Elastic ease-out — spring-like oscillation that settles at the target.
---@param t any
---@return number
function lurek.math.outElastic(t) end

--- Exponential ease-out — sharp initial speed that decelerates exponentially.
---@param t any
---@return number
function lurek.math.outExpo(t) end

--- Quadratic ease-out — deceleration that starts fast and ends at zero.
---@param t any
---@return number
function lurek.math.outQuad(t) end

--- Quartic ease-out — rapid deceleration using a power-of-4 curve.
---@param t any
---@return number
function lurek.math.outQuart(t) end

--- Sinusoidal ease-out — gentle deceleration based on a cosine curve.
---@param t any
---@return number
function lurek.math.outSine(t) end

--- Returns 2D Perlin noise at (x, y) with the given seed.
---@param x any
---@param y any
---@param seed? any (optional)
---@return number
function lurek.math.perlin2d(x, y, seed) end

--- Returns 3D Perlin noise at (x, y, z) with the given seed.
---@param x any
---@param y any
---@param z any
---@param seed? any (optional)
---@return number
function lurek.math.perlin3d(x, y, z, seed) end

--- Returns true if (px, py) is inside the polygon given as a flat {x1,y1,...} table.
---@param pts any
---@param px any
---@param py any
---@return boolean
function lurek.math.pointInPolygon(pts, px, py) end

--- Returns the signed area of a polygon given as a flat {x1,y1,...} table.
---@param pts any
---@return number
function lurek.math.polygonArea(pts) end

--- Returns the centroid (cx, cy) of a polygon given as a flat {x1,y1,...} table.
---@param pts any
---@return number
function lurek.math.polygonCentroid(pts) end

--- Clips a polygon against a single half-plane using the Sutherland-Hodgman algorithm.
---@param pts any
---@param nx any
---@param ny any
---@param d any
---@return table
function lurek.math.polygonClip(pts, nx, ny, d) end

--- Computes the approximate difference `A - B` (the part of A not covered by B).
---@param a any
---@param b any
---@return table
function lurek.math.polygonDifference(a, b) end

--- Computes the intersection of two convex polygons using the Sutherland-Hodgman
---@param a any
---@param b any
---@return table
function lurek.math.polygonIntersection(a, b) end

--- Computes the approximate union of two convex polygons as the convex hull of
---@param a any
---@param b any
---@return table
function lurek.math.polygonUnion(a, b) end

--- Returns x raised to the power y.
---@param x any
---@param y any
---@return number
function lurek.math.pow(x, y) end

--- Converts degrees to radians.
---@param deg any
---@return number
function lurek.math.rad(deg) end

--- Returns a pseudo-random number in [0,1) with no args,
---@param a? any (optional)
---@param b? any (optional)
---@return number
function lurek.math.random(a, b) end

--- Returns a pseudo-random integer in [lo, hi] (inclusive).
---@param lo any
---@param hi any
---@return integer
function lurek.math.randomInt(lo, hi) end

--- Creates a rectangle centered at (cx, cy) with the given width and height.
---@param cx any
---@param cy any
---@param w any
---@param h any
---@return number
function lurek.math.rectFromCenter(cx, cy, w, h) end

--- Returns the union (bounding box) of two rectangles.
---@param x1 any
---@param y1 any
---@param w1 any
---@param h1 any
---@param x2 any
---@param y2 any
---@param w2 any
---@param h2 any
---@return number
function lurek.math.rectUnion(x1, y1, w1, h1, x2, y2, w2, h2) end

--- Remaps `v` from [in_min, in_max] to [out_min, out_max].
---@param v any
---@param in_min any
---@param in_max any
---@param out_min any
---@param out_max any
---@return number
function lurek.math.remap(v, in_min, in_max, out_min, out_max) end

--- Converts RGBA floats to HSL (h: 0-360, s: 0-1, l: 0-1).
---@param r any
---@param g any
---@param b any
---@return number
function lurek.math.rgbToHsl(r, g, b) end

--- Returns x rounded to the nearest integer (half-up).
---@param x any
---@return number
function lurek.math.round(x) end

--- Tests if two line segments intersect. Returns (hit, ix?, iy?).
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@param x3 any
---@param y3 any
---@param x4 any
---@param y4 any
---@return table
function lurek.math.segmentIntersectsSegment(x1, y1, x2, y2, x3, y3, x4, y4) end

--- Returns -1, 0, or 1 depending on the sign of x.
---@param x any
---@return number
function lurek.math.sign(x) end

--- Returns -1, 0, or 1 depending on the sign of `v`.
---@param v any
---@return number
function lurek.math.sign(v) end

--- Returns 2D Simplex noise at (x, y) with the given seed.
---@param x any
---@param y any
---@param seed? any (optional)
---@return number
function lurek.math.simplex2d(x, y, seed) end

--- Returns a simplex noise value in [-1, 1] for 2D or 3D coordinates.
---@param x any
---@param y any
---@param z? any (optional)
---@return number
function lurek.math.simplexNoise(x, y, z) end

--- Returns the sine of x (radians).
---@param x any
---@return number
function lurek.math.sin(x) end

--- Hermite smoothstep between `edge0` and `edge1`.
---@param edge0 any
---@param edge1 any
---@param x any
---@return number
function lurek.math.smoothstep(edge0, edge1, x) end

--- Returns the square root of x.
---@param x any
---@return number
function lurek.math.sqrt(x) end

--- Returns the tangent of x (radians).
---@param x any
---@return number
function lurek.math.tan(x) end

--- Triangulates a simple polygon given as a flat table {x1,y1, x2,y2, ...}.
---@param pts any
---@return table
function lurek.math.triangulate(pts) end

--- Creates a 2D vector with x and y components.
---@param x any
---@param y any
function lurek.math.vec2(x, y) end

--- Creates a 3D vector `{x, y, z}` table with numeric components.
---@param x any
---@param y any
---@param z any
function lurek.math.vec3(x, y, z) end

--- Computes the Voronoi diagram for a list of 2-D seed points.
---@param points any
---@return table
function lurek.math.voronoi(points) end

---@class lurek.minimap
lurek.minimap = {}

--- Lua-side wrapper around a [`Minimap`].
---@class Minimap
local Minimap = {}

--- Removes the animation from a marker, reverting it to static.
---@param id any
---@return nil
function Minimap:clearMarkerAnimation(id) end

--- Removes all tracked objects.
---@return nil
function Minimap:clearObjects() end

--- Removes all custom geometry from the minimap overlay.
---@return nil
function Minimap:clearOverlay() end

--- Removes a displayed path. If id is nil, all paths are removed.
---@param id? any (optional)
---@return nil
function Minimap:clearPath(id) end

--- Clears the viewport rectangle overlay.
---@return nil
function Minimap:clearViewportRect() end

--- Renders the minimap grid to a CPU ImageData.
---@param pixel_size any
---@return ImageData
function Minimap:drawToImage(pixel_size) end

--- Returns the center coordinates as x, y.
---@return number
function Minimap:getCenter() end

--- Returns the center X coordinate.
---@return number
function Minimap:getCenterX() end

--- Returns the center Y coordinate.
---@return number
function Minimap:getCenterY() end

--- Returns the current color mode as a string.
---@return string
function Minimap:getColorMode() end

--- Returns the display height in pixels.
---@return integer
function Minimap:getDisplayHeight() end

--- Returns the display width and height as two values.
---@return integer
function Minimap:getDisplaySize() end

--- Returns the display width in pixels.
---@return integer
function Minimap:getDisplayWidth() end

--- Returns the fog overlay color as r, g, b, a.
---@return number
function Minimap:getFogColor() end

--- Returns the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
---@param x any
---@param y any
---@return integer
function Minimap:getFogLevel(x, y) end

--- Returns the grid height in cells.
---@return integer
function Minimap:getGridHeight() end

--- Returns the grid width and height as two values.
---@return integer
function Minimap:getGridSize() end

--- Returns the grid width in cells.
---@return integer
function Minimap:getGridWidth() end

--- Returns the index of the currently active render layer.
---@return integer
function Minimap:getLayer() end

--- Returns the number of markers.
---@return integer
function Minimap:getMarkerCount() end

--- Returns the description of a marker, or nil.
---@param id any
---@return string?
function Minimap:getMarkerDescription(id) end

--- Returns the number of tracked objects.
---@return integer
function Minimap:getObjectCount() end

--- Returns the number of registered object types.
---@return integer
function Minimap:getObjectTypeCount() end

--- Returns the display color for an owner/faction as r, g, b, a.
---@param owner any
---@return number
function Minimap:getOwnerColor(owner) end

--- Returns the number of active pings.
---@return integer
function Minimap:getPingCount() end

--- Returns the terrain type at a 1-based grid position.
---@param x any
---@param y any
---@return integer
function Minimap:getTerrain(x, y) end

--- Returns the display color for a terrain type as r, g, b, a.
---@param terrain_type any
---@return number
function Minimap:getTerrainColor(terrain_type) end

--- Returns the hover tooltip string for a terrain type ID, or nil.
---@param type_id any
---@return string?
function Minimap:getTileDescription(type_id) end

--- Returns the viewport rectangle color as r, g, b, a.
---@return number
function Minimap:getViewportColor() end

--- Returns the viewport rectangle as x, y, w, h or nil if not set.
---@return nil
function Minimap:getViewportRect() end

--- Returns the current zoom level.
---@return number
function Minimap:getZoom() end

--- Returns whether a marker with the given ID exists.
---@param id any
---@return boolean
function Minimap:hasMarker(id) end

--- Returns whether anti-aliasing is enabled.
---@return boolean
function Minimap:isAntiAlias() end

--- Returns whether this minimap responds to click hit-testing.
---@return boolean
function Minimap:isClickable() end

--- Returns whether fog of war is enabled.
---@return boolean
function Minimap:isFogEnabled() end

--- Returns whether an object type (1-based index) is visible.
---@param type_idx any
---@return boolean
function Minimap:isObjectTypeVisible(type_idx) end

--- Returns whether the viewport rectangle is visible.
---@return boolean
function Minimap:isViewportVisible() end

--- Removes the minimap marker with the given integer ID, if present.
---@param id any
---@return boolean
function Minimap:removeMarker(id) end

--- Removes a tracked object by ID.
---@param id any
---@return boolean
function Minimap:removeObject(id) end

--- Renders the minimap to the screen at the given position.
---@param x? any (optional)
---@param y? any (optional)
---@return nil
function Minimap:render(x, y) end

--- Sets whether anti-aliasing is enabled.
---@param enabled any
---@return nil
function Minimap:setAntiAlias(enabled) end

--- Sets the center of the minimap view in grid coordinates.
---@param x any
---@param y any
---@return nil
function Minimap:setCenter(x, y) end

--- Sets whether this minimap responds to click hit-testing.
---@param enabled any
---@return nil
function Minimap:setClickable(enabled) end

--- Sets the color mode ("terrain" or "political").
---@param mode any
---@return nil
function Minimap:setColorMode(mode) end

--- Sets the display size in pixels.
---@param w any
---@param h any
---@return nil
function Minimap:setDisplaySize(w, h) end

--- Sets the entire fog grid from a flat 1-based table (0=hidden, 1=explored, 2=visible).
---@param data any
---@return nil
function Minimap:setFogData(data) end

--- Enables or disables fog of war.
---@param enabled any
---@return nil
function Minimap:setFogEnabled(enabled) end

--- Sets the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
---@param x any
---@param y any
---@param level any
---@return nil
function Minimap:setFogLevel(x, y, level) end

--- Switches the minimap's active render layer (0-based index).
---@param layer any
---@return nil
function Minimap:setLayer(layer) end

--- Sets terrain types from a flat 1-based Lua table of integers (row-major).
---@param data any
---@return nil
function Minimap:setTerrainData(data) end

--- Sets whether the viewport rectangle is visible.
---@param visible any
---@return nil
function Minimap:setViewportVisible(visible) end

--- Sets the zoom level (minimum 0.1).
---@param zoom any
---@return nil
function Minimap:setZoom(zoom) end

--- Returns the type name of this object.
---@return string
function Minimap:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function Minimap:typeOf(name) end

--- Advances time-based effects by dt seconds (expires pings).
---@param dt any
---@return nil
function Minimap:update(dt) end

--- Creates a new grid-based minimap.
---@param grid_w any
---@param grid_h any
---@param display_w? any (optional)
---@param display_h? any (optional)
---@return Minimap
function lurek.minimap.newMinimap(grid_w, grid_h, display_w, display_h) end

---@class lurek.mods
lurek.mods = {}

--- A typed content registry for mod-contributed assets and objects.
---@class ContentRegistry
local ContentRegistry = {}

--- Retrieve a content entry.
---@param type_name any
---@param id any
---@return any
function ContentRegistry:get(type_name, id) end

--- Get all entries for a type.
---@param type_name any
---@return table
function ContentRegistry:getAll(type_name) end

--- Get all registered type names.
---@return table
function ContentRegistry:getTypes() end

--- Register a content entry.
---@param type_name any
---@param id any
---@param obj any
---@return nil
function ContentRegistry:register(type_name, id, obj) end

--- Register a new content type.
---@param type_name any
---@return nil
function ContentRegistry:registerType(type_name) end

--- Lua-side wrapper around [`ModInfo`] with per-mod hook and config storage.
---@class Mod
local Mod = {}

--- Returns the required engine API version string, or nil if not set
---@return string?
function Mod:getApiVersion() end

--- Returns the author name string from this mod's metadata manifest
---@return string
function Mod:getAuthor() end

--- Returns an array of declared capability flags
---@return table
function Mod:getCapabilities() end

--- Returns the stored config value, or nil
---@return table?
function Mod:getConfig() end

--- Returns the config schema as an array of `{key, type, default}` tables.
---@return table
function Mod:getConfigSchema() end

--- Returns the list of required mod IDs
---@return table
function Mod:getDependencies() end

--- Returns the mod description
---@return string
function Mod:getDescription() end

--- Returns the hook function for the given name, or nil
---@param name any
---@return function?
function Mod:getHook(name) end

--- Returns an array of registered hook names
---@return table
function Mod:getHookNames() end

--- Returns the unique mod identifier
---@return string
function Mod:getId() end

--- Returns the localized or human-readable display name of the mod.
---@return string
function Mod:getName() end

--- Returns the load-order priority
---@return integer
function Mod:getPriority() end

--- Returns the version string
---@return string
function Mod:getVersion() end

--- Returns whether a hook with the given name exists
---@param name any
---@return boolean
function Mod:hasHook(name) end

--- Returns whether the mod is enabled
---@return boolean
function Mod:isEnabled() end

--- Returns whether the mod has been loaded
---@return boolean
function Mod:isLoaded() end

--- Releases all hook and config registry references
---@return nil
function Mod:releaseRefs() end

--- Sets the required engine API version string
---@param api_version any
---@return nil
function Mod:setApiVersion(api_version) end

--- Replaces the capability list with the given array of strings
---@param caps any
---@return nil
function Mod:setCapabilities(caps) end

--- Stores an arbitrary config value for this mod
---@param value any
---@return nil
function Mod:setConfig(value) end

--- Replaces the config schema with the given array of `{key, type, default}` tables.
---@param schema any
---@return nil
function Mod:setConfigSchema(schema) end

--- Enables or disables this mod; disabled mods are skipped during loading
---@param enabled any
---@return nil
function Mod:setEnabled(enabled) end

--- Lua-side wrapper around [`ModManager`].
---@class ModManager
local ModManager = {}

--- Clears the custom load order, reverting to priority-based sorting
---@return nil
function ModManager:clearLoadOrder() end

--- Clears the reload queue without reloading
---@return nil
function ModManager:clearReloadQueue() end

--- Returns an array of info tables for all registered mods
---@return table
function ModManager:getAllMods() end

--- Returns an array of info tables in effective load order
---@return table
function ModManager:getLoadOrder() end

--- Returns the number of registered mods
---@return integer
function ModManager:getModCount() end

--- Returns the filesystem path of a registered mod, or nil
---@param mod_id any
---@return string?
function ModManager:getModPath(mod_id) end

--- Returns the array of mod IDs pending hot-reload
---@return table
function ModManager:getReloadQueue() end

--- Returns whether any circular dependency cycles exist
---@return boolean
function ModManager:hasCircularDependencies() end

--- Returns whether a mod with the given ID is registered
---@param mod_id any
---@return boolean
function ModManager:hasMod(mod_id) end

--- Marks a registered mod for hot-reload
---@param mod_id any
---@return boolean
function ModManager:markForReload(mod_id) end

--- Registers a mod from its Mod userdata
---@param ud any
---@return nil
function ModManager:registerMod(ud) end

--- Scans a directory for mods with mod.toml and registers them
---@param path any
---@return table
function ModManager:scanFolder(path) end

--- Sets an explicit load order from an array of mod ID strings
---@param order_table any
---@return nil
function ModManager:setLoadOrder(order_table) end

--- Removes a mod by ID and returns whether it was found
---@param mod_id any
---@return boolean
function ModManager:unregisterMod(mod_id) end

--- Returns an array of mod IDs with missing dependencies
---@return table
function ModManager:validateDependencies() end

--- Checks whether a mod's required `api_version` is compatible with the given `host_version`.
---@param mod_ud any
---@param host_version any
---@return table|nil
function lurek.mods.checkApiVersion(mod_ud, host_version) end

--- Creates a new Mod from an info table with at least an `id` field.
---@param info any
---@return Mod
function lurek.mods.newMod(info) end

--- Creates a new empty ModManager.
---@return ModManager
function lurek.mods.newModManager() end

--- Creates a new empty ContentRegistry for mod-contributed assets.
---@return ContentRegistry
function lurek.mods.newRegistry() end

---@class lurek.network
lurek.network = {}

--- Lua-side wrapper around [`NetworkHost`].
---@class NetworkHost
local NetworkHost = {}

--- Destroys the host, closing the underlying socket.
---@return nil
function NetworkHost:destroy() end

--- Flushes all pending sends immediately.
---@return nil
function NetworkHost:flush() end

--- Returns the local bind address as a string.
---@return string
function NetworkHost:getAddress() end

--- Returns the bandwidth limits as a table with incoming and outgoing fields.
---@return table
function NetworkHost:getBandwidthLimit() end

--- Returns the maximum number of channels per connection.
---@return integer
function NetworkHost:getChannelLimit() end

--- Returns the number of currently connected peers.
---@return integer
function NetworkHost:getConnectedPeerCount() end

--- Returns a table of connected peer IDs.
---@return table
function NetworkHost:getConnectedPeerIds() end

--- Returns the remote address of a peer, or nil if unavailable.
---@param peer_id any
---@return string?
function NetworkHost:getPeerAddress(peer_id) end

--- Returns the maximum number of peer slots.
---@return integer
function NetworkHost:getPeerLimit() end

--- Returns the connection state of a peer as a string.
---@param peer_id any
---@return string
function NetworkHost:getPeerState(peer_id) end

--- Returns a statistics table for a peer.
---@param peer_id any
---@return table
function NetworkHost:getPeerStats(peer_id) end

--- Returns the multiplayer role of this host ("server", "client", or "host").
---@return string
function NetworkHost:getRole() end

--- Returns the round-trip time estimate for a peer in milliseconds.
---@param peer_id any
---@return number
function NetworkHost:getRoundTripTime(peer_id) end

--- Returns true if this host was created as a client.
---@return boolean
function NetworkHost:isClient() end

--- Returns true if the host has been destroyed.
---@return boolean
function NetworkHost:isDestroyed() end

--- Returns true if this host was created as a server.
---@return boolean
function NetworkHost:isServer() end

--- Sends a ping to a peer to measure round-trip time.
---@param peer_id any
---@return nil
function NetworkHost:ping(peer_id) end

--- Resets a peer connection immediately without notifying the remote side.
---@param peer_id any
---@return nil
function NetworkHost:resetPeer(peer_id) end

--- Polls the network for one event, returning an event table or nil.
---@return table?
function NetworkHost:service() end

--- Sets the channel limit for future connections.
---@param limit any
---@return nil
function NetworkHost:setChannelLimit(limit) end

--- Lua-side wrapper around [`NetworkRuntime`] for async HTTP/TCP/WebSocket.
---@class NetworkRuntime
local NetworkRuntime = {}

--- Sends an HTTP request asynchronously. Poll with `poll()` for the response.
---@param opts any
---@return nil
function NetworkRuntime:httpRequest(opts) end

--- Polls for completed async responses (HTTP, TCP events, WebSocket events).
---@return table
function NetworkRuntime:poll() end

--- Shuts down the background network thread.
---@return nil
function NetworkRuntime:shutdown() end

--- Closes the TCP connection identified by the given connection handle.
---@param id any
---@return nil
function NetworkRuntime:tcpClose(id) end

--- Opens a TCP connection to a remote address.
---@param addr any
---@return nil
function NetworkRuntime:tcpConnect(addr) end

--- Sends data over a TCP connection.
---@param id any
---@param data any
---@return nil
function NetworkRuntime:tcpSend(id, data) end

--- Closes a WebSocket connection.
---@param id any
---@return nil
function NetworkRuntime:wsClose(id) end

--- Opens a WebSocket connection.
---@param url any
---@return nil
function NetworkRuntime:wsConnect(url) end

--- Sends a text message over a WebSocket connection.
---@param id any
---@param data any
---@return nil
function NetworkRuntime:wsSend(id, data) end

--- Creates a LobbyInfo record and broadcasts it once on the local network.
---@param name any
---@param port any
---@param player_count? any (optional)
---@param max_players? any (optional)
---@return table|nil
function lurek.network.createLobby(name, port, player_count, max_players) end

--- Listens for LAN lobby announcements for `timeout_ms` milliseconds (default 500).
---@param timeout_ms? any (optional)
---@return table|nil
function lurek.network.discoverLobbies(timeout_ms) end

--- Creates a client host that connects to a remote server.
---@param opts any
---@return NetworkHost
function lurek.network.newClient(opts) end

--- Creates a new network host bound to the given address.
---@param opts any
---@return NetworkHost
function lurek.network.newHost(opts) end

--- Creates a background network runtime for async HTTP, TCP, and WebSocket.
---@return NetworkRuntime
function lurek.network.newRuntime() end

--- Creates a server host that binds to a port and accepts connections.
---@param opts any
---@return NetworkHost
function lurek.network.newServer(opts) end

--- Serializes a Lua value to a binary MessagePack string.
---@param value any
---@return string
function lurek.network.pack(value) end

--- Convenience helper: packs an entity snapshot and broadcasts it to all peers.
---@param host NetworkHost
---@param entity_id integer
---@param data table
---@param channel? integer? (optional)
---@param reliable? boolean? (optional)
---@return nil
function lurek.network.syncEntity(host, entity_id, data, channel, reliable) end

--- Deserializes a MessagePack binary string back to a Lua value.
---@param data any
---@return table|nil
function lurek.network.unpack(data) end

---@class lurek.parallax
lurek.parallax = {}

--- Lua-side handle to a single parallax background layer.
---@class ParallaxLayer
local ParallaxLayer = {}

--- Removes scroll clamping so the layer scrolls freely.
---@return nil
function ParallaxLayer:clearClamp() end

--- Returns the autoscroll velocity as `(vx, vy)`.
---@return number
function ParallaxLayer:getAutoscroll() end

--- Returns the current blend mode as a string.
---@return string
function ParallaxLayer:getBlendMode() end

--- Returns the current floating-point depth.
---@return number
function ParallaxLayer:getDepth() end

--- Returns the static offset as `(x, y)`.
---@return number
function ParallaxLayer:getOffset() end

--- Returns the current opacity.
---@return number
function ParallaxLayer:getOpacity() end

--- Returns the scroll factor as `(x, y)`.
---@return number
function ParallaxLayer:getScrollFactor() end

--- Returns `true` if seamless infinite tiling is enabled.
---@return boolean
function ParallaxLayer:getTiling() end

--- Returns the current tint as `(r, g, b, a)`.
---@return number
function ParallaxLayer:getTint() end

--- Returns the draw-order depth.
---@return integer
function ParallaxLayer:getZ() end

--- Returns `true` if the layer is currently visible.
---@return boolean
function ParallaxLayer:isVisible() end

--- Draws the layer using an explicit camera world position.
---@param cam_x any
---@param cam_y any
---@return nil
function ParallaxLayer:render(cam_x, cam_y) end

--- Draws the layer using the engine active camera position automatically.
---@return nil
function ParallaxLayer:renderAuto() end

--- Resets the autonomous scroll accumulator to zero.
---@return nil
function ParallaxLayer:resetAutoscroll() end

--- Sets the autonomous scroll velocity in world-pixels per second.
---@param vx any
---@param vy any
---@return nil
function ParallaxLayer:setAutoscroll(vx, vy) end

--- Sets the GPU blend mode for this layer.
---@param mode any
---@return nil
function ParallaxLayer:setBlendMode(mode) end

--- Sets the floating-point draw depth for fine-grained layer ordering.
---@param z any
---@return nil
function ParallaxLayer:setDepth(z) end

--- Sets the static world-pixel position bias added on top of camera scroll.
---@param x any
---@param y any
---@return nil
function ParallaxLayer:setOffset(x, y) end

--- Sets the layer-wide opacity override in `[0.0, 1.0]`.
---@param a any
---@return nil
function ParallaxLayer:setOpacity(a) end

--- Sets whether the layer tiles on the X and Y axes.
---@param rx any
---@param ry any
---@return nil
function ParallaxLayer:setRepeat(rx, ry) end

--- Sets the texture display scale factor on each axis.
---@param sx any
---@param sy any
---@return nil
function ParallaxLayer:setScale(sx, sy) end

--- Sets the scroll factor relative to camera movement on each axis.
---@param x any
---@param y any
---@return nil
function ParallaxLayer:setScrollFactor(x, y) end

--- Sets explicit tile dimensions in logical pixels, overriding the default
---@param w any
---@param h any
---@return nil
function ParallaxLayer:setTileSize(w, h) end

--- Enables or disables seamless infinite tiling on both axes simultaneously.
---@param enabled any
---@return nil
function ParallaxLayer:setTiling(enabled) end

--- Sets the multiplicative RGBA tint applied to all pixels of this layer.
---@param r any
---@param g any
---@param b any
---@param a any
---@return nil
function ParallaxLayer:setTint(r, g, b, a) end

--- Shows or hides this layer.
---@param v any
---@return nil
function ParallaxLayer:setVisible(v) end

--- Sets the draw-order depth. Lower values render first (further back).
---@param z any
---@return nil
function ParallaxLayer:setZ(z) end

--- Returns the type name of this object.
---@return string
function ParallaxLayer:type() end

--- Advances the autonomous scroll accumulator by `dt` seconds.
---@param dt any
---@return nil
function ParallaxLayer:update(dt) end

--- Lua-side container that groups `LuaParallaxLayer` objects for scene-level management.
---@class ParallaxSet
local ParallaxSet = {}

--- Adds a layer to this set.
---@param layer any
---@return nil
function ParallaxSet:addLayer(layer) end

--- Returns the name of this set.
---@return string
function ParallaxSet:getName() end

--- Returns `true` if the set is currently visible.
---@return boolean
function ParallaxSet:isVisible() end

--- Returns the number of layers in this set.
---@return integer
function ParallaxSet:layerCount() end

--- Removes the layer at the given 1-based index.
---@param index any
---@return boolean
function ParallaxSet:removeLayerAt(index) end

--- Draws all visible layers in ascending `z` order using an explicit camera position.
---@param cam_x any
---@param cam_y any
---@return nil
function ParallaxSet:render(cam_x, cam_y) end

--- Draws all visible layers using the engine active camera position.
---@return nil
function ParallaxSet:renderAuto() end

--- Sets the name of this set.
---@param name any
---@return nil
function ParallaxSet:setName(name) end

--- Shows or hides all layers in this set.
---@param v any
---@return nil
function ParallaxSet:setVisible(v) end

--- Re-sorts all layers by ascending `z` value.
---@return nil
function ParallaxSet:sortByZ() end

--- Returns the type name of this object.
---@return string
function ParallaxSet:type() end

--- Advances the autoscroll accumulator of every layer by `dt` seconds.
---@param dt any
---@return nil
function ParallaxSet:update(dt) end

--- Creates a new parallax background layer from an options table.
---@param opts any
---@return LuaParallaxLayer
function lurek.parallax.newLayer(opts) end

--- Creates a new empty parallax set with the given name.
---@param name any
---@return LuaParallaxSet
function lurek.parallax.newSet(name) end

---@class lurek.particle
lurek.particle = {}

--- Lua-side handle to a particle system stored in SharedState.
---@class ParticleSystem
local ParticleSystem = {}

--- Adds a child emitter that updates and renders with this system.
---@param config_tbl any
---@return index
function ParticleSystem:addSubSystem(config_tbl) end

--- Removes all attractors from this particle system.
---@return nil
function ParticleSystem:clearAttractors() end

--- Removes the bounding rectangle so particles can move freely.
---@return nil
function ParticleSystem:clearBounds() end

--- Creates a copy of this particle system (config only, no live particles).
---@return ParticleSystem
function ParticleSystem:clone() end

--- Returns the number of living particles.
---@return integer
function ParticleSystem:count() end

--- Renders all live particles to a CPU ImageData.
---@param w any
---@param h any
---@return ImageData
function ParticleSystem:drawToImage(w, h) end

--- Emits a burst of the given number of particles.
---@param count any
---@return nil
function ParticleSystem:emit(count) end

--- Returns the number of attractors currently registered on this system.
---@return integer
function ParticleSystem:getAttractorCount() end

--- Returns the maximum particle count.
---@return integer
function ParticleSystem:getBufferSize() end

--- Returns color keyframes as a table of {r,g,b,a} tables.
---@return table
function ParticleSystem:getColors() end

--- Returns the number of living particles (alias for count).
---@return integer
function ParticleSystem:getCount() end

--- Returns emission direction in radians.
---@return number
function ParticleSystem:getDirection() end

--- Returns emission area: dist-string, w, h.
---@return nil
function ParticleSystem:getEmissionArea() end

--- Returns particles emitted per second.
---@return number
function ParticleSystem:getEmissionRate() end

--- Returns the emitter lifetime.
---@return number
function ParticleSystem:getEmitterLifetime() end

--- Returns the current flipbook configuration as `(cols, rows, fps)`, or `nil` if not set.
---@return nil
function ParticleSystem:getFlipbook() end

--- Returns the gravity acceleration applied to particles as two numbers `gx, gy`.
---@return number
function ParticleSystem:getGravity() end

--- Returns the insert mode as a string.
---@return string
function ParticleSystem:getInsertMode() end

--- Returns linear acceleration range.
---@return number
function ParticleSystem:getLinearAcceleration() end

--- Returns linear damping range.
---@return number
function ParticleSystem:getLinearDamping() end

--- Returns the render origin offset.
---@return number
function ParticleSystem:getOffset() end

--- Returns min and max particle lifetime.
---@return number
function ParticleSystem:getParticleLifetime() end

--- Returns the emitter world position.
---@return number
function ParticleSystem:getPosition() end

--- Returns radial acceleration range.
---@return number
function ParticleSystem:getRadialAcceleration() end

--- Returns initial rotation range.
---@return number
function ParticleSystem:getRotation() end

--- Returns the particle draw shape as a string.
---@return string
function ParticleSystem:getShape() end

--- Returns the maximum random size variation applied to newly emitted particles.
---@return number
function ParticleSystem:getSizeVariation() end

--- Returns size keyframes as a Lua table.
---@return table
function ParticleSystem:getSizes() end

--- Returns min/max initial speed.
---@return number
function ParticleSystem:getSpeed() end

--- Returns angular velocity range.
---@return number
function ParticleSystem:getSpin() end

--- Returns the maximum random angular velocity variation for new particles.
---@return number
function ParticleSystem:getSpinVariation() end

--- Returns the half-angle spread in radians for the emission cone.
---@return number
function ParticleSystem:getSpread() end

--- Returns tangential acceleration range.
---@return number
function ParticleSystem:getTangentialAcceleration() end

--- Returns whether relative rotation is enabled.
---@return boolean
function ParticleSystem:hasRelativeRotation() end

--- Returns true if the emitter is currently emitting or has live particles.
---@return boolean
function ParticleSystem:isActive() end

--- Returns true if there are no live particles.
---@return boolean
function ParticleSystem:isEmpty() end

--- Returns true if the system has reached max_particles.
---@return boolean
function ParticleSystem:isFull() end

--- Returns true if the emitter is paused.
---@return boolean
function ParticleSystem:isPaused() end

--- Returns true if the emitter is stopped.
---@return boolean
function ParticleSystem:isStopped() end

--- Moves the emitter to the given world position.
---@param x any
---@param y any
---@return nil
function ParticleSystem:moveTo(x, y) end

--- Pauses particle emission; existing particles continue to simulate.
---@return nil
function ParticleSystem:pause() end

--- Removes the particle system from the engine, freeing its slot.
---@return nil
function ParticleSystem:release() end

--- Renders all live particles to the GPU command queue.
---@param ox? any (optional)
---@param oy? any (optional)
---@return nil
function ParticleSystem:render(ox, oy) end

--- Removes all particles and resets the emitter.
---@return nil
function ParticleSystem:reset() end

--- Resumes a paused emitter.
---@return nil
function ParticleSystem:resume() end

--- Sets the maximum number of particles (resizes the pool).
---@param n any
---@return nil
function ParticleSystem:setBufferSize(n) end

--- Sets color keyframes. Each arg is a table {r, g, b, a}.
---@param colors any
---@return nil
function ParticleSystem:setColors(colors) end

--- Sets a Lua function that returns (offset_x, offset_y) for each newly spawned
---@param cb any
---@return nil
function ParticleSystem:setCustomEmissionShape(cb) end

--- Sets emission direction in radians.
---@param dir any
---@return nil
function ParticleSystem:setDirection(dir) end

--- Sets emission area distribution and size.
---@param dist any
---@param w any
---@param h any
---@param angle? any (optional)
---@param dir_rel? any (optional)
---@return nil
function ParticleSystem:setEmissionArea(dist, w, h, angle, dir_rel) end

--- Sets particles emitted per second.
---@param rate any
---@return nil
function ParticleSystem:setEmissionRate(rate) end

--- Sets how long the emitter runs before auto-stopping. Negative = infinite.
---@param t any
---@return nil
function ParticleSystem:setEmitterLifetime(t) end

--- Sets the gravity acceleration applied to all active particles each frame.
---@param gx any
---@param gy any
---@return nil
function ParticleSystem:setGravity(gx, gy) end

--- Sets the insert mode: "top", "bottom", or "random".
---@param mode any
---@return nil
function ParticleSystem:setInsertMode(mode) end

--- Sets linear damping range.
---@param min any
---@param max any
---@return nil
function ParticleSystem:setLinearDamping(min, max) end

--- Sets the render origin offset.
---@param ox any
---@param oy any
---@return nil
function ParticleSystem:setOffset(ox, oy) end

--- Sets a Lua function called after each update() with all particles that died
---@param cb any
---@return nil
function ParticleSystem:setOnDeathBatch(cb) end

--- Sets min and max particle lifetime in seconds.
---@param min any
---@param max any
---@return nil
function ParticleSystem:setParticleLifetime(min, max) end

--- Sets the emitter world position.
---@param x any
---@param y any
---@return nil
function ParticleSystem:setPosition(x, y) end

--- Sets whether particle rotation follows velocity direction.
---@param v any
---@return nil
function ParticleSystem:setRelativeRotation(v) end

--- Sets initial rotation range in radians.
---@param min any
---@param max any
---@return nil
function ParticleSystem:setRotation(min, max) end

--- Sets the particle draw shape.
---@param shape any
---@return nil
function ParticleSystem:setShape(shape) end

--- Sets size variation (0â€“1).
---@param v any
---@return nil
function ParticleSystem:setSizeVariation(v) end

--- Sets size keyframes (varargs: each number is one keyframe).
---@param sizes any
---@return nil
function ParticleSystem:setSizes(sizes) end

--- Sets min/max initial speed.
---@param min any
---@param max any
---@return nil
function ParticleSystem:setSpeed(min, max) end

--- Sets angular velocity range.
---@param min any
---@param max any
---@return nil
function ParticleSystem:setSpin(min, max) end

--- Sets spin variation (0â€“1).
---@param v any
---@return nil
function ParticleSystem:setSpinVariation(v) end

--- Sets emission spread (half-angle cone) in radians.
---@param spread any
---@return nil
function ParticleSystem:setSpread(spread) end

--- Starts or restarts particle emission.
---@return nil
function ParticleSystem:start() end

--- Stops particle emission immediately.
---@return nil
function ParticleSystem:stop() end

--- Returns the number of direct child sub-systems attached to this emitter.
---@return count
function ParticleSystem:subSystemCount() end

--- Alias for `drawToImage`. Renders all live particles to a CPU ImageData.
---@param w any
---@param h any
---@return ImageData
function ParticleSystem:toImage(w, h) end

--- Returns the type name "ParticleSystem".
---@return string
function ParticleSystem:type() end

--- Returns true if this matches the given type name.
---@param name any
---@return boolean
function ParticleSystem:typeOf(name) end

--- Advances the particle simulation by dt seconds.
---@param dt any
---@return nil
function ParticleSystem:update(dt) end

--- Pre-simulates the particle system for `seconds` so it appears fully
---@param seconds any
---@return nil
function ParticleSystem:warmUp(seconds) end

--- Lua-side wrapper around a [`Trail`] ribbon effect.
---@class Trail
local Trail = {}

--- Removes all trail points.
---@return nil
function Trail:clear() end

--- Renders the trail ribbon to a CPU ImageData.
---@param w any
---@param h any
---@return ImageData
function Trail:drawToImage(w, h) end

--- Returns the trail point lifetime in seconds.
---@return number
function Trail:getLifetime() end

--- Returns the number of active trail points.
---@return integer
function Trail:getPointCount() end

--- Returns the start and end width.
---@return number
function Trail:getWidth() end

--- Appends a new point to the trail head.
---@param x any
---@param y any
---@return nil
function Trail:pushPoint(x, y) end

--- Sets how long each trail point persists in seconds.
---@param lifetime any
---@return nil
function Trail:setLifetime(lifetime) end

--- Sets the minimum distance between trail points.
---@param distance any
---@return nil
function Trail:setMinDistance(distance) end

--- Sets the start and end width of the trail ribbon.
---@param start any
---@param end? any (optional)
---@return nil
function Trail:setWidth(start, end) end

--- Ages trail points and removes expired ones.
---@param dt any
---@return nil
function Trail:update(dt) end

--- Creates a new particle system from a TOML config file.
---@param path any
---@return ParticleSystem
function lurek.particle.fromTOML(path) end

--- Creates a new particle system and stores it in the engine pool.
---@param config? any (optional)
---@return ParticleSystem
function lurek.particle.newSystem(config) end

--- Creates a new trail ribbon effect.
---@param lifetime any
---@param start_width any
---@return Trail
function lurek.particle.newTrail(lifetime, start_width) end

---@class lurek.pathfind
lurek.pathfind = {}

--- Lua-side wrapper around a PathGrid-based [`AiFlowField`].
---@class AiFlowField
local AiFlowField = {}

--- Returns the normalised direction toward the goal (1-based coordinates).
---@param x any
---@param y any
---@return number
function AiFlowField:getDirection(x, y) end

--- Returns the BFS distance to the goal (1-based coordinates).
---@param x any
---@param y any
---@return number
function AiFlowField:getDistance(x, y) end

--- Returns the flow field grid height in cells.
---@return integer
function AiFlowField:getHeight() end

--- Returns the flow field grid width in cells.
---@return integer
function AiFlowField:getWidth() end

--- Returns true if a goal has been set.
---@return boolean
function AiFlowField:hasGoal() end

--- Sets the goal cell and triggers BFS recomputation (1-based coordinates).
---@param x any
---@param y any
---@return nil
function AiFlowField:setGoal(x, y) end

--- Returns the type name of this object.
---@return string
function AiFlowField:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function AiFlowField:typeOf(name) end

--- Lua-side wrapper around a [`FlowField`].
---@class FlowField
local FlowField = {}

--- Returns the integrated cost to the nearest target (1-based coordinates).
---@param x any
---@param y any
---@return number
function FlowField:getCostToTarget(x, y) end

--- Returns the normalised direction vector at a cell (1-based coordinates).
---@param x any
---@param y any
---@return number
function FlowField:getDirection(x, y) end

--- Returns the flow direction as an angle in radians (1-based coordinates).
---@param x any
---@param y any
---@return number
function FlowField:getDirectionAngle(x, y) end

--- Returns the target cells from the most recent computation (1-based coordinates).
---@return table
function FlowField:getTargets() end

--- Returns true if the flow field has been computed at least once.
---@return boolean
function FlowField:isCalculated() end

--- Returns the type name of this object.
---@return string
function FlowField:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function FlowField:typeOf(name) end

--- Lua-side wrapper around a [`HexGrid`].
---@class HexGrid
local HexGrid = {}

--- Returns true if a cell is blocked (1-based coordinates).
---@param col any
---@param row any
---@return boolean
function HexGrid:isBlocked(col, row) end

--- Set movement cost for a cell (1-based coordinates).
---@param col any
---@param row any
---@param cost any
---@return nil
function HexGrid:setCost(col, row, cost) end

--- Lua-side wrapper around a [`JpsGrid`].
---@class JpsGrid
local JpsGrid = {}

--- Returns true if the cell is blocked (1-based coordinates).
---@param x any
---@param y any
---@return boolean
function JpsGrid:isBlocked(x, y) end

--- Lua-side wrapper around a [`NavGrid`] with optional HPA★ abstract graph.
---@class NavGrid
local NavGrid = {}

--- Clears all pending dirty rectangles.
---@return nil
function NavGrid:clearDirty() end

--- Sets every cell to the given cost.
---@param cost any
---@return nil
function NavGrid:fill(cost) end

--- Returns the current HPA★ chunk size.
---@return integer
function NavGrid:getChunkSize() end

--- Returns the traversal cost of a cell (1-based coordinates).
---@param x any
---@param y any
---@return integer
function NavGrid:getCost(x, y) end

--- Returns the current diagonal movement mode as a string.
---@return string
function NavGrid:getDiagonalMode() end

--- Returns the grid dimensions as width, height.
---@return integer
function NavGrid:getDimensions() end

--- Returns the grid height in cells.
---@return integer
function NavGrid:getHeight() end

--- Returns the grid width in cells.
---@return integer
function NavGrid:getWidth() end

--- Returns true if the cell is blocked (1-based coordinates).
---@param x any
---@param y any
---@return boolean
function NavGrid:isBlocked(x, y) end

--- Overwrites the grid from a raw byte string (row-major, one byte per cell).
---@param data any
---@return nil
function NavGrid:loadFromString(data) end

--- Rebuilds the HPA★ abstract graph from the current grid state.
---@return nil
function NavGrid:rebuildAbstract() end

--- Exports the cost grid as a byte string (row-major, one byte per cell).
---@return string
function NavGrid:saveToString() end

--- Sets the HPA★ chunk size.
---@param size any
---@return nil
function NavGrid:setChunkSize(size) end

--- Sets the traversal cost of a cell (1-based coordinates).
---@param x any
---@param y any
---@param cost any
---@return nil
function NavGrid:setCost(x, y, cost) end

--- Sets the diagonal movement mode.
---@param mode any
---@return nil
function NavGrid:setDiagonalMode(mode) end

--- Records a dirty rectangle for incremental HPA★ updates (1-based coordinates).
---@param x any
---@param y any
---@param w any
---@param h any
---@return nil
function NavGrid:setDirty(x, y, w, h) end

--- Returns the type name of this object.
---@return string
function NavGrid:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function NavGrid:typeOf(name) end

--- Lua-side wrapper around a [`PathGrid`] (A★ weighted grid with per-cell cost).
---@class PathGrid
local PathGrid = {}

--- Returns the world-space size of each cell.
---@return number
function PathGrid:getCellSize() end

--- Returns the cost multiplier for a cell (1-based coordinates).
---@param x any
---@param y any
---@return number
function PathGrid:getCost(x, y) end

--- Returns the grid height in cells.
---@return integer
function PathGrid:getHeight() end

--- Returns the grid width in cells.
---@return integer
function PathGrid:getWidth() end

--- Returns true if a cell is walkable (1-based coordinates).
---@param x any
---@param y any
---@return boolean
function PathGrid:isWalkable(x, y) end

--- Sets the cost multiplier for a cell (1-based coordinates).
---@param x any
---@param y any
---@param cost any
---@return nil
function PathGrid:setCost(x, y, cost) end

--- Sets the walkability of a cell (1-based coordinates).
---@param x any
---@param y any
---@param w any
---@return nil
function PathGrid:setWalkable(x, y, w) end

--- Returns the type name of this object.
---@return string
function PathGrid:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function PathGrid:typeOf(name) end

--- Lua-side wrapper around a [`UnitPathfinder`].
---@class UnitPathfinder
local UnitPathfinder = {}

--- Removes all cached path results.
---@return nil
function UnitPathfinder:clearCache() end

--- Returns the number of entries in the path cache.
---@return integer
function UnitPathfinder:getCacheSize() end

--- Returns the sum of grid traversal costs along a path.
---@param path any
---@return number
function UnitPathfinder:getPathCost(path) end

--- Returns the euclidean length of a path table.
---@param path any
---@return number
function UnitPathfinder:getPathLength(path) end

--- Returns true if path result caching is enabled.
---@return boolean
function UnitPathfinder:isCacheEnabled() end

--- Enables or disables path result caching.
---@param enabled any
---@return nil
function UnitPathfinder:setCacheEnabled(enabled) end

--- Sets the maximum number of cached path entries.
---@param n any
---@return nil
function UnitPathfinder:setCacheMaxSize(n) end

--- Returns the type name of this object.
---@return string
function UnitPathfinder:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function UnitPathfinder:typeOf(name) end

--- Returns the background pathfinding thread count (currently always 0).
---@return integer
function lurek.pathfind.getThreadCount() end

--- Creates a new FlowField backed by a NavGrid.
---@param grid_ud any
---@return FlowField
function lurek.pathfind.newFlowField(grid_ud) end

--- Creates a hex grid for pathfinding, LOS, FOV, and range queries.
---@param width any
---@param height any
---@param layout_str? any (optional)
---@return HexGrid
function lurek.pathfind.newHexGrid(width, height, layout_str) end

--- Creates a uniform-cost grid optimised for Jump Point Search (orthogonal + diagonal).
---@param width any
---@param height any
---@return JpsGrid
function lurek.pathfind.newJpsGrid(width, height) end

--- Creates a new NavGrid with all cells walkable.
---@param width any
---@param height any
---@return NavGrid
function lurek.pathfind.newNavGrid(width, height) end

--- Builds a NavGrid from a TileMap layer, treating specified GIDs as blocked (unwalkable).
---@param tm_ud any
---@param layer_index any
---@param blocked_table any
---@return NavGrid
function lurek.pathfind.newNavGridFromTileMap(tm_ud, layer_index, blocked_table) end

--- Creates a new BFS flow field from a PathGrid.
---@param grid_ud any
---@return AiFlowField
function lurek.pathfind.newPathFlowField(grid_ud) end

--- Creates a new PathGrid with per-cell cost and walkability.
---@param w any
---@param h any
---@param cell_size any
---@return PathGrid
function lurek.pathfind.newPathGrid(w, h, cell_size) end

--- Creates a new UnitPathfinder backed by a NavGrid.
---@param grid_ud any
---@return UnitPathfinder
function lurek.pathfind.newPathfinder(grid_ud) end

--- Computes a Dijkstra range-of-movement map from an origin within a movement budget.
---@param opts any
---@return table
function lurek.pathfind.rangeMap(opts) end

--- Sets the background pathfinding thread count (currently a no-op).
---@param count any
---@return nil
function lurek.pathfind.setThreadCount(count) end

---@class lurek.patterns
lurek.patterns = {}

--- Lua wrapper for the Blackboard pattern.
---@class Blackboard
local Blackboard = {}

--- Removes a fact from the blackboard.
---@param key any
---@return nil
function Blackboard:clear(key) end

--- Clears all facts from the blackboard.
---@return nil
function Blackboard:clearAll() end

--- Gets a fact from the blackboard. Returns nil if not set.
---@param key any
---@return boolean|number|string|nil
function Blackboard:get(key) end

--- Returns the monotonic revision counter (incremented on every write).
---@return integer
function Blackboard:getRevision() end

--- Returns true when the key has a non-nil value.
---@param key any
---@return boolean
function Blackboard:has(key) end

--- Returns all set fact keys as a table.
---@return table
function Blackboard:keys() end

--- Sets a fact on the blackboard. Accepts boolean, number, or string values.
---@param key any
---@param value any
---@return nil
function Blackboard:set(key, value) end

--- Returns all facts as a flat keyâ†’value table.
---@return table
function Blackboard:snapshot() end

--- Removes a watcher subscription by id.
---@param id any
---@return nil
function Blackboard:unwatch(id) end

--- Subscribes to changes on a specific key (or "*" for all changes).
---@param key any
---@param callback any
---@return integer
function Blackboard:watch(key, callback) end

--- Lua wrapper for the CommandStack pattern.
---@class CommandStack
local CommandStack = {}

--- Returns true if there is a command available to redo.
---@return boolean
function CommandStack:canRedo() end

--- Returns true if the most recent command can be undone.
---@return boolean
function CommandStack:canUndo() end

--- Clears all command history, releasing Lua registry values.
---@return nil
function CommandStack:clearAll() end

--- Executes a named command and records it in undo/redo history.
---@param name any
---@param exec_fn any
---@param undo_fn? any (optional)
---@return nil
function CommandStack:execute(name, exec_fn, undo_fn) end

--- Returns the name of the most recently executed command, or nil.
---@return string?
function CommandStack:getCurrentName() end

--- Returns the total number of recorded commands (undo + redo).
---@return integer
function CommandStack:getHistorySize() end

--- Re-executes the next undone command. Returns true if successful.
---@return boolean
function CommandStack:redo() end

--- Undoes the most recent command. Returns true if successful.
---@return boolean
function CommandStack:undo() end

--- Lua wrapper for the Debounce pattern.
---@class Debounce
local Debounce = {}

--- Cancels the pending trigger without firing.
---@return nil
function Debounce:cancel() end

--- Returns the total number of times this debounce has fired.
---@return integer
function Debounce:getFireCount() end

--- Returns true when a trigger is pending.
---@return boolean
function Debounce:isPending() end

--- Sets the callback invoked when the debounce fires.
---@param f any
---@return nil
function Debounce:onFire(f) end

--- Records an input event, resetting the idle timer.
---@return nil
function Debounce:trigger() end

--- Advances the idle timer by dt seconds; fires the callback if idle wait expired.
---@param dt any
---@return boolean
function Debounce:update(dt) end

--- Lua wrapper for the EventBus pattern.
---@class EventBus
local EventBus = {}

--- Removes all listeners for a specific event.
---@param event any
---@return nil
function EventBus:clear(event) end

--- Removes all listeners on this EventBus.
---@return nil
function EventBus:clearAll() end

--- Dispatches an event, calling all registered listeners in priority order.
---@param args any
---@return nil
function EventBus:emit(args) end

--- Returns all event names that have at least one listener.
---@return table
function EventBus:getEvents() end

--- Returns the number of listeners registered for an event.
---@param event any
---@return integer
function EventBus:getListenerCount(event) end

--- Removes a previously registered event listener by subscription ID.
---@param id any
---@return nil
function EventBus:off(id) end

--- Registers a listener callback for an event.
---@param event any
---@param callback any
---@param priority? any (optional)
---@return integer
function EventBus:on(event, callback, priority) end

--- Lua wrapper for the Factory pattern.
---@class Factory
local Factory = {}

--- Registers an alias pointing to an existing canonical type name.
---@param alias any
---@param canonical any
---@return nil
function Factory:alias(alias, canonical) end

--- Removes all registered type constructors and aliases.
---@return nil
function Factory:clearAll() end

--- Creates an instance of the named type by invoking its constructor.
---@param args any
---@return table|userdata
function Factory:create(args) end

--- Returns a table of all registered type names.
---@return table
function Factory:getTypes() end

--- Returns true if the named type (or alias) is registered.
---@param type_name any
---@return boolean
function Factory:has(type_name) end

--- Registers a named type constructor function.
---@param type_name any
---@param ctor any
---@return nil
function Factory:register(type_name, ctor) end

--- Unregisters a type constructor (and any aliases pointing to it).
---@param type_name any
---@return nil
function Factory:remove(type_name) end

--- Lua wrapper for the Funnel (event aggregator) pattern.
---@class Funnel
local Funnel = {}

--- Discards all buffered entries without flushing.
---@return nil
function Funnel:discard() end

--- Manually flushes all pending entries, invoking the onFlush callback.
---@return nil
function Funnel:flush() end

--- Returns the total number of flushes performed.
---@return integer
function Funnel:getFlushCount() end

--- Sets a callback invoked when the funnel flushes. Receives a table of {tag, value} entries.
---@param f any
---@return nil
function Funnel:onFlush(f) end

--- Returns the number of buffered entries not yet flushed.
---@return integer
function Funnel:pendingCount() end

--- Adds an event to the funnel. Immediately flushes if max_entries reached or window is 0.
---@param tag any
---@param value? any (optional)
---@return nil
function Funnel:push(tag, value) end

--- Advances the window timer by dt seconds; flushes when window expires.
---@param dt any
---@return boolean
function Funnel:update(dt) end

--- Lua wrapper for an ordered, resizable list.
---@class List
local List = {}

--- Appends a value to the end of the list.
---@param value any
---@return nil
function List:add(value) end

--- Removes all values from the list.
---@return nil
function List:clear() end

--- Returns true if the list contains a value equal to the given Lua value (string/number/boolean).
---@param value any
---@return boolean
function List:contains(value) end

--- Returns the value at a 1-based index, or nil.
---@param index any
---@return table|nil
function List:get(index) end

--- Returns true if the list is empty.
---@return boolean
function List:isEmpty() end

--- Returns the number of items in the list.
---@return integer
function List:len() end

--- Removes and returns the value at a 1-based index.
---@param index any
---@return table|nil
function List:remove(index) end

--- Replaces the value at a 1-based index.
---@param index any
---@param value any
---@return nil
function List:set(index, value) end

--- Returns all items as a Lua table.
---@return table
function List:toArray() end

--- Lua wrapper for the Mediator pattern.
---@class Mediator
local Mediator = {}

--- Dispatches a message to all handlers across all channels.
---@param args any
---@return nil
function Mediator:broadcast(args) end

--- Returns all registered channel names.
---@return table
function Mediator:channels() end

--- Removes all channels and handlers.
---@return nil
function Mediator:clear() end

--- Returns the number of handlers on a channel.
---@param channel any
---@return integer
function Mediator:handlerCount(channel) end

--- Unregisters a handler by ID.
---@param channel any
---@param id any
---@return nil
function Mediator:off(channel, id) end

--- Registers a handler callback on a channel; returns handler ID.
---@param channel any
---@param callback any
---@return integer
function Mediator:on(channel, callback) end

--- Removes a channel and all its handlers.
---@param channel any
---@return nil
function Mediator:removeChannel(channel) end

--- Dispatches a message to all handlers on a channel.
---@param args any
---@return nil
function Mediator:send(args) end

--- Lua wrapper for the ObjectPool pattern.
---@class ObjectPool
local ObjectPool = {}

--- Acquires an available object from the pool; returns nil if empty.
---@return string|number|boolean|table|nil
function ObjectPool:acquire() end

--- Inserts a pre-built object into the available pool.
---@param value any
---@return nil
function ObjectPool:add(value) end

--- Clears all objects from the pool, releasing Lua registry values.
---@return nil
function ObjectPool:clearAll() end

--- Returns the number of currently active (acquired) objects.
---@return integer
function ObjectPool:getActiveCount() end

--- Returns the number of available (idle) objects in the pool.
---@return integer
function ObjectPool:getAvailableCount() end

--- Returns the total number of tracked objects (active + available).
---@return integer
function ObjectPool:getTotalCount() end

--- Returns an object to the available pool.
---@param value any
---@return nil
function ObjectPool:release(value) end

--- Lua wrapper for the Observer pattern.
---@class Observer
local Observer = {}

--- Gets a property value, or nil if not set.
---@param key any
---@return string|number|boolean|table|nil
function Observer:get(key) end

--- Returns the total number of active subscriptions.
---@return integer
function Observer:getCount() end

--- Sets a property value and fires subscribed watchers.
---@param key any
---@param new_val any
---@return nil
function Observer:set(key, new_val) end

--- Subscribes to changes on a property key (or "*" for all).
---@param key any
---@param callback any
---@param once? any (optional)
---@return integer
function Observer:subscribe(key, callback, once) end

--- Removes a subscription by id.
---@param id any
---@return nil
function Observer:unsubscribe(id) end

--- Lua wrapper for the PriorityQueue pattern.
---@class PriorityQueue
local PriorityQueue = {}

--- Removes all items from the queue.
---@return nil
function PriorityQueue:clearAll() end

--- Returns true when the queue has no items.
---@return boolean
function PriorityQueue:isEmpty() end

--- Returns the number of items in the queue.
---@return integer
function PriorityQueue:len() end

--- Returns the highest-priority item without removing it, or nil if empty.
---@return string|number|boolean|table|nil
function PriorityQueue:peek() end

--- Removes and returns the highest-priority item, or nil if empty.
---@return string|number|boolean|table|nil
function PriorityQueue:pop() end

--- Inserts an item with a priority. Higher priorities are dequeued first.
---@param priority any
---@param value any
---@param label? any (optional)
---@return integer
function PriorityQueue:push(priority, value, label) end

--- Lua wrapper for a FIFO queue.
---@class Queue
local Queue = {}

--- Removes all values from the queue.
---@return nil
function Queue:clear() end

--- Removes and returns the front value, or nil if empty.
---@return table|nil
function Queue:dequeue() end

--- Adds a value to the back of the queue. Returns false if capacity is full.
---@param value any
---@return boolean
function Queue:enqueue(value) end

--- Returns the front value without removing it, or nil if empty.
---@return table|nil
function Queue:front() end

--- Returns true if the queue is empty.
---@return boolean
function Queue:isEmpty() end

--- Returns true if the queue is at its capacity limit.
---@return boolean
function Queue:isFull() end

--- Returns the number of items in the queue.
---@return integer
function Queue:len() end

--- Returns all items as a Lua table (front to back).
---@return table
function Queue:toArray() end

--- Lua wrapper for the RelationshipManager pattern.
---@class RelationshipManager
local RelationshipManager = {}

--- Adjusts the numeric relationship value by a delta.
---@param a any
---@param b any
---@param delta any
---@return nil
function RelationshipManager:adjustValue(a, b, delta) end

--- Defines a relationship type with ordered levels.
---@param name any
---@param levels any
---@param default_level? any (optional)
---@return nil
function RelationshipManager:defineType(name, levels, default_level) end

--- Returns the named level for a typed relationship, or nil.
---@param a any
---@param b any
---@param type_name any
---@return string?
function RelationshipManager:getLevel(a, b, type_name) end

--- Returns the numeric relationship value between two entities (default 0.0).
---@param a any
---@param b any
---@return number
function RelationshipManager:getValue(a, b) end

--- Returns the total number of stored relationship pairs.
---@return integer
function RelationshipManager:pairCount() end

--- Removes all relationship data between two entities.
---@param a any
---@param b any
---@return nil
function RelationshipManager:removePair(a, b) end

--- Removes a relationship type definition.
---@param name any
---@return nil
function RelationshipManager:removeType(name) end

--- Sets a named level for a typed relationship between two entities.
---@param a any
---@param b any
---@param type_name any
---@param level any
---@return boolean
function RelationshipManager:setLevel(a, b, type_name, level) end

--- Sets the numeric relationship value between two entities.
---@param a any
---@param b any
---@param value any
---@return nil
function RelationshipManager:setValue(a, b, value) end

--- Returns all defined relationship type names.
---@return table
function RelationshipManager:typeNames() end

--- Lua wrapper for the Ring (circular buffer) pattern.
---@class Ring
local Ring = {}

--- Returns the average of all numeric values, or 0 if empty.
---@return number
function Ring:average() end

--- Removes all entries from the ring.
---@return nil
function Ring:clear() end

--- Returns true when the ring is at capacity.
---@return boolean
function Ring:isFull() end

--- Returns the most recently pushed entry, or nil.
---@return table?
function Ring:latest() end

--- Returns the number of entries currently in the ring.
---@return integer
function Ring:len() end

--- Pushes a value (number or string) with an optional tag. Overwrites oldest on overflow.
---@param value any
---@param tag? any (optional)
---@return integer
function Ring:push(value, tag) end

--- Returns the sum of all numeric values in the ring.
---@return number
function Ring:sum() end

--- Returns all entries (oldest first) as an array of {id, tag, value?, text?} tables.
---@return table
function Ring:toArray() end

--- Lua wrapper for the ServiceLocator pattern.
---@class ServiceLocator
local ServiceLocator = {}

--- Removes all registered services.
---@return nil
function ServiceLocator:clearAll() end

--- Returns a table of all registered service names.
---@return table
function ServiceLocator:getServices() end

--- Returns true if a service with the given name is registered.
---@param name any
---@return boolean
function ServiceLocator:has(name) end

--- Retrieves a registered service by name; returns nil if not found.
---@param name any
---@return string|number|boolean|table|nil
function ServiceLocator:locate(name) end

--- Registers a named service with an associated Lua value.
---@param name any
---@param value any
---@return nil
function ServiceLocator:provide(name, value) end

--- Unregisters and removes a named service.
---@param name any
---@return nil
function ServiceLocator:remove(name) end

--- Lua wrapper for an unordered set. Values are keyed by their string representation.
---@class Set
local Set = {}

--- Adds a string key to the set. Returns true if it was not already present.
---@param key any
---@return boolean
function Set:add(key) end

--- Removes all keys from the set.
---@return nil
function Set:clear() end

--- Returns true if the key is in the set.
---@param key any
---@return boolean
function Set:has(key) end

--- Returns the intersection of this set and another as a new Set.
---@param other any
---@return Set
function Set:intersection(other) end

--- Returns true if the set is empty.
---@return boolean
function Set:isEmpty() end

--- Returns the number of distinct keys in the set.
---@return integer
function Set:len() end

--- Removes a key from the set. Returns true if it was present.
---@param key any
---@return boolean
function Set:remove(key) end

--- Returns all keys as a Lua table (unordered).
---@return table
function Set:toArray() end

--- Returns the union of this set and another as a new Set.
---@param other any
---@return Set
function Set:union(other) end

--- Lua wrapper for the SimpleState finite state machine pattern.
---@class SimpleState
local SimpleState = {}

--- Registers a named state with optional enter, exit, and update callbacks.
---@param name any
---@param callbacks? any (optional)
---@return nil
function SimpleState:addState(name, callbacks) end

--- Removes all states and callbacks from this state machine.
---@return nil
function SimpleState:clearAll() end

--- Returns the name of the current state, or nil if none is active.
---@return string?
function SimpleState:getCurrent() end

--- Returns a table of all registered state names.
---@return table
function SimpleState:getStates() end

--- Returns true if a state with the given name is registered.
---@param name any
---@return boolean
function SimpleState:hasState(name) end

--- Transitions to a named state, calling exit/enter callbacks as needed.
---@param name any
---@return boolean
function SimpleState:transitionTo(name) end

--- Calls the update callback of the current state with the given delta time.
---@param dt any
---@return nil
function SimpleState:update(dt) end

--- Lua wrapper for a LIFO stack.
---@class Stack
local Stack = {}

--- Removes all values from the stack.
---@return nil
function Stack:clear() end

--- Returns true if the stack is empty.
---@return boolean
function Stack:isEmpty() end

--- Returns true if the stack is at its capacity limit.
---@return boolean
function Stack:isFull() end

--- Returns the number of items on the stack.
---@return integer
function Stack:len() end

--- Returns the top value without removing it, or nil if empty.
---@return table|nil
function Stack:peek() end

--- Removes and returns the top value, or nil if empty.
---@return table|nil
function Stack:pop() end

--- Pushes a value onto the stack. Returns false if capacity is full.
---@param value any
---@return boolean
function Stack:push(value) end

--- Returns all items as a Lua table (bottom to top).
---@return table
function Stack:toArray() end

--- Lua wrapper for the Strategy pattern.
---@class Strategy
local Strategy = {}

--- Removes all strategies and clears the active selection.
---@return nil
function Strategy:clear() end

--- Calls the currently active strategy function with the given arguments.
---@param args any
---@return table|nil
function Strategy:execute(args) end

--- Returns the name of the active strategy, or nil.
---@return string?
function Strategy:getCurrent() end

--- Returns true if a strategy with this name is registered.
---@param name any
---@return boolean
function Strategy:has(name) end

--- Returns all registered strategy names.
---@return table
function Strategy:names() end

--- Registers a named strategy function.
---@param name any
---@param callback any
---@return nil
function Strategy:register(name, callback) end

--- Removes a strategy by name.
---@param name any
---@return boolean
function Strategy:remove(name) end

--- Sets the active strategy by name. Returns false if not registered.
---@param name any
---@return boolean
function Strategy:set(name) end

--- Lua wrapper for the Throttle pattern.
---@class Throttle
local Throttle = {}

--- Returns the total number of times this throttle has fired.
---@return integer
function Throttle:getFireCount() end

--- Returns the normalised progress through the current interval [0, 1].
---@return number
function Throttle:getProgress() end

--- Sets the callback invoked when the throttle fires.
---@param f any
---@return nil
function Throttle:onFire(f) end

--- Resets the elapsed counter without firing.
---@return nil
function Throttle:reset() end

--- Enables or disables the throttle.
---@param v any
---@return nil
function Throttle:setEnabled(v) end

--- Advances the timer by dt seconds; fires the callback if the interval elapsed.
---@param dt any
---@return boolean
function Throttle:update(dt) end

--- Creates a new Blackboard shared key-value store.
---@param name? any (optional)
---@return Blackboard
function lurek.patterns.newBlackboard(name) end

--- Creates a new CommandStack instance.
---@param max_size? any (optional)
---@return CommandStack
function lurek.patterns.newCommandStack(max_size) end

--- Creates a trailing-edge debounce that fires after the input stream is idle for wait seconds.
---@param wait any
---@return Debounce
function lurek.patterns.newDebounce(wait) end

--- Creates a new EventBus instance.
---@param name? any (optional)
---@return EventBus
function lurek.patterns.newEventBus(name) end

--- Creates a new Factory instance.
---@return Factory
function lurek.patterns.newFactory() end

--- Creates a time-windowed event aggregator. window=0 means flush on every push.
---@param window any
---@param max_entries? any (optional)
---@param name? any (optional)
---@return Funnel
function lurek.patterns.newFunnel(window, max_entries, name) end

--- Creates an ordered, resizable list.
---@return List
function lurek.patterns.newList() end

--- Creates a new named-channel message broker.
---@return Mediator
function lurek.patterns.newMediator() end

--- Creates a new ObjectPool instance.
---@return ObjectPool
function lurek.patterns.newObjectPool() end

--- Creates a new reactive property Observer.
---@param name? any (optional)
---@return Observer
function lurek.patterns.newObserver(name) end

--- Creates a stable priority-ordered task queue.
---@param name? any (optional)
---@return PriorityQueue
function lurek.patterns.newPriorityQueue(name) end

--- Creates a FIFO queue. capacity=0 means unlimited.
---@param capacity? any (optional)
---@return Queue
function lurek.patterns.newQueue(capacity) end

--- Creates a new entity relationship manager.
---@return RelationshipManager
function lurek.patterns.newRelationshipManager() end

--- Creates a fixed-capacity circular history buffer.
---@param capacity any
---@param name? any (optional)
---@return Ring
function lurek.patterns.newRing(capacity, name) end

--- Creates a new ServiceLocator instance.
---@return ServiceLocator
function lurek.patterns.newServiceLocator() end

--- Creates an unordered set that rejects duplicate values (by string key).
---@return Set
function lurek.patterns.newSet() end

--- Creates a new SimpleState finite state machine instance.
---@return SimpleState
function lurek.patterns.newSimpleState() end

--- Creates a LIFO stack. capacity=0 means unlimited.
---@param capacity? any (optional)
---@return Stack
function lurek.patterns.newStack(capacity) end

--- Creates a new strategy registry.
---@return Strategy
function lurek.patterns.newStrategy() end

--- Creates a leading-edge rate limiter that fires at most once per interval seconds.
---@param interval any
---@return Throttle
function lurek.patterns.newThrottle(interval) end

---@class lurek.physics
lurek.physics = {}

--- Lua-side handle to a physics body accessed through its world.
---@class Body
local Body = {}

--- Applies an angular impulse.
---@param impulse any
---@return nil
function Body:applyAngularImpulse(impulse) end

--- Applies a continuous force to the body.
---@param fx any
---@param fy any
---@return nil
function Body:applyForce(fx, fy) end

--- Applies a linear impulse to the body.
---@param ix any
---@param iy any
---@return nil
function Body:applyImpulse(ix, iy) end

--- Applies a torque (rotational force).
---@param torque any
---@return nil
function Body:applyTorque(torque) end

--- Removes this body from the world.
---@return nil
function Body:destroy() end

--- Returns the body angle in radians.
---@return number
function Body:getAngle() end

--- Returns the angular damping coefficient.
---@return number
function Body:getAngularDamping() end

--- Returns the angular velocity in radians/s.
---@return number
function Body:getAngularVelocity() end

--- Returns the body friction coefficient.
---@return number
function Body:getFriction() end

--- Returns the per-body gravity multiplier.
---@return number
function Body:getGravityScale() end

--- Returns the height of this body's primary collider shape in world units.
---@return number
function Body:getHeight() end

--- Returns the body's integer ID.
---@return integer
function Body:getId() end

--- Returns the collision layer bitmask.
---@return integer
function Body:getLayer() end

--- Returns the linear damping coefficient.
---@return number
function Body:getLinearDamping() end

--- Returns the collision mask bitmask.
---@return integer
function Body:getMask() end

--- Returns the body mass in kilograms used for force and impulse calculations.
---@return number
function Body:getMass() end

--- Returns the body position (x, y).
---@return number
function Body:getPosition() end

--- Returns the body restitution (bounciness).
---@return number
function Body:getRestitution() end

--- Returns the body type as a string.
---@return string
function Body:getType() end

--- Returns the body velocity (vx, vy).
---@return number
function Body:getVelocity() end

--- Returns the width of this body's primary collider shape in world units.
---@return number
function Body:getWidth() end

--- Returns the body X position.
---@return number
function Body:getX() end

--- Returns the body Y position.
---@return number
function Body:getY() end

--- Returns whether CCD is enabled.
---@return boolean
function Body:isBullet() end

--- Returns whether rotation is locked.
---@return boolean
function Body:isFixedRotation() end

--- Returns true if this body is currently sleeping (inactive).
---@return boolean
function Body:isSleeping() end

--- Returns whether the body can sleep.
---@return boolean
function Body:isSleepingAllowed() end

--- Sets the body angle in radians.
---@param angle any
---@return nil
function Body:setAngle(angle) end

--- Sets the angular damping coefficient.
---@param damping any
---@return nil
function Body:setAngularDamping(damping) end

--- Sets the angular velocity.
---@param omega any
---@return nil
function Body:setAngularVelocity(omega) end

--- Enables or disables continuous collision detection (CCD) for fast-moving bodies.
---@param bullet any
---@return nil
function Body:setBullet(bullet) end

--- Locks or unlocks rotation.
---@param fixed any
---@return nil
function Body:setFixedRotation(fixed) end

--- Sets the body friction coefficient.
---@param friction any
---@return nil
function Body:setFriction(friction) end

--- Sets the per-body gravity multiplier.
---@param scale any
---@return nil
function Body:setGravityScale(scale) end

--- Sets the collision layer bitmask.
---@param layer any
---@return nil
function Body:setLayer(layer) end

--- Sets the linear damping coefficient.
---@param damping any
---@return nil
function Body:setLinearDamping(damping) end

--- Sets the collision mask bitmask.
---@param mask any
---@return nil
function Body:setMask(mask) end

--- Sets the body mass; affects how forces and impulses change velocity.
---@param mass any
---@return nil
function Body:setMass(mass) end

--- Teleports the body to the given world-space position, bypassing collision.
---@param x any
---@param y any
---@return nil
function Body:setPosition(x, y) end

--- Sets the body restitution (bounciness).
---@param restitution any
---@return nil
function Body:setRestitution(restitution) end

--- Sets whether the body can sleep.
---@param allowed any
---@return nil
function Body:setSleepingAllowed(allowed) end

--- Changes the body type: `"dynamic"`, `"static"`, or `"kinematic"`.
---@param bt any
---@return nil
function Body:setType(bt) end

--- Sets the body's linear velocity in world units per second.
---@param vx any
---@param vy any
---@return nil
function Body:setVelocity(vx, vy) end

--- Puts this body to sleep immediately.
---@return nil
function Body:sleep() end

--- Forcibly wakes up this body.
---@return nil
function Body:wakeUp() end

--- Lua-side handle to a falling-sand [`CellularWorld`].
---@class Cellular
local Cellular = {}

--- Counts cells of the given material type.
---@param t any
---@return integer
function Cellular:countCells(t) end

--- Returns positions of all cells of the given material as an array of `{x, y}` tables.
---@param t any
---@return table
function Cellular:findCells(t) end

--- Returns the material at `(cx, cy)` as an integer constant.
---@param cx any
---@param cy any
---@return integer
function Cellular:getCell(cx, cy) end

--- Loads grid data from bytes produced by `toBytes`.
---@param data any
---@return nil
function Cellular:loadFromBytes(data) end

--- Sets the material of a cell.
---@param cx any
---@param cy any
---@param t any
---@return nil
function Cellular:setCell(cx, cy, t) end

--- Advances the simulation by one tick.
---@return nil
function Cellular:step() end

--- Advances the simulation by `n` ticks.
---@param n any
---@return nil
function Cellular:stepN(n) end

--- Serialises the grid to a byte string.
---@return string
function Cellular:toBytes() end

--- Returns the full grid as an RGBA byte string using the default colour palette.
---@return nil
function Cellular:toImageData() end

--- Lua-side standalone shape object (circle, rectangle, edge, polygon, chain).
---@class PhysicsShape
local PhysicsShape = {}

--- Releases this shape handle (GC handles cleanup).
---@return nil
function PhysicsShape:destroy() end

--- Returns the axis-aligned bounding box (x1, y1, x2, y2).
---@return number
function PhysicsShape:getBoundingBox() end

--- Returns the radius. Only valid for circle shapes.
---@return number
function PhysicsShape:getRadius() end

--- Returns the shape type string: "circle", "rectangle", "polygon", "edge", or "chain".
---@return string
function PhysicsShape:getType() end

--- Sets the density for this shape (used when attaching to a body).
---@param density any
---@return nil
function PhysicsShape:setDensity(density) end

--- Sets the friction coefficient.
---@param friction any
---@return nil
function PhysicsShape:setFriction(friction) end

--- Sets the restitution (bounciness) coefficient.
---@param restitution any
---@return nil
function PhysicsShape:setRestitution(restitution) end

--- Sets whether this shape is a sensor (non-colliding trigger).
---@param sensor any
---@return nil
function PhysicsShape:setSensor(sensor) end

--- Lua-side handle to a destructible [`TerrainMap`].
---@class Terrain
local Terrain = {}

--- Removes unsupported cells, returning the number of cells that fell.
---@return nil
function Terrain:collapseColumns() end

--- Sets every cell in the grid to `solid`.
---@param solid any
---@return nil
function Terrain:fillAll(solid) end

--- Rebuilds physics bodies for all dirty chunks.
---@return nil
function Terrain:flush() end

--- Returns whether a cell is solid.
---@param cx any
---@param cy any
---@return boolean
function Terrain:getCell(cx, cy) end

--- Returns `true` when at least one chunk needs flushing.
---@return boolean
function Terrain:isDirty() end

--- Loads terrain cell data from bytes produced by `toBytes`.
---@param data any
---@return nil
function Terrain:loadFromBytes(data) end

--- Sets a single terrain cell to solid or empty.
---@param cx any
---@param cy any
---@param solid any
---@return nil
function Terrain:setCell(cx, cy, solid) end

--- Returns the world-space centres of all solid cells as an array of `{x, y}` tables.
---@return table
function Terrain:solidPositions() end

--- Serialises the terrain grid to a byte string for save/load.
---@return string
function Terrain:toBytes() end

--- Lua-side handle wrapping a physics World.
---@class World
local World = {}

--- Creates a rectangular gravity/damping zone and returns a LuaZone handle.
---@param x any
---@param y any
---@param w any
---@param h any
---@return LuaZone
function World:addZone(x, y, w, h) end

--- Resets the world, removing all bodies and joints.
---@return nil
function World:clear() end

--- Removes the begin-contact callback.
---@return nil
function World:clearBeginContact() end

--- Removes the Lua data attached to a body.
---@param id any
---@return nil
function World:clearBodyData(id) end

--- Removes the one-way platform flag from a body.
---@param id any
---@return nil
function World:clearBodyOneWay(id) end

--- Removes the end-contact callback.
---@return nil
function World:clearEndContact() end

--- Removes a body from the world.
---@param id any
---@return nil
function World:destroyBody(id) end

--- Removes a joint from the world.
---@param jid any
---@return nil
function World:destroyJoint(jid) end

--- Returns the number of fixtures on a body.
---@param body_id any
---@return integer
function World:fixtureCount(body_id) end

--- Returns begin-contact events from the last step.
---@return table
function World:getBeginContactEvents() end

--- Returns the body ID at a world-space point, or nil.
---@param x any
---@param y any
---@return integer|nil
function World:getBodyAtPoint(x, y) end

--- Returns whether CCD is enabled for a body.
---@param id any
---@return boolean
function World:getBodyCCD(id) end

--- Returns contacts involving a specific body.
---@param body_id any
---@return table
function World:getBodyContacts(body_id) end

--- Returns the total number of bodies in the world.
---@return integer
function World:getBodyCount() end

--- Returns the Lua data previously attached to a body, or nil if none is set.
---@param id any
---@return nil
function World:getBodyData(id) end

--- Returns all body IDs in the world.
---@return table
function World:getBodyIds() end

--- Returns the one-way normal for a body, or nil if not configured.
---@param id any
---@return nil
function World:getBodyOneWay(id) end

--- Returns the body type as a string.
---@param id any
---@return string
function World:getBodyType(id) end

--- Returns collision events from the last step.
---@return table
function World:getCollisionEvents() end

--- Returns all contact pairs from the narrow phase.
---@return table
function World:getContacts() end

--- Returns end-contact events from the last step.
---@return table
function World:getEndContactEvents() end

--- Returns the gravity vector (gx, gy).
---@return number
function World:getGravity() end

--- Returns the two body IDs connected by a joint.
---@param jid any
---@return integer
function World:getJointBodies(jid) end

--- Returns the break threshold for a joint, or nil if not set.
---@param jid any
---@return nil
function World:getJointBreakForce(jid) end

--- Returns a table of integer IDs for every joint attached to this world.
---@return table
function World:getJointIds() end

--- Returns the angular limits on a joint.
---@param jid any
---@return number
function World:getJointLimits(jid) end

--- Returns the motor speed on a joint's angular axis.
---@param jid any
---@return number
function World:getJointMotorSpeed(jid) end

--- Returns the type name of a joint.
---@param jid any
---@return string
function World:getJointType(jid) end

--- Returns the pixels-per-meter scaling factor.
---@return number
function World:getMeter() end

--- Returns the current number of solver iterations per step.
---@return integer
function World:getSolverIterations() end

--- Returns zone enter/leave events produced by the most recent step.
---@return nil
function World:getZoneEvents() end

--- Returns true if a body is currently sleeping (inactive).
---@param id any
---@return boolean
function World:isBodySleeping(id) end

--- Returns the total number of joints.
---@return integer
function World:jointCount() end

--- Creates multiple bodies in one call.
---@param specs any
---@return nil
function World:newBodies(specs) end

--- Creates a new rectangular body and adds it to the world.
---@param x any
---@param y any
---@param bt any
---@return Body
function World:newBody(x, y, bt) end

--- Registers a Lua function called with (bodyIdA, bodyIdB) when two
---@param f any
---@return nil
function World:setBeginContact(f) end

--- Enables or disables Continuous Collision Detection for a body.
---@param id any
---@param enabled any
---@return nil
function World:setBodyCCD(id, enabled) end

--- Changes the simulation type of the body: `"dynamic"`, `"static"`, or `"kinematic"`.
---@param id any
---@param bt any
---@return nil
function World:setBodyType(id, bt) end

--- Registers a Lua function called with (bodyIdA, bodyIdB) when two
---@param f any
---@return nil
function World:setEndContact(f) end

--- Sets the world gravity vector; default is `(0, 9.81)` (downward).
---@param gx any
---@param gy any
---@return nil
function World:setGravity(gx, gy) end

--- Sets the relative-velocity threshold above which a joint breaks.
---@param jid any
---@param f any
---@return nil
function World:setJointBreakForce(jid, f) end

--- Sets the pixels-per-meter scaling factor.
---@param ppm any
---@return nil
function World:setMeter(ppm) end

--- Sets the number of constraint solver iterations per step.
---@param n any
---@return nil
function World:setSolverIterations(n) end

--- Puts a body to sleep immediately.
---@param id any
---@return nil
function World:sleepBody(id) end

--- Advances the physics simulation by dt seconds, firing onBeginContact /
---@param dt any
---@return nil
function World:step(dt) end

--- Converts a pixel value to physics units.
---@param px any
---@return number
function World:toPhysics(px) end

--- Converts a physics-unit value to pixels.
---@param m any
---@return number
function World:toPixels(m) end

--- Forcibly wakes up a sleeping body.
---@param id any
---@return nil
function World:wakeUpBody(id) end

--- Lua-side handle to a [`PhysicsZone`] living inside a [`World`].
---@class Zone
local Zone = {}

--- Removes the zone from the world.
---@return nil
function Zone:destroy() end

--- Returns the zone's integer ID.
---@return integer
function Zone:getId() end

--- Replaces the zone boundary with a circle.
---@param cx any
---@param cy any
---@param radius any
---@return nil
function Zone:setCircle(cx, cy, radius) end

--- Enables or disables the zone.
---@param enabled any
---@return nil
function Zone:setEnabled(enabled) end

--- Sets directional gravity inside the zone.
---@param gx any
---@param gy any
---@return nil
function Zone:setGravityDirectional(gx, gy) end

--- Suppresses gravity inside the zone (zero-g pocket).
---@return nil
function Zone:setGravityZero() end

--- Sets the layer bitmask; only bodies whose `layer & mask != 0` are affected.
---@param mask any
---@return nil
function Zone:setLayerMask(mask) end

--- Sets an optional linear damping override for bodies inside the zone.
---@param value? any (optional)
---@return nil
function Zone:setLinearDampingOverride(value) end

--- Sets the zone priority; higher values win over lower when zones overlap.
---@param priority any
---@return nil
function Zone:setPriority(priority) end

--- Attaches a standalone shape to a body as an additional fixture.
---@param body_ud any
---@param shape_ud any
---@return nil
function lurek.physics.attachShape(body_ud, shape_ud) end

--- Enables or disables the physics debug overlay (AABB boxes and velocity vectors).
---@param enable any
---@return nil
function lurek.physics.debugDraw(enable) end

--- Marks a physics world for destruction. Subsequent operations on the world
---@param world_ud any
---@return nil
function lurek.physics.destroyWorld(world_ud) end

--- Extracts collider geometry from a World and queues a GPU physics debug
---@param world_ud any
---@param config_val any
---@return nil
function lurek.physics.drawDebugGpu(world_ud, config_val) end

--- Returns the position and velocity of a body (x, y, vx, vy).
---@param world_ud any
---@param body_ud any
---@return number
function lurek.physics.getBody(world_ud, body_ud) end

--- Returns all collision events from the last simulation step.
---@param world_ud any
---@return table
function lurek.physics.getCollisions(world_ud) end

--- Returns whether the body is allowed to sleep.
---@param world_ud any
---@param body_ud any
---@return boolean
function lurek.physics.isSleepingAllowed(world_ud, body_ud) end

--- Creates a new rectangular body in the given world.
---@param world_ud any
---@param x any
---@param y any
---@param bt any
---@return Body
function lurek.physics.newBody(world_ud, x, y, bt) end

--- Creates a falling-sand cellular automaton grid.
---@param width any
---@param height any
---@return LuaCellular
function lurek.physics.newCellular(width, height) end

--- Creates a chain shape userdata from flat variadic vertex pairs.
---@param closed any
---@param coords any
---@return Shape
function lurek.physics.newChainShape(closed, coords) end

--- Creates a circle shape userdata.
---@param r any
---@return Shape
function lurek.physics.newCircleShape(r) end

--- Creates an edge (line segment) shape userdata.
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@return Shape
function lurek.physics.newEdgeShape(x1, y1, x2, y2) end

--- Creates a convex polygon shape userdata from flat variadic vertex pairs.
---@return Shape
function lurek.physics.newPolygonShape() end

--- Creates a rectangle shape userdata.
---@param w any
---@param h any
---@return Shape
function lurek.physics.newRectangleShape(w, h) end

--- Creates a destructible terrain grid.
---@param width any
---@param height any
---@param cell_size any
---@param world_ud any
---@return LuaTerrain
function lurek.physics.newTerrain(width, height, cell_size, world_ud) end

--- Creates a new physics world with the given gravity vector.
---@param gx any
---@param gy any
---@return World
function lurek.physics.newWorld(gx, gy) end

--- Sets the velocity of a body.
---@param world_ud any
---@param body_ud any
---@param vx any
---@param vy any
---@return nil
function lurek.physics.setBodyVelocity(world_ud, body_ud, vx, vy) end

--- Sets whether the body is allowed to sleep.
---@param world_ud any
---@param body_ud any
---@param allowed any
---@return nil
function lurek.physics.setSleepingAllowed(world_ud, body_ud, allowed) end

--- Advances the physics world by dt seconds.
---@param world_ud any
---@param dt any
---@return nil
function lurek.physics.step(world_ud, dt) end

--- Returns true when two axis-aligned bounding boxes overlap.
---@param ax any
---@param ay any
---@param aw any
---@param ah any
---@param bx any
---@param by any
---@param bw any
---@param bh any
---@return boolean
function lurek.physics.testAABB(ax, ay, aw, ah, bx, by, bw, bh) end

--- Returns true when a circle overlaps an AABB.
---@param cx any
---@param cy any
---@param cr any
---@param ax any
---@param ay any
---@param aw any
---@param ah any
---@return boolean
function lurek.physics.testCircleAABB(cx, cy, cr, ax, ay, aw, ah) end

--- Returns true when two circles overlap.
---@param ax any
---@param ay any
---@param ar any
---@param bx any
---@param by any
---@param br any
---@return boolean
function lurek.physics.testCircles(ax, ay, ar, bx, by, br) end

--- Returns true when point (px, py) lies inside the AABB.
---@param px any
---@param py any
---@param ax any
---@param ay any
---@param aw any
---@param ah any
---@return boolean
function lurek.physics.testPoint(px, py, ax, ay, aw, ah) end

---@class lurek.pipeline
lurek.pipeline = {}

--- Lua-side wrapper around a [`Pipeline`] DAG with scheduler and Lua callback registry.
---@class Pipeline
local Pipeline = {}

--- Adds a step to the pipeline. Returns self for chaining.
---@param step_ud any
---@return Pipeline
function Pipeline:addStep(step_ud) end

--- Cancels all pending and waiting steps.
---@return nil
function Pipeline:cancel() end

--- Clears all steps from the pipeline.
---@return nil
function Pipeline:clear() end

--- Returns the stored async context table, or nil.
---@return table?
function Pipeline:getContext() end

--- Returns the current error mode as a string.
---@return string
function Pipeline:getErrorMode() end

--- Returns the topological execution order as an array of step names.
---@return nil
function Pipeline:getExecutionOrder() end

--- Returns the pipeline's name.
---@return string
function Pipeline:getName() end

--- Returns parallel execution groups as a nested array of step name arrays.
---@return nil
function Pipeline:getParallelGroups() end

--- Returns the current result table built from step states, or nil.
---@return table?
function Pipeline:getResult() end

--- Returns the LuaStep wrapper for the named step, or nil.
---@param name any
---@return nil
function Pipeline:getStep(name) end

--- Returns the total number of steps.
---@return integer
function Pipeline:getStepCount() end

--- Returns a Lua array of all step wrappers in the pipeline.
---@return table
function Pipeline:getSteps() end

--- Returns a Lua array of all steps whose tag matches the given string.
---@param tag any
---@return table
function Pipeline:getStepsByTag(tag) end

--- Returns true if all steps have reached a terminal state.
---@return boolean
function Pipeline:isComplete() end

--- Returns true if the pipeline is currently running asynchronously.
---@return boolean
function Pipeline:isRunning() end

--- Registers a callback invoked after every step with `(step_name, status)`.
---@param cb any
---@return nil
function Pipeline:onProgress(cb) end

--- Removes a step from the pipeline by name.
---@param name any
---@return nil
function Pipeline:removeStep(name) end

--- Resets all step states and clears the async context.
---@return nil
function Pipeline:reset() end

--- Executes the pipeline synchronously in topological order.
---@param context? any (optional)
---@return table
function Pipeline:run(context) end

--- Starts an async pipeline run. Steps are executed one-per-frame via update(dt).
---@param context? any (optional)
---@return nil
function Pipeline:runAsync(context) end

--- Sets the pipeline error mode: "abort" or "continue".
---@param mode any
---@return nil
function Pipeline:setErrorMode(mode) end

--- Sets the pipeline's name.
---@param name any
---@return nil
function Pipeline:setName(name) end

--- Sets the callback to invoke when the pipeline completes.
---@param cb? any (optional)
---@return nil
function Pipeline:setOnComplete(cb) end

--- Sets the callback to invoke each time a step completes successfully.
---@param cb? any (optional)
---@return nil
function Pipeline:setOnStepComplete(cb) end

--- Sets the callback to invoke each time a step fails.
---@param cb? any (optional)
---@return nil
function Pipeline:setOnStepError(cb) end

--- Returns a multi-line ASCII string visualising the pipeline DAG.
---@return string
function Pipeline:toAscii() end

--- Serialises the pipeline definition to a Lua table (no callbacks).
---@return table
function Pipeline:toTable() end

--- Returns the type name of this object.
---@return string
function Pipeline:type() end

--- Returns the type identifier string of this pipeline stage object.
---@param name any
---@return boolean
function Pipeline:typeOf(name) end

--- Advances the async pipeline by one tick. Returns true when all steps are done.
---@param dt any
---@return boolean
function Pipeline:update(dt) end

--- Validates the pipeline DAG. Returns (ok, error_array).
---@return nil
function Pipeline:validate() end

--- Lua-side wrapper around a single [`PipelineStep`], plus Lua callback registry keys.
---@class Step
local Step = {}

--- Adds a dependency on another step by name or PipelineStep. Returns self for chaining
---@param dep any
---@return PipelineStep
function Step:dependsOn(dep) end

--- Returns the number of execution attempts so far
---@return integer
function Step:getAttempt() end

--- Retrieves a metadata value by key, returning nil if not found
---@param key any
---@return string?
function Step:getData(key) end

--- Returns the configured delay in seconds
---@return number
function Step:getDelay() end

--- Returns the list of dependency step names
---@return table
function Step:getDependencies() end

--- Returns the number of declared dependencies
---@return integer
function Step:getDependencyCount() end

--- Returns total seconds spent executing this step
---@return number
function Step:getDuration() end

--- Returns the error message from the last failed attempt, or nil
---@return string?
function Step:getError() end

--- Returns the unique name of this step
---@return string
function Step:getName() end

--- Returns the configured retry count
---@return integer
function Step:getRetryCount() end

--- Returns the current execution status as a string
---@return string
function Step:getStatus() end

--- Returns the tag on this step, or nil if unset
---@return string?
function Step:getTag() end

--- Returns the timeout stored in metadata, or 0.0 if unset
---@return number
function Step:getTimeout() end

--- Returns whether this step is marked as optional
---@return boolean
function Step:isOptional() end

--- Stores a Lua function as the execute callback for this step
---@param cb any
---@return nil
function Step:setCallback(cb) end

--- Stores a Lua function (or nil) as the run-condition for this step
---@param cond? any (optional)
---@return nil
function Step:setCondition(cond) end

--- Stores an arbitrary string value under the given key in step metadata
---@param key any
---@param value any
---@return nil
function Step:setData(key, value) end

--- Sets the delay in seconds to wait after dependencies finish
---@param seconds any
---@return nil
function Step:setDelay(seconds) end

--- Stores a Lua function (or nil) to call if this step fails
---@param cb? any (optional)
---@return nil
function Step:setOnError(cb) end

--- Marks whether this step is optional (downstream steps continue on failure)
---@param optional any
---@return nil
function Step:setOptional(optional) end

--- Sets the maximum number of retry attempts on failure
---@param count any
---@return nil
function Step:setRetryCount(count) end

--- Sets the delay in seconds between retry attempts
---@param seconds any
---@return nil
function Step:setRetryDelay(seconds) end

--- Sets the tag on this step for grouping and filtering
---@param tag any
---@return nil
function Step:setTag(tag) end

--- Stores a timeout in seconds in the step's metadata
---@param seconds any
---@return nil
function Step:setTimeout(seconds) end

--- Returns the type name "PipelineStep"
---@return string
function Step:type() end

--- Returns true when the given name matches "PipelineStep" or a parent type
---@param name any
---@return boolean
function Step:typeOf(name) end

--- Deserialises a pipeline from a definition table.
---@param def any
---@return Pipeline
function lurek.pipeline.fromTable(def) end

--- Creates a new empty pipeline with the given name (defaults to "pipeline").
---@param name? any (optional)
---@return Pipeline
function lurek.pipeline.newPipeline(name) end

--- Creates a new pipeline step with the given name and optional callback.
---@param name any
---@param callback? any (optional)
---@return PipelineStep
function lurek.pipeline.newStep(name, callback) end

---@class lurek.procgen
lurek.procgen = {}

--- Generates a dungeon using Binary Space Partitioning.
---@param opts? any (optional)
---@return table
function lurek.procgen.bspDungeon(opts) end

--- Generates a dungeon using Binary Space Partitioning.
---@param opts? any (optional)
---@return table
function lurek.procgen.bspDungeon(opts) end

--- Generates a cave-like map using cellular automata.
---@param w any
---@param h any
---@param opts? any (optional)
---@return table
function lurek.procgen.cellularAutomata(w, h, opts) end

--- BFS flood fill on a flat grid of bytes.
---@param data table
---@param w integer
---@param h integer
---@param sx integer
---@param sy integer
---@param threshold? integer? (optional)
---@param above? boolean? (optional)
---@return table
function lurek.procgen.floodFill(data, w, h, sx, sy, threshold, above) end

--- Generates a single procedural name using a Markov chain.
---@param samples table
---@param min_len? integer? (optional)
---@param max_len? integer? (optional)
---@param seed? integer? (optional)
---@return string
function lurek.procgen.generateName(samples, min_len, max_len, seed) end

--- Generates a single procedural name using a Markov chain.
---@param samples table
---@param min_len? integer? (optional)
---@param max_len? integer? (optional)
---@param seed? integer? (optional)
---@return string
function lurek.procgen.generateName(samples, min_len, max_len, seed) end

--- Generates N procedural names using a Markov chain.
---@param samples table
---@param n integer
---@param min_len? integer? (optional)
---@param max_len? integer? (optional)
---@param seed? integer? (optional)
---@return table
function lurek.procgen.generateNames(samples, n, min_len, max_len, seed) end

--- Generates N procedural names using a Markov chain.
---@param samples table
---@param n integer
---@param min_len? integer? (optional)
---@param max_len? integer? (optional)
---@param seed? integer? (optional)
---@return table
function lurek.procgen.generateNames(samples, n, min_len, max_len, seed) end

--- Generates a heightmap using fractal noise.
---@param opts? any (optional)
---@return table
function lurek.procgen.heightmap(opts) end

--- Generates a heightmap using fractal noise.
---@param opts? any (optional)
---@return table
function lurek.procgen.heightmap(opts) end

--- Generates an L-system string.
---@param opts any
---@return string
function lurek.procgen.lsystem(opts) end

--- Generates an L-system string.
---@param opts any
---@return string
function lurek.procgen.lsystem(opts) end

--- Generates L-system line segments for rendering.
---@param opts any
---@param angle_deg? any (optional)
---@param step? any (optional)
---@return table
function lurek.procgen.lsystemSegments(opts, angle_deg, step) end

--- Generates L-system line segments for rendering.
---@param opts any
---@param angle_deg? any (optional)
---@param step? any (optional)
---@return table
function lurek.procgen.lsystemSegments(opts, angle_deg, step) end

--- Generates a noise map using the configurable NoiseGenerator.
---@param width any
---@param height any
---@param opts? any (optional)
---@return table
function lurek.procgen.noiseMap(width, height, opts) end

--- Generates a noise map using the configurable NoiseGenerator.
---@param width any
---@param height any
---@param opts? any (optional)
---@return table
function lurek.procgen.noiseMap(width, height, opts) end

--- Generates a noise map using rayon parallel processing.
---@param width any
---@param height any
---@param opts? any (optional)
---@return table
function lurek.procgen.noiseMapParallel(width, height, opts) end

--- Generates a noise map using rayon parallel processing.
---@param width any
---@param height any
---@param opts? any (optional)
---@return table
function lurek.procgen.noiseMapParallel(width, height, opts) end

--- Evaluates periodic Perlin noise at a point.
---@param x any
---@param y any
---@param px any
---@param py any
---@return number
function lurek.procgen.perlinNoise(x, y, px, py) end

--- Generates Poisson disk sample points using Bridson's algorithm.
---@param w any
---@param h any
---@param min_dist any
---@param max_attempts? any (optional)
---@param seed? any (optional)
---@return table
function lurek.procgen.poissonDisk(w, h, min_dist, max_attempts, seed) end

--- Generates a rooms-and-corridors dungeon.
---@param opts? any (optional)
---@return table
function lurek.procgen.roomsDungeon(opts) end

--- Generates a rooms-and-corridors dungeon.
---@param opts? any (optional)
---@return table
function lurek.procgen.roomsDungeon(opts) end

--- Returns a single Simplex noise value at the given 2-D coordinate.
---@param x any
---@param y any
---@return number
function lurek.procgen.simplex2d(x, y) end

--- Returns a single Simplex noise value at the given 3-D coordinate.
---@param x any
---@param y any
---@param z any
---@return number
function lurek.procgen.simplex3d(x, y, z) end

--- Generates a Voronoi diagram for a set of seed points.
---@param w any
---@param h any
---@param pts_tbl any
---@param opts_tbl? any (optional)
---@return table
function lurek.procgen.voronoi(w, h, pts_tbl, opts_tbl) end

--- Generates a tile grid using Wave Function Collapse.
---@param opts any
---@return table
function lurek.procgen.wfcGenerate(opts) end

--- Generates a tile grid using Wave Function Collapse.
---@param opts any
---@return table
function lurek.procgen.wfcGenerate(opts) end

--- Generates a world graph with scattered regions and edges.
---@param width any
---@param height any
---@param region_count any
---@param seed? any (optional)
---@return table
function lurek.procgen.worldGraph(width, height, region_count, seed) end

--- Generates a world graph with scattered regions and edges.
---@param width any
---@param height any
---@param region_count any
---@param seed? any (optional)
---@return table
function lurek.procgen.worldGraph(width, height, region_count, seed) end

---@class lurek.raycaster
lurek.raycaster = {}

--- Lua-side wrapper around a [`DoorManager`], managing sliding doors in a level.
---@class DoorManager
local DoorManager = {}

--- Begins closing the door at the given index.
---@param index any
---@return nil
function DoorManager:closeDoor(index) end

--- Returns the number of registered doors.
---@return integer
function DoorManager:count() end

--- Returns the state table for door at index, or nil if out of range.
---@param index any
---@return nil
function DoorManager:getDoor(index) end

--- Begins opening the door at the given index.
---@param index any
---@return nil
function DoorManager:openDoor(index) end

--- Returns the type string "DoorManager".
---@return string
function DoorManager:type() end

--- Returns the type string "DoorManager".
---@return string
function DoorManager:typeOf() end

--- Advances all door animations by dt seconds.
---@param dt any
---@return nil
function DoorManager:update(dt) end

--- Lua-side wrapper around a [`HeightMap`] for variable floor/ceiling heights.
---@class HeightMap
local HeightMap = {}

--- Returns the ceiling height at (x, y). Returns 1.0 for out-of-bounds.
---@param x any
---@param y any
---@return number
function HeightMap:ceilingAt(x, y) end

--- Returns the floor height at (x, y). Returns 0.0 for out-of-bounds.
---@param x any
---@param y any
---@return number
function HeightMap:floorAt(x, y) end

--- Sets the ceiling height at (x, y).
---@param x any
---@param y any
---@param h any
---@return nil
function HeightMap:setCeiling(x, y, h) end

--- Sets the floor height at (x, y).
---@param x any
---@param y any
---@param h any
---@return nil
function HeightMap:setFloor(x, y, h) end

--- Returns the type string "HeightMap".
---@return string
function HeightMap:type() end

--- Returns the type string "HeightMap".
---@return string
function HeightMap:typeOf() end

--- Lua-side value wrapper around a raycaster [`PointLight`].
---@class PointLight
local PointLight = {}

--- Returns the RGB color as three separate values.
---@return number
function PointLight:color() end

--- Returns the intensity multiplier.
---@return number
function PointLight:intensity() end

--- Returns the illumination radius.
---@return number
function PointLight:radius() end

--- Returns the type string "PointLight".
---@return string
function PointLight:type() end

--- Returns the type string "PointLight".
---@return string
function PointLight:typeOf() end

--- Returns the world-space X position.
---@return number
function PointLight:x() end

--- Returns the world-space Y position.
---@return number
function PointLight:y() end

--- Lua-side wrapper around a [`Raycaster2D`] grid.
---@class Raycaster
local Raycaster = {}

--- Returns the cell value at (x, y).
---@param x any
---@param y any
---@return integer
function Raycaster:getCell(x, y) end

--- Returns the opacity for a wall tile type. Returns 1.0 if not set.
---@param tile_type any
---@return number
function Raycaster:getWallAlpha(tile_type) end

--- Returns the grid height in cells.
---@return integer
function Raycaster:height() end

--- Returns true when the cell at (x, y) is a wall (value > 0).
---@param x any
---@param y any
---@return boolean
function Raycaster:isBlocked(x, y) end

--- Sets the cell value at grid position (x, y).
---@param x any
---@param y any
---@param val any
---@return nil
function Raycaster:setCell(x, y, val) end

--- Replaces all grid cells from a flat array of values in row-major order.
---@param cells_tbl any
---@return nil
function Raycaster:setCells(cells_tbl) end

--- Sets the opacity for a wall tile type. Alpha is clamped to [0, 1].
---@param tile_type any
---@param alpha any
---@return nil
function Raycaster:setWallAlpha(tile_type, alpha) end

--- Returns the grid width in cells.
---@return integer
function Raycaster:width() end

--- Lua-side wrapper around a [`SpriteManager`] for batch depth-sorted sprite projection.
---@class SpriteManager
local SpriteManager = {}

--- Removes all sprites from the manager.
---@return nil
function SpriteManager:clear() end

--- Removes the sprite with the given id. No-op if not found.
---@param id any
---@return nil
function SpriteManager:remove(id) end

--- Moves the sprite with the given id to world (x, y).
---@param id any
---@param x any
---@param y any
---@return nil
function SpriteManager:setPosition(id, x, y) end

--- Shows or hides the sprite with the given id.
---@param id any
---@param visible any
---@return nil
function SpriteManager:setVisible(id, visible) end

--- Returns the type string "SpriteManager".
---@return string
function SpriteManager:type() end

--- Returns the type string "SpriteManager".
---@return string
function SpriteManager:typeOf() end

--- Returns distance-based brightness in [0, 1].
---@param distance any
---@param max_distance any
---@return number
function lurek.raycaster.distanceShade(distance, max_distance) end

--- Creates a new raycaster grid of the given dimensions.
---@param w any
---@param h any
---@return Raycaster
function lurek.raycaster.new(w, h) end

--- Creates a new empty door manager.
---@return DoorManager
function lurek.raycaster.newDoorManager() end

--- Creates a new height map with default floor (0.0) and ceiling (1.0) values.
---@param w any
---@param h any
---@return HeightMap
function lurek.raycaster.newHeightMap(w, h) end

--- Alias for `new`. Creates a new raycaster grid of the given dimensions.
---@param w any
---@param h any
---@return Raycaster
function lurek.raycaster.newMap(w, h) end

--- Creates a point light for use in raycaster scene lighting.
---@param x any
---@param y any
---@param r any
---@param g any
---@param b any
---@param radius any
---@param intensity any
---@return PointLight
function lurek.raycaster.newPointLight(x, y, r, g, b, radius, intensity) end

--- Creates a new empty batch sprite manager for depth-sorted projection.
---@return SpriteManager
function lurek.raycaster.newSpriteManager() end

--- Projects a wall distance to screen-space drawing parameters.
---@param distance any
---@param fov any
---@param screen_height any
---@return number
function lurek.raycaster.projectColumn(distance, fov, screen_height) end

---@class lurek.render
lurek.render = {}

--- Lua-side handle to an off-screen render target stored in SharedState.
---@class Canvas
local Canvas = {}

--- Returns width and height of this canvas.
---@return integer
function Canvas:getDimensions() end

--- Returns the height of this canvas in pixels.
---@return integer
function Canvas:getHeight() end

--- Returns the width of this canvas in pixels.
---@return integer
function Canvas:getWidth() end

--- Releases GPU framebuffer memory for this canvas.
---@return boolean
function Canvas:release() end

--- Returns the type name of this object.
---@return string
function Canvas:type() end

--- Returns the type name of this object.
---@return string
function Canvas:typeOf() end

--- Lua-side z-ordered draw queue. Callbacks are sorted by z and called on `flush()`.
---@class DrawLayer
local DrawLayer = {}

--- Removes all queued callbacks without calling them.
---@return void
function DrawLayer:clear() end

--- Sorts and calls all queued callbacks, then empties the queue.
---@return nil
function DrawLayer:flush() end

--- Returns the number of queued callbacks.
---@return number
function DrawLayer:getCount() end

--- Queues a draw callback at the given z-order.
---@param z any
---@param f any
---@return nil
function DrawLayer:queue(z, f) end

--- Returns the string type identifier of this draw layer (e.g. `'sprite'`).
---@return string
function DrawLayer:type() end

--- Returns true if this object is an instance of the given type name.
---@param name any
---@return boolean
function DrawLayer:typeOf(name) end

--- Lua-side handle to a loaded font stored in SharedState.
---@class Font
local Font = {}

--- Returns the ascent of this font in pixels.
---@return number
function Font:getAscent() end

--- Returns the descent of this font in pixels.
---@return number
function Font:getDescent() end

--- Returns the line height of this font.
---@return number
function Font:getHeight() end

--- Returns the line height multiplier of this font.
---@return number
function Font:getLineHeight() end

--- Returns the rendered width of the given text string.
---@param text any
---@return number
function Font:getWidth(text) end

--- Wraps text to the given width and returns the lines.
---@param text any
---@param limit any
---@return nil
function Font:getWrap(text, limit) end

--- Releases this font and frees its atlas memory.
---@return boolean
function Font:release() end

--- Sets the line height multiplier for this font.
---@param height any
---@return nil
function Font:setLineHeight(height) end

--- Returns the type name of this object.
---@return string
function Font:type() end

--- Returns the type name of this object.
---@return string
function Font:typeOf() end

--- Lua-side handle to a loaded GPU texture stored in the engine's texture pool.
---@class Image
local Image = {}

--- Returns width and height of this image.
---@return integer
function Image:getDimensions() end

--- Returns the height of this image in pixels.
---@return integer
function Image:getHeight() end

--- Returns the width of this image in pixels.
---@return integer
function Image:getWidth() end

--- Releases the GPU texture memory for this image.
---@return boolean
function Image:release() end

--- Returns the type name of this object.
---@return string
function Image:type() end

--- Returns the type name of this object.
---@return string
function Image:typeOf() end

--- Lua-side handle to a loaded texture stored in SharedState.
---@class ImageData
local ImageData = {}

--- Returns the sum of absolute per-channel differences between this image and `other`.
---@param other_ud any
---@return integer
function ImageData:diff(other_ud) end

--- Returns the pixel height of this image buffer.
---@return integer
function ImageData:getHeight() end

--- Returns the pixel width of this image buffer.
---@return integer
function ImageData:getWidth() end

--- Applies a Lua function to every pixel in-place.
---@param callback any
---@return nil
function ImageData:mapPixels(callback) end

--- Returns a new ImageData scaled to the given dimensions using bilinear interpolation.
---@param w any
---@param h any
---@return nil
function ImageData:resize(w, h) end

--- Returns the type name "ImageData".
---@return string
function ImageData:type() end

--- Returns true when the given name matches "ImageData" or a parent type.
---@param name any
---@return boolean
function ImageData:typeOf(name) end

--- Lua-side handle to a mesh stored in SharedState.
---@class Mesh
local Mesh = {}

--- Returns vertex data at the given 1-based index.
---@param index any
---@return nil
function Mesh:getVertex(index) end

--- Returns the number of vertices in this mesh.
---@return integer
function Mesh:getVertexCount() end

--- Releases the GPU mesh resource, freeing VRAM immediately.
---@return boolean
function Mesh:release() end

--- Assigns a texture to this mesh.
---@param ud? any (optional)
---@return nil
function Mesh:setTexture(ud) end

--- Sets vertex data at the given 1-based index.
---@param index any
---@param data any
---@return nil
function Mesh:setVertex(index, data) end

--- Returns the type name of this object.
---@return string
function Mesh:type() end

--- Returns the type name of this object.
---@return string
function Mesh:typeOf() end

--- Lua-side 9-slice descriptor.
---@class NineSlice
local NineSlice = {}

--- Returns the four inset values as (top, right, bottom, left).
---@return number
function NineSlice:getInsets() end

--- Returns the width and height of the source texture.
---@return integer
function NineSlice:getTextureSize() end

--- Returns the type name "NineSlice".
---@return string
function NineSlice:type() end

--- Returns true when the given name matches "NineSlice" or a parent type.
---@param name any
---@return boolean
function NineSlice:typeOf(name) end

--- Lua-side quad viewport into a texture.
---@class Quad
local Quad = {}

--- Returns the reference texture dimensions.
---@return number
function Quad:getTextureDimensions() end

--- Returns the quad viewport rectangle.
---@return number
function Quad:getViewport() end

--- Returns the type name of this object.
---@return string
function Quad:type() end

--- Returns the type name of this object.
---@return string
function Quad:typeOf() end

--- Lua-side handle to a compiled shader stored in SharedState.
---@class Shader
local Shader = {}

--- Returns whether this shader has a uniform with the given name.
---@param name any
---@return boolean
function Shader:hasUniform(name) end

--- Releases the compiled GPU shader, freeing VRAM and shader slots.
---@return boolean
function Shader:release() end

--- Sends a uniform value to this shader.
---@param name any
---@param value any
---@return nil
function Shader:send(name, value) end

--- Returns the type name of this object.
---@return string
function Shader:type() end

--- Returns the type name of this object.
---@return string
function Shader:typeOf() end

--- Lua-side handle to a [`CompoundShape`] stored in [`SharedState::shapes`].
---@class Shape
local Shape = {}

--- Removes all commands and resets the shape to empty.
---@return nil
function Shape:clear() end

--- Returns the number of drawing commands currently stored.
---@return integer
function Shape:getCommandCount() end

--- Queues a line segment command.
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@return nil
function Shape:line(x1, y1, x2, y2) end

--- Queues a polyline command from variadic (x, y) coordinate pairs.
---@return nil
function Shape:polyline() end

--- Sets the stroke width for subsequent outlined primitives.
---@param w any
---@return nil
function Shape:setLineWidth(w) end

--- Returns the type name of this object.
---@return string
function Shape:type() end

--- Returns true if the given type name matches this object's type or any parent type.
---@param name any
---@return boolean
function Shape:typeOf(name) end

--- Lua-side handle to a sprite batch stored in SharedState.
---@class SpriteBatch
local SpriteBatch = {}

--- Removes all sprites from this batch.
---@return nil
function SpriteBatch:clear() end

--- Returns the maximum capacity of this batch.
---@return integer
function SpriteBatch:getBufferSize() end

--- Returns the number of sprites in this batch.
---@return integer
function SpriteBatch:getCount() end

--- Releases this sprite batch.
---@return boolean
function SpriteBatch:release() end

--- Returns the type name of this object.
---@return string
function SpriteBatch:type() end

--- Returns the type name of this object.
---@return string
function SpriteBatch:typeOf() end

--- Applies an affine transform matrix.
---@param mat any
function lurek.render.applyTransform(mat) end

--- Draws a partial circle arc at the given position with specified radius and angle range.
---@param mode string
---@param x number
---@param y number
---@param radius number
---@param angle1 number
---@param angle2 number
---@param segments? integer? (optional)
function lurek.render.arc(mode, x, y, radius, angle1, angle2, segments) end

--- Begins a Y/Z depth sort group. Draw commands until flushSortGroup are depth-sortable.
---@param id any
function lurek.render.beginSortGroup(id) end

--- Begins a Y/Z depth sort group identified by id.
---@param id any
function lurek.render.beginSortGroup(id) end

--- Calls the given callback with an ImageData captured from the current frame (stub: creates blank).
---@param callback any
---@return nil
function lurek.render.captureScreenshot(callback) end

--- Draws a filled or outlined circle at the given world-space position.
---@param mode any
---@param x any
---@param y any
---@param radius any
function lurek.render.circle(mode, x, y, radius) end

--- Clears the draw command queue (resets the screen).
---@param r? any (optional)
---@param g? any (optional)
---@param b? any (optional)
function lurek.render.clear(r, g, b) end

--- Resets the stencil mode to the default (keep / always / 0).
---@return nil
function lurek.render.clearStencil() end

--- Returns the name of the currently active named layer.
---@return string
function lurek.render.currentLayer() end

--- Draws a drawable (Image, Canvas, SpriteBatch, Mesh) at the given position.
---@param args any
---@return table|nil
function lurek.render.draw(args) end

--- Queues a beveled border rectangle with inner fill.
---@param x number
---@param y number
---@param w number
---@param h number
---@param bevelW? number? (optional)
---@param style? string? (optional)
---@param opts? table? (optional)
function lurek.render.drawBevelRect(x, y, w, h, bevelW, style, opts) end

--- Queues a beveled border rectangle.
---@param x any
---@param y any
---@param w any
---@param h any
---@param bevel_w? any (optional)
---@param style? any (optional)
---@param opts? any (optional)
function lurek.render.drawBevelRect(x, y, w, h, bevel_w, style, opts) end

--- Queues a convex polygon with per-vertex colours.
---@param vertices any
---@param colors any
---@param mode? any (optional)
function lurek.render.drawColoredPolygon(vertices, colors, mode) end

--- Queues a convex polygon with per-vertex colours.
---@param vertices any
---@param colors any
---@param mode? any (optional)
function lurek.render.drawColoredPolygon(vertices, colors, mode) end

--- Queues a cubic BĂ©zier curve from (x1,y1) to (x2,y2) with two control points.
---@param x1 number
---@param y1 number
---@param cx1 number
---@param cy1 number
---@param cx2 number
---@param cy2 number
---@param x2 number
---@param y2 number
---@param segments? integer? (optional)
function lurek.render.drawCubicBezier(x1, y1, cx1, cy1, cx2, cy2, x2, y2, segments) end

--- Queues a cubic BĂ©zier curve from (x1,y1) to (x2,y2) with two control points.
---@param x1 any
---@param y1 any
---@param cx1 any
---@param cy1 any
---@param cx2 any
---@param cy2 any
---@param x2 any
---@param y2 any
---@param segments? any (optional)
function lurek.render.drawCubicBezier(x1, y1, cx1, cy1, cx2, cy2, x2, y2, segments) end

--- Queues a gradient-filled rectangle. color1/color2 are {r,g,b,a} tables.
---@param x number
---@param y number
---@param w number
---@param h number
---@param color1 table
---@param color2 table
---@param direction? string? (optional)
function lurek.render.drawGradientRect(x, y, w, h, color1, color2, direction) end

--- Queues a gradient-filled rectangle. Both colors are RGBA tables {r,g,b,a} or positional {[1]=r,[2]=g,[3]=b,[4]=a}.
---@param x any
---@param y any
---@param w any
---@param h any
---@param c1 any
---@param c2 any
---@param dir? any (optional)
function lurek.render.drawGradientRect(x, y, w, h, c1, c2, dir) end

--- Queues a hexagonal tile at centre (cx, cy) with given circumradius.
---@param cx number
---@param cy number
---@param size number
---@param orientation? string? (optional)
---@param mode? string? (optional)
function lurek.render.drawHexTile(cx, cy, size, orientation, mode) end

--- Queues a hexagonal tile at centre (cx, cy) with given circumradius.
---@param cx any
---@param cy any
---@param size any
---@param orientation? any (optional)
---@param mode? any (optional)
function lurek.render.drawHexTile(cx, cy, size, orientation, mode) end

--- Queues a three-face isometric cube tile at screen position (sx, sy).
---@param sx number
---@param sy number
---@param halfW number
---@param halfH number
---@param opts? table? (optional)
function lurek.render.drawIsoCubeTile(sx, sy, halfW, halfH, opts) end

--- Queues a three-face isometric cube tile at screen position (sx, sy).
---@param sx any
---@param sy any
---@param half_w any
---@param half_h any
---@param opts? any (optional)
function lurek.render.drawIsoCubeTile(sx, sy, half_w, half_h, opts) end

--- Queues a 9-slice draw call inside lurek.render / lurek.render_ui.
---@param slice any
---@param x any
---@param y any
---@param w any
---@param h any
---@return nil
function lurek.render.drawNineSlice(slice, x, y, w, h) end

--- Queues a multi-segment vector path.
---@param path any
---@param mode? any (optional)
---@param close? any (optional)
function lurek.render.drawPath(path, mode, close) end

--- Queues a multi-segment vector path.
---@param path any
---@param mode? any (optional)
---@param close? any (optional)
function lurek.render.drawPath(path, mode, close) end

--- Queues a quadratic BĂ©zier curve from (x1,y1) to (x2,y2) with one control point.
---@param x1 number
---@param y1 number
---@param cx number
---@param cy number
---@param x2 number
---@param y2 number
---@param segments? integer? (optional)
function lurek.render.drawQuadBezier(x1, y1, cx, cy, x2, y2, segments) end

--- Must be called inside lurek.render or lurek.render_ui.
---@param x1 any
---@param y1 any
---@param cx any
---@param cy any
---@param x2 any
---@param y2 any
---@param segments? any (optional)
function lurek.render.drawQuadBezier(x1, y1, cx, cy, x2, y2, segments) end

--- Draws a portion of an image defined by a Quad.
---@param image Image
---@param quad Quad
---@param x? number? (optional)
---@param y? number? (optional)
---@param r? number? (optional)
---@param sx? number? (optional)
---@param sy? number? (optional)
---@param ox? number? (optional)
---@param oy? number? (optional)
function lurek.render.drawq(image, quad, x, y, r, sx, sy, ox, oy) end

--- Draws a filled or outlined ellipse with independent x/y radii.
---@param mode any
---@param x any
---@param y any
---@param rx any
---@param ry any
function lurek.render.ellipse(mode, x, y, rx, ry) end

--- Sorts and flushes all draw commands in the sort group.
---@param id any
function lurek.render.flushSortGroup(id) end

--- Sorts and flushes all draw commands in the sort group.
---@param id any
function lurek.render.flushSortGroup(id) end

--- Returns the current background color.
---@return number
function lurek.render.getBackgroundColor() end

--- Returns the current blend mode as a string.
---@return string
function lurek.render.getBlendMode() end

--- Returns the current canvas, or nil if drawing to screen.
---@return table|nil
function lurek.render.getCanvas() end

--- Returns the dimensions of a canvas.
---@param ud any
---@return integer
function lurek.render.getCanvasSize(ud) end

--- Returns the current drawing color.
---@return number
function lurek.render.getColor() end

--- Returns the current color mask.
function lurek.render.getColorMask() end

--- Returns the default texture filter mode.
---@return table|nil
function lurek.render.getDefaultFilter() end

--- Returns a built-in font by pixel height (snaps to nearest available size).
---@param pixel_height? any (optional)
---@return Font
function lurek.render.getDefaultFont(pixel_height) end

--- Returns the current depth mode as (mode, write).
---@return table|nil
function lurek.render.getDepthMode() end

--- Returns window width and height.
---@return integer
function lurek.render.getDimensions() end

--- Returns the currently active font, or nil.
---@return table|nil
function lurek.render.getFont() end

--- Returns the ascent of the given font.
---@param ud any
---@return number
function lurek.render.getFontAscent(ud) end

--- Returns the cell width of the given font (for monospaced bitmap fonts).
---@param ud any
---@return number
function lurek.render.getFontCellWidth(ud) end

--- Returns the descent of the given font.
---@param ud any
---@return number
function lurek.render.getFontDescent(ud) end

--- Returns the line height of the given font.
---@param ud any
---@return number
function lurek.render.getFontHeight(ud) end

--- Returns the line height of the given font (alias for getFontHeight).
---@param ud any
---@return number
function lurek.render.getFontLineHeight(ud) end

--- Returns a table of available built-in font pixel heights.
---@return table
function lurek.render.getFontSizes() end

--- Returns the pixel width of text in the given font.
---@param ud any
---@param text any
---@return number
function lurek.render.getFontWidth(ud, text) end

--- Returns wrapped lines and the maximum line width.
---@param text any
---@param limit any
---@return table|nil
function lurek.render.getFontWrap(text, limit) end

--- Returns the window height in pixels.
---@return integer
function lurek.render.getHeight() end

--- Returns the z-order of the named layer, or `0` if unregistered.
---@param name any
---@return integer
function lurek.render.getLayerZOrder(name) end

--- Returns the current line width.
---@return number
function lurek.render.getLineWidth() end

--- Returns the current point size.
---@return number
function lurek.render.getPointSize() end

--- Returns the active scissor rectangle, or nothing.
---@return table|nil
function lurek.render.getScissor() end

--- Returns the active shader, or nil.
---@return table|nil
function lurek.render.getShader() end

--- Returns a table of renderer statistics.
---@return table
function lurek.render.getStats() end

--- Returns the current stencil mode as (action, compare, value).
---@return table|nil
function lurek.render.getStencilMode() end

--- Returns the window width in pixels.
---@return integer
function lurek.render.getWidth() end

--- Intersects the current scissor with a new rectangle.
---@param x any
---@param y any
---@param w any
---@param h any
function lurek.render.intersectScissor(x, y, w, h) end

--- Returns `true` if the named layer is visible (default: `true`).
---@param name any
---@return boolean
function lurek.render.isLayerVisible(name) end

--- Returns whether wireframe mode is active.
---@return boolean
function lurek.render.isWireframe() end

--- Draws a line between two points.
---@param args any
function lurek.render.line(args) end

--- Creates an off-screen render canvas.
---@param width any
---@param height any
---@return Canvas
function lurek.render.newCanvas(width, height) end

--- Creates a new z-ordered draw-call queue.
---@return DrawLayer
function lurek.render.newDrawLayer() end

--- Loads a bitmap font PNG from a file, or selects a built-in size by pixel height.
---@param args any
---@return Font
function lurek.render.newFont(args) end

--- Loads an image from a file path or creates one from ImageData.
---@param arg any
---@return Image
function lurek.render.newImage(arg) end

--- Registers a named render layer with an optional z-order (default 0).
---@param name any
---@param z_order? any (optional)
---@return nil
function lurek.render.newLayer(name, z_order) end

--- Creates a custom mesh from vertex data.
---@param verts any
---@param mode? any (optional)
---@return Mesh
function lurek.render.newMesh(verts, mode) end

--- Creates a 9-slice descriptor from a texture and inset values.
---@param image any
---@param top any
---@param right any
---@param bottom any
---@param left any
---@return NineSlice
function lurek.render.newNineSlice(image, top, right, bottom, left) end

--- Creates a new Quad viewport into a texture.
---@param x any
---@param y any
---@param w any
---@param h any
---@param sw any
---@param sh any
---@return Quad
function lurek.render.newQuad(x, y, w, h, sw, sh) end

--- Compiles a custom WGSL shader and returns its handle.
---@param code any
---@return Shader
function lurek.render.newShader(code) end

--- Creates a new empty [`CompoundShape`] stored in the resource pool.
---@return Shape
function lurek.render.newShape() end

--- Creates a new sprite batch for the given image.
---@param ud any
---@param max? any (optional)
---@return SpriteBatch
function lurek.render.newSpriteBatch(ud, max) end

--- Resets the transform to the identity.
function lurek.render.origin() end

--- Draws a batch of individual points at the specified world-space coordinates.
---@param args any
function lurek.render.points(args) end

--- Draws a polygon from a list of vertices.
---@param args any
function lurek.render.polygon(args) end

--- Pops the transform from the stack.
function lurek.render.pop() end

--- Ends and composites the named layer back to its parent.
---@param id any
function lurek.render.popLayer(id) end

--- Ends and composites the named layer.
---@param id any
function lurek.render.popLayer(id) end

--- Draws text at the given position.
---@param text any
---@param x? any (optional)
---@param y? any (optional)
---@param scale? any (optional)
function lurek.render.print(text, x, y, scale) end

--- Draws a sequence of individually-styled text spans at `(x, y)`.
---@param spans_table any
---@param x any
---@param y any
function lurek.render.printRich(spans_table, x, y) end

--- Draws word-wrapped text within a given width.
---@param text any
---@param x any
---@param y any
---@param limit any
---@param align? any (optional)
function lurek.render.printf(text, x, y, limit, align) end

--- Pushes the current transform onto the stack.
function lurek.render.push() end

--- Begins a named compositing layer with optional alpha and blend mode.
---@param id any
---@param alpha? any (optional)
---@param blend_mode? any (optional)
function lurek.render.pushLayer(id, alpha, blend_mode) end

--- Begins a named compositing layer. Provides alpha and blend mode for composite.
---@param id any
---@param alpha? any (optional)
---@param blend_mode? any (optional)
function lurek.render.pushLayer(id, alpha, blend_mode) end

--- Associates the previous draw command with a depth value within the active sort group.
---@param depth any
function lurek.render.pushSortKey(depth) end

--- Associates the previous draw command with a depth value within the active sort group.
---@param depth any
function lurek.render.pushSortKey(depth) end

--- Draws a filled or outlined axis-aligned rectangle at the given position.
---@param mode string
---@param x number
---@param y number
---@param w number
---@param h number
---@param rx? number? (optional)
---@param ry? number? (optional)
function lurek.render.rectangle(mode, x, y, w, h, rx, ry) end

--- Rotates the coordinate system.
---@param angle any
function lurek.render.rotate(angle) end

--- Queues a screenshot to be saved after the current frame.
---@param path any
function lurek.render.saveScreenshot(path) end

--- Scales the coordinate system.
---@param sx any
---@param sy? any (optional)
function lurek.render.scale(sx, sy) end

--- Sets the background clear color.
---@param r any
---@param g any
---@param b any
function lurek.render.setBackgroundColor(r, g, b) end

--- Sets the blend mode for drawing.
---@param mode any
function lurek.render.setBlendMode(mode) end

--- Sets the active render target to a Canvas, or back to the screen.
---@param ud? any (optional)
function lurek.render.setCanvas(ud) end

--- Sets the current drawing color.
---@param r any
---@param g any
---@param b any
---@param a? any (optional)
function lurek.render.setColor(r, g, b, a) end

--- Sets which RGBA channels are written. Reset with no args.
---@param args any
function lurek.render.setColorMask(args) end

--- Sets the default texture filter mode.
---@param min any
---@param mag any
---@param anisotropy? any (optional)
function lurek.render.setDefaultFilter(min, mag, anisotropy) end

--- Sets the depth test comparison and write enable.
---@param mode any
---@param write? any (optional)
function lurek.render.setDepthMode(mode, write) end

--- Sets the active font for print calls.
---@param ud any
function lurek.render.setFont(ud) end

--- Sets the line height of the given font (stub â€” returns nil; fonts are immutable in headless mode).
---@param font any
---@param lh any
---@return nil
function lurek.render.setFontLineHeight(font, lh) end

--- Sets the active named layer. Draw calls made after this will be
---@param name any
---@return nil
function lurek.render.setLayer(name) end

--- Shows or hides the named layer. Hidden layers are excluded from
---@param name any
---@param visible any
---@return nil
function lurek.render.setLayerVisible(name, visible) end

--- Updates the z-order of the named layer. Auto-creates the layer if
---@param name any
---@param z any
---@return nil
function lurek.render.setLayerZOrder(name, z) end

--- Sets the line width for outline drawing.
---@param w any
function lurek.render.setLineWidth(w) end

--- Sets the point diameter in pixels.
---@param size any
function lurek.render.setPointSize(size) end

--- Restricts drawing to a rectangle, or clears scissor if no args.
---@param args any
function lurek.render.setScissor(args) end

--- Sets the active shader, or clears it.
---@param ud? any (optional)
function lurek.render.setShader(ud) end

--- Sets the stencil buffer write/test mode.
---@param action any
---@param compare? any (optional)
---@param value? any (optional)
function lurek.render.setStencilMode(action, compare, value) end

--- Sets the stencil comparison test, or disables stencil testing.
---@param compare? any (optional)
---@param value? any (optional)
function lurek.render.setStencilTest(compare, value) end

--- Enables or disables wireframe rendering.
---@param enabled any
function lurek.render.setWireframe(enabled) end

--- Shears the coordinate system.
---@param kx any
---@param ky any
function lurek.render.shear(kx, ky) end

--- Begins stencil writing with the given action and value.
---@param action? any (optional)
---@param value? any (optional)
function lurek.render.stencil(action, value) end

--- Translates the coordinate system.
---@param x any
---@param y any
function lurek.render.translate(x, y) end

--- Draws a filled or outlined triangle connecting three world-space vertices.
---@param mode any
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@param x3 any
---@param y3 any
function lurek.render.triangle(mode, x1, y1, x2, y2, x3, y3) end

---@class lurek.save
lurek.save = {}

--- Lua-side wrapper around [`SaveManager`] with per-module callback storage.
---@class SaveManager
local SaveManager = {}

--- Collects data from all registered collectors into a table with metadata
---@return table
function SaveManager:collect() end

--- Deletes a save file for the given slot.
---@param slot any
---@return nil
function SaveManager:delete(slot) end

--- Disables automatic periodic saving; manual `write()` calls still work.
---@return nil
function SaveManager:disableAutoSave() end

--- Returns the current schema version
---@return integer
function SaveManager:getSchemaVersion() end

--- Returns metadata for a single slot, or nil if not found.
---@param slot any
---@return table?
function SaveManager:getSlotInfo(slot) end

--- Returns a list of all save slots with metadata.
---@return table
function SaveManager:getSlots() end

--- Returns the current summary string
---@return string
function SaveManager:getSummary() end

--- Returns whether compression is currently enabled.
---@return boolean
function SaveManager:isCompressed() end

--- Returns whether data has been modified since the last save or load
---@return boolean
function SaveManager:isDirty() end

--- Loads data from a slot file, applies migrations, and restores.
---@param slot any
---@return nil
function SaveManager:load(slot) end

--- Marks data as modified since the last save or load
---@return nil
function SaveManager:markDirty() end

--- Registers a callback that fires after every successful load operation.
---@param func any
---@return nil
function SaveManager:onAfterLoad(func) end

--- Registers a callback that fires before every save operation.
---@param func any
---@return nil
function SaveManager:onBeforeSave(func) end

--- Resets all state, removing callbacks and clearing the manager
---@return nil
function SaveManager:reset() end

--- Restores data from a table, applying migrations and calling restorers
---@param data any
---@return nil
function SaveManager:restore(data) end

--- Collects data and writes it to a slot file.
---@param slot any
---@return nil
function SaveManager:save(slot) end

--- Enables or disables LZ4 compression for saved data
---@param enabled any
---@return nil
function SaveManager:setCompress(enabled) end

--- Sets the current schema version for new saves
---@param version any
---@return nil
function SaveManager:setSchemaVersion(version) end

--- Sets the summary string included in save metadata
---@param summary any
---@return nil
function SaveManager:setSummary(summary) end

--- Removes a named module and its callbacks
---@param name any
---@return nil
function SaveManager:unregister(name) end

--- Advances the auto-save timer, returning the slot name if a save should trigger
---@param dt any
---@return string?
function SaveManager:update(dt) end

--- Creates a new SaveManager for slot-based save/load operations.
---@return SaveManager
function lurek.save.newSaveManager() end

---@class lurek.scene
lurek.scene = {}

--- Lua-side wrapper around a [`DepthSorter`] with registry-stored callbacks.
---@class DepthSorter
local DepthSorter = {}

--- Registers a draw callback at the given depth layer.
---@param callback any
---@param depth any
---@return nil
function DepthSorter:add(callback, depth) end

--- Registers a table object with a draw method at the given depth.
---@param obj any
---@return nil
function DepthSorter:addObject(obj) end

--- Removes all registered callbacks without calling them.
---@return nil
function DepthSorter:clear() end

--- Calls all draw callbacks in sorted depth order, then clears.
---@return nil
function DepthSorter:flush() end

--- Returns the number of registered draw entries.
---@return integer
function DepthSorter:getCount() end

--- Returns true if stable sort mode is enabled.
---@return boolean
function DepthSorter:isStable() end

--- Sets whether equal-depth entries preserve insertion order.
---@param stable any
---@return nil
function DepthSorter:setStable(stable) end

--- Sorts all registered callbacks by depth ascending.
---@return nil
function DepthSorter:sort() end

--- Clears all scenes from the stack, calling leave on each.
---@return nil
function lurek.scene.clear() end

--- Creates a reusable scene class â€” returns a zero-argument constructor function.
---@param def? any (optional)
---@return function
function lurek.scene.define(def) end

--- Returns the number of scenes on the stack.
---@return integer
function lurek.scene.depth() end

--- Restores scene data_refs from a snapshot produced by serializeScene().
---@param snapshot any
---@return nil
function lurek.scene.deserializeScene(snapshot) end

--- Draws all scenes in the stack from bottom to top (legacy name; prefer `render`).
---@return nil
function lurek.scene.draw() end

--- Returns a fade cross-dissolve transition config table.
---@param duration? any (optional)
---@return table|nil
function lurek.scene.fade(duration) end

--- Returns a table array of all active scene tables.
---@return table
function lurek.scene.getActiveScenes() end

--- Returns the current top scene table, or nil if the stack is empty.
---@return table?
function lurek.scene.getCurrent() end

--- Returns a value from the inter-scene data store, or nil if not found.
---@param key any
---@return table?
function lurek.scene.getData(key) end

--- Returns a registered scene table by name, or nil if not found.
---@param name any
---@return table?
function lurek.scene.getRegistered(name) end

--- Returns a list of all registered scene names.
---@return table
function lurek.scene.getRegisteredNames() end

--- Returns the number of scenes on the stack.
---@return integer
function lurek.scene.getStackSize() end

--- Returns the transition progress from 0.0 to 1.0.
---@return number
function lurek.scene.getTransitionProgress() end

--- Returns the easing-adjusted transition progress from 0.0 to 1.0.
---@return number
function lurek.scene.getTransitionProgressEased() end

--- Returns a table listing all supported transition type strings.
---@return table
function lurek.scene.getTransitionTypes() end

--- Returns true if the given key exists in the data store.
---@param key any
---@return boolean
function lurek.scene.hasData(key) end

--- Returns true if a scene is registered under the given name.
---@param name any
---@return boolean
function lurek.scene.hasRegistered(name) end

--- Returns an iris in/out (circular reveal) transition config table.
---@param duration? any (optional)
---@return table|nil
function lurek.scene.iris(duration) end

--- Returns true if the scene stack is empty.
---@return boolean
function lurek.scene.isEmpty() end

--- Returns true if the current top scene was pushed as an overlay.
---@return boolean
function lurek.scene.isOverlay() end

--- Returns true if the named scene has been preloaded.
---@param name any
---@return boolean
function lurek.scene.isPreloaded(name) end

--- Returns true if a scene transition is currently active.
---@return boolean
function lurek.scene.isTransitioning() end

--- Creates a scene instance directly from a methods table.
---@param def? any (optional)
---@return table
function lurek.scene.new(def) end

--- Creates a new DepthSorter for z-ordered draw batching.
---@return DepthSorter
function lurek.scene.newDepthSorter() end

--- Alias for `lurek.scene.new`. Creates a scene instance from a methods table.
---@param def? any (optional)
---@return table
function lurek.scene.newScene(def) end

--- Pops the top scene from the stack with an optional transition and easing.
---@param transition? any (optional)
---@param duration? any (optional)
---@param easing? any (optional)
---@return nil
function lurek.scene.pop(transition, duration, easing) end

--- Pops scenes until the named scene is on top, calling leave on each removed.
---@param name any
---@return boolean
function lurek.scene.popTo(name) end

--- Registers a loader function for a named scene. The loader is called
---@param name any
---@param loader any
---@return nil
function lurek.scene.preload(name, loader) end

--- Calls `scene:ready(self)` once per scene on the first tick after enter,
---@param dt any
---@return nil
function lurek.scene.process(dt) end

--- Calls `scene:process_late(dt)` on all active scenes (after process, before render).
---@param dt any
---@return nil
function lurek.scene.processLate(dt) end

--- Calls `scene:process_physics(dt)` on all active scenes (fixed timestep).
---@param dt any
---@return nil
function lurek.scene.processPhysics(dt) end

--- Pushes a scene table onto the stack with an optional transition and easing.
---@param scene table
---@param transition? string? (optional)
---@param duration? number? (optional)
---@param easing? string? (optional)
---@param params? table? (optional)
---@return nil
function lurek.scene.push(scene, transition, duration, easing, params) end

--- Pushes a scene as a non-pausing overlay over the current top scene.
---@param scene table
---@param transition? string? (optional)
---@param duration? number? (optional)
---@param easing? string? (optional)
---@param params? table? (optional)
---@return nil
function lurek.scene.pushOverlay(scene, transition, duration, easing, params) end

--- Pushes a registered scene by name, running its loader if not yet preloaded.
---@param name string
---@param transition? string? (optional)
---@param duration? number? (optional)
---@param easing? string? (optional)
---@param params? table? (optional)
---@return nil
function lurek.scene.pushPreloaded(name, transition, duration, easing, params) end

--- Registers a scene table by name for later retrieval.
---@param name any
---@param scene any
---@return nil
function lurek.scene.registerScene(name, scene) end

--- Removes a value from the inter-scene data store by key.
---@param key any
---@return nil
function lurek.scene.removeData(key) end

--- Draws all scenes in the stack from bottom to top.
---@return nil
function lurek.scene.render() end

--- Draws UI overlay for all scenes in the stack from bottom to top.
---@return nil
function lurek.scene.renderUi() end

--- Returns a snapshot of the scene stack as a Lua table: { stack=[name...], data={key=val} }.
---@return table
function lurek.scene.serializeScene() end

--- Stores a value in the inter-scene data store under the given key.
---@param key any
---@param value any
---@return nil
function lurek.scene.setData(key, value) end

--- Returns a directional slide transition config table.
---@param direction? any (optional)
---@param duration? any (optional)
---@return table|nil
function lurek.scene.slide(direction, duration) end

--- Replaces the top scene with a new one, calling leave and enter callbacks.
---@param scene table
---@param transition? string? (optional)
---@param duration? number? (optional)
---@param easing? string? (optional)
---@param params? table? (optional)
---@return nil
function lurek.scene.switchTo(scene, transition, duration, easing, params) end

--- Removes a scene from the registry by name.
---@param name any
---@return nil
function lurek.scene.unregisterScene(name) end

--- Updates the top scene and any active transition (legacy name; prefer `process`).
---@param dt any
---@return nil
function lurek.scene.update(dt) end

--- Returns a wipe/curtain transition config table.
---@param duration? any (optional)
---@return table|nil
function lurek.scene.wipe(duration) end

---@class lurek.serial
lurek.serial = {}

--- Decodes a binary MessagePack string into a Lua table.
---@param bytes string
---@return table
function lurek.serial.decodeMsgPack(bytes) end

--- Parses an XML string and returns a nested Lua table.
---@param s any
---@return table
function lurek.serial.decodeXml(s) end

--- Encodes a Lua table to a binary MessagePack string.
---@param value any
---@return string
function lurek.serial.encodeMsgPack(value) end

--- Parses a CSV string and returns a sequence of row tables.
---@param s any
---@param delim? any (optional)
---@param headers? any (optional)
---@return table
function lurek.serial.fromCsv(s, delim, headers) end

--- Parses a JSON string and returns a Lua table.
---@param s any
---@return table
function lurek.serial.fromJson(s) end

--- Parses a TOML string and returns a Lua table.
---@param s any
---@return table
function lurek.serial.fromToml(s) end

--- Serializes a sequence of row tables to a CSV string.
---@param value any
---@param delim? any (optional)
---@param headers? any (optional)
---@return string
function lurek.serial.toCsv(value, delim, headers) end

--- Serializes a Lua value to a JSON string.
---@param value any
---@param pretty? any (optional)
---@return string
function lurek.serial.toJson(value, pretty) end

--- Serializes a Lua table to a TOML string.
---@param value any
---@return string
function lurek.serial.toToml(value) end

--- Validates a Lua table against a schema table.
---@param value any
---@param schema any
function lurek.serial.validate(value, schema) end

---@class lurek.spine
lurek.spine = {}

--- Lua-side wrapper around a [`Skeleton`].
---@class Skeleton
local Skeleton = {}

--- Adds a SkeletonAnimation to this skeleton's library.
---@param anim_ud any
---@return nil
function Skeleton:addAnimation(anim_ud) end

--- Registers a new empty skin by name.
---@param name any
---@return nil
function Skeleton:addSkin(name) end

--- Returns the total number of bones.
---@return integer
function Skeleton:boneCount() end

--- Renders the skeleton as a stick-figure debug view into a new ImageData.
---@param w any
---@param h any
---@return ImageData
function Skeleton:drawToImage(w, h) end

--- Returns the index of the named bone, or nil if not found.
---@param name any
---@return integer?
function Skeleton:findBone(name) end

--- Returns the index of the named slot, or nil if not found.
---@param name any
---@return integer?
function Skeleton:findSlot(name) end

--- Returns the current playback time in seconds of the active animation.
---@return number
function Skeleton:getAnimationTime() end

--- Returns the world-space transform of a bone as a table, or nil if out of range.
---@param idx any
---@return table?
function Skeleton:getBoneWorld(idx) end

--- Returns the name of the currently active skin, or nil.
---@return string?
function Skeleton:getSkin() end

--- Sets the root bone position and propagates world transforms.
---@param x any
---@param y any
---@return nil
function Skeleton:setPosition(x, y) end

--- Activates the named skin for attachment lookups.
---@param name any
---@return boolean
function Skeleton:setSkin(name) end

--- Returns the total number of slots.
---@return integer
function Skeleton:slotCount() end

--- Stops the current skeletal animation.
---@return nil
function Skeleton:stopAnimation() end

--- Advances the playing animation by `dt` seconds and applies keyframes.
---@param dt any
---@return nil
function Skeleton:updateAnimation(dt) end

--- Propagates local transforms down the bone hierarchy to compute world positions.
---@return nil
function Skeleton:updateWorldTransforms() end

--- Lua-side wrapper around a [`SkeletonAnimation`] keyframe clip.
---@class SkeletonAnimation
local SkeletonAnimation = {}

--- Returns the total duration of the animation in seconds.
---@return number
function SkeletonAnimation:getDuration() end

--- Returns a list of event names that fall in the half-open interval `(from, to]`.
---@param from any
---@param to any
---@return nil
function SkeletonAnimation:getEvents(from, to) end

--- Returns the number of bone timelines in this animation.
---@return integer
function SkeletonAnimation:getTimelineCount() end

--- Creates a new empty skeleton with the given name.
---@param name any
---@return Skeleton
function lurek.spine.newSkeleton(name) end

--- Creates a new empty SkeletonAnimation clip with the given name and duration.
---@param name any
---@param duration any
---@return SkeletonAnimation
function lurek.spine.newSkeletonAnimation(name, duration) end

---@class lurek.sprite
lurek.sprite = {}

--- Lua-side wrapper around a [`SpriteAtlas`] named-region store.
---@class SpriteAtlas
local SpriteAtlas = {}

--- Returns the total number of named regions in the atlas.
---@return integer
function SpriteAtlas:entryCount() end

--- Returns a sequential table of all region names.
---@return table
function SpriteAtlas:entryNames() end

--- Returns the region at the given 1-based insertion index, or nil.
---@param index any
---@return table?
function SpriteAtlas:getByIndex(index) end

--- Returns the named region as a table `{name, x, y, w, h, rotated}`, or nil.
---@param name any
---@return table?
function SpriteAtlas:getEntry(name) end

--- Lua-side wrapper around a [`SpriteSheet`] frame-grid calculator.
---@class SpriteSheet
local SpriteSheet = {}

--- Renders the sheet grid as a debug view into a new ImageData.
---@param w any
---@param h any
---@return ImageData
function SpriteSheet:drawToImage(w, h) end

--- Returns a sequential table of quad tables for every frame in the given column.
---@param col any
---@return table
function SpriteSheet:getColumn(col) end

--- Returns the quad for the 0-based frame index, or nil if out of range.
---@param index any
---@return table?
function SpriteSheet:getFrame(index) end

--- Returns the total number of frames in the sheet.
---@return integer
function SpriteSheet:getFrameCount() end

--- Returns the width and height of a single frame cell in pixels.
---@return integer
function SpriteSheet:getFrameSize() end

--- Returns the number of columns and rows in the grid.
---@return integer
function SpriteSheet:getGridSize() end

--- Returns a sequential table of quad tables for the named frame group, or nil.
---@param name any
---@return table?
function SpriteSheet:getGroupFrames(name) end

--- Returns a sequential table of all defined group names.
---@return table
function SpriteSheet:getGroupNames() end

--- Returns a sequential table of quad tables for every frame in the given row.
---@param row any
---@return table
function SpriteSheet:getRow(row) end

--- Builds a SpriteSheet whose frames come from named entries in a SpriteAtlas.
---@param atlas_ud any
---@param sw any
---@param sh any
---@return SpriteSheet
function lurek.sprite.newAtlasSheet(atlas_ud, sw, sh) end

--- Creates an RPGMaker VX/Ace character sheet (3 cols Ă— 4 rows) with "down", "left", "right", "up" groups.
---@param tw any
---@param th any
---@return SpriteSheet
function lurek.sprite.newRPGMakerSheet(tw, th) end

--- Creates a sprite sheet with a uniform grid of `frame_w Ă— frame_h` frames.
---@param tw any
---@param th any
---@param fw any
---@param fh any
---@return SpriteSheet
function lurek.sprite.newSheet(tw, th, fw, fh) end

--- Parses an Aseprite JSON export string and returns a `SpriteAtlas`.
---@param json_str any
---@return SpriteAtlas
function lurek.sprite.parseAsepriteAtlas(json_str) end

--- Parses a TexturePacker JSON string (hash or array format) and returns a SpriteAtlas.
---@param json_str any
---@return SpriteAtlas
function lurek.sprite.parseAtlas(json_str) end

---@class lurek.system
lurek.system = {}

--- Serialises an engine error message to a compact JSON string.
---@param msg any
---@return string
function lurek.system.errorSnapshot(msg) end

--- Returns the CPU architecture string for the current machine.
---@return string
function lurek.system.getArch() end

--- Returns the command-line arguments as a table.
---@return table
function lurek.system.getArgs() end

--- Returns the output table from the most recently completed runBatch call.
---@param results any
---@return integer
function lurek.system.getBatchResults(results) end

--- Returns the current contents of the system clipboard.
---@return string
function lurek.system.getClipboardText() end

--- Returns whether the debug overlay is currently visible.
function lurek.system.getDebugOverlay() end

--- Returns the value of an environment variable, or nil if not set.
---@param name any
function lurek.system.getEnv(name) end

--- Returns a table of system information including OS name, CPU model, and installed RAM.
---@return table
function lurek.system.getInfo() end

--- Returns the last unhandled error message, or nil.
---@return table?
function lurek.system.getLastError() end

--- Returns the name of the current minimum log level for runtime messages.
function lurek.system.getLogLevel() end

--- Returns the total amount of installed system RAM in megabytes.
---@return integer
function lurek.system.getMemorySize() end

--- Resolves a stable runtime message ID such as 'L001' to its human-readable text.
---@param id any
---@return string
function lurek.system.getMessage(id) end

--- Returns the total number of message entries loaded into the runtime message catalog.
---@return integer
function lurek.system.getMessageCount() end

--- Returns the host operating system name ('Windows', 'Linux', 'macOS').
---@return string
function lurek.system.getOS() end

--- Returns battery state, percentage charged, and estimated time remaining.
---@return table
function lurek.system.getPowerInfo() end

--- Returns an ordered list of the user's preferred locale strings (e.g. 'en-US').
---@return table
function lurek.system.getPreferredLocales() end

--- Returns the number of logical CPU cores available.
---@return integer
function lurek.system.getProcessorCount() end

--- Returns the Lurek2D engine version string.
---@return string
function lurek.system.getVersion() end

--- Returns true when the runtime message catalog contains the given stable message ID.
---@param id any
---@return boolean
function lurek.system.hasMessage(id) end

--- Emit a log message from Lua at the specified level.
---@param level any
---@param message any
function lurek.system.log(level, message) end

--- Opens a URL in the system's default browser.
---@param url any
---@return boolean
function lurek.system.openURL(url) end

--- Parses a command-line argument string and returns a structured key/value table.
---@param args? any (optional)
---@return table
function lurek.system.parseArgs(args) end

--- Runs a list of shell commands in parallel and returns immediately without blocking.
---@param tasks any
---@param opts? any (optional)
---@return table
function lurek.system.runBatch(tasks, opts) end

--- Replaces the system clipboard contents with the given string.
---@param text any
function lurek.system.setClipboardText(text) end

--- Shows or hides the FPS/draw-call debug overlay.
---@param enabled any
function lurek.system.setDebugOverlay(enabled) end

--- Sets the minimum severity level for runtime log messages.
---@param level any
function lurek.system.setLogLevel(level) end

---@class lurek.terminal
lurek.terminal = {}

--- Lua-side wrapper around a [`Terminal`] with widget binding management.
---@class Terminal
local Terminal = {}

--- Attaches a widget to this terminal.
---@param widget_ud any
---@return nil
function Terminal:addWidget(widget_ud) end

--- Resizes the window to exactly fit the terminal grid at the current font size.
---@return nil
function Terminal:autoResize() end

--- Clears all cells to defaults.
---@return nil
function Terminal:clear() end

--- Detaches all widgets from this terminal.
---@return nil
function Terminal:clearWidgets() end

--- Returns the cell data at 1-based coordinates.
---@param col any
---@param row any
---@return nil
function Terminal:get(col, row) end

--- Returns the current cell size in pixels derived from the active font.
---@return integer
function Terminal:getCellSize() end

--- Returns the active cell size override as `{w, h}`, or `nil` if none is set.
---@return table?
function Terminal:getCellSize() end

--- Returns the terminal grid dimensions.
---@return integer
function Terminal:getDimensions() end

--- Returns the currently focused widget, or nil.
---@return nil
function Terminal:getFocused() end

--- Returns the number of attached widgets.
---@return integer
function Terminal:getWidgetCount() end

--- Routes a key press to the focused widget and fires callbacks.
---@param key any
---@return boolean
function Terminal:keypressed(key) end

--- Detaches a widget from this terminal.
---@param widget_ud any
---@return nil
function Terminal:removeWidget(widget_ud) end

--- Renders the terminal grid and widgets as render commands.
---@param x? any (optional)
---@param y? any (optional)
---@return nil
function Terminal:render(x, y) end

--- Removes the cell size override, restoring font-derived cell dimensions.
---@return nil
function Terminal:resetCellSize() end

--- Sets a cell at 1-based coordinates with character FG and BG colours.
---@param args any
---@return nil
function Terminal:set(args) end

--- Sets a per-terminal cell pixel size override, bypassing the font-derived size.
---@param w any
---@param h any
---@return nil
function Terminal:setCellSize(w, h) end

--- Sets the focused widget, or clears focus if nil is passed.
---@param value any
---@return nil
function Terminal:setFocus(value) end

--- Sets the terminal font by pixel height, snapping to the nearest built-in size.
---@param height any
---@return nil
function Terminal:setFont(height) end

--- Routes text input to the focused widget and fires callbacks.
---@param text any
---@return boolean
function Terminal:textinput(text) end

--- Lua-side wrapper around a [`Widget`] with attachment and callback state.
---@class Widget
local Widget = {}

--- Adds a child widget to a panel widget.
---@param child_ud any
---@return nil
function Widget:addChild(child_ud) end

--- Adds an item to a list widget.
---@param item any
---@return nil
function Widget:addItem(item) end

--- Removes all children from a panel widget.
---@return nil
function Widget:clearChildren() end

--- Removes all items from a list widget.
---@return nil
function Widget:clearItems() end

--- Returns a child widget from a panel by 1-based index, or nil.
---@param index any
---@return nil
function Widget:getChild(index) end

--- Returns the number of children in a panel widget.
---@return integer
function Widget:getChildCount() end

--- Returns the colour of a label or border widget.
---@return number
function Widget:getColor() end

--- Returns a list item by 1-based index.
---@param index any
---@return string
function Widget:getItem(index) end

--- Returns the number of items in a list widget.
---@return integer
function Widget:getItemCount() end

--- Returns the maximum character length of a text box widget.
---@return integer
function Widget:getMaxLength() end

--- Returns the widget position as 1-based coordinates.
---@return integer
function Widget:getPosition() end

--- Returns the selected item index (1-based) in a list widget, or nil.
---@return integer?
function Widget:getSelected() end

--- Returns the widget size in cells.
---@return integer
function Widget:getSize() end

--- Returns the border style name of a border widget.
---@return string
function Widget:getStyle() end

--- Returns the free-form identification tag.
---@return string
function Widget:getTag() end

--- Returns the text content of a label, button, or text box widget.
---@return string
function Widget:getText() end

--- Returns the title of a border widget.
---@return string
function Widget:getTitle() end

--- Returns whether the widget accepts input.
---@return boolean
function Widget:isEnabled() end

--- Returns whether the widget is visible.
---@return boolean
function Widget:isVisible() end

--- Removes a child widget from a panel widget.
---@param child_ud any
---@return nil
function Widget:removeChild(child_ud) end

--- Removes an item from a list widget by 1-based index.
---@param index any
---@return nil
function Widget:removeItem(index) end

--- Sets whether the widget accepts input.
---@param enabled any
---@return nil
function Widget:setEnabled(enabled) end

--- Sets the maximum character length of a text box widget.
---@param max_length any
---@return nil
function Widget:setMaxLength(max_length) end

--- Registers a text change callback for a text box widget.
---@param callback? any (optional)
---@return nil
function Widget:setOnChange(callback) end

--- Registers a click callback for a button widget.
---@param callback? any (optional)
---@return nil
function Widget:setOnClick(callback) end

--- Registers a selection change callback for a list widget.
---@param callback? any (optional)
---@return nil
function Widget:setOnSelect(callback) end

--- Sets the widget position from 1-based coordinates.
---@param col any
---@param row any
---@return nil
function Widget:setPosition(col, row) end

--- Sets the selected item in a list widget by 1-based index.
---@param index? any (optional)
---@return nil
function Widget:setSelected(index) end

--- Sets the widget size in cells.
---@param width any
---@param height any
---@return nil
function Widget:setSize(width, height) end

--- Sets the border style of a border widget.
---@param style_name any
---@return nil
function Widget:setStyle(style_name) end

--- Sets the free-form identification tag.
---@param tag any
---@return nil
function Widget:setTag(tag) end

--- Sets the text content of a label, button, or text box widget.
---@param text any
---@return nil
function Widget:setText(text) end

--- Sets the title of a border widget.
---@param title any
---@return nil
function Widget:setTitle(title) end

--- Sets the widget visibility.
---@param visible any
---@return nil
function Widget:setVisible(visible) end

--- Adds a candidate string to the tab-completion engine.
---@param candidate any
---@return nil
function lurek.terminal.addCompletion(candidate) end

--- Applies a named colour theme to a terminal, recolouring all existing cells.
---@param term_ud any
---@param theme any
---@return nil
function lurek.terminal.applyTheme(term_ud, theme) end

--- Clears all entries from this terminal's command history.
---@param term_ud any
---@return nil
function lurek.terminal.clearCmdHistory(term_ud) end

--- Clears all completion candidates.
---@return nil
function lurek.terminal.clearCompletions() end

--- Returns the total number of entries in this terminal's command history.
---@param term_ud any
---@return integer
function lurek.terminal.cmdHistoryLen(term_ud) end

--- Returns all registered candidates that start with `prefix`, as a sorted array.
---@param prefix any
---@return table
function lurek.terminal.getCompletions(prefix) end

--- Returns the maximum number of columns a Terminal can be constructed with.
---@return integer
function lurek.terminal.getMaxCols() end

--- Returns the maximum number of rows a Terminal can be constructed with.
---@return integer
function lurek.terminal.getMaxRows() end

--- Returns a table of lines from the scrollback buffer.
---@param term_ud any
---@param offset any
---@param count any
---@return table|nil
function lurek.terminal.getScrollback(term_ud, offset, count) end

--- Creates a new decorative border widget at 1-based coordinates.
---@param col any
---@param row any
---@param width any
---@param height any
---@return Widget
function lurek.terminal.newBorder(col, row, width, height) end

--- Creates a new button widget at 1-based coordinates.
---@param col integer
---@param row integer
---@param width integer
---@param height? integer? (optional)
---@param text? string? (optional)
---@return Widget
function lurek.terminal.newButton(col, row, width, height, text) end

--- Creates a new label widget at 1-based coordinates.
---@param col any
---@param row any
---@param text? any (optional)
---@return Widget
function lurek.terminal.newLabel(col, row, text) end

--- Creates a new scrollable list widget at 1-based coordinates.
---@param col any
---@param row any
---@param width any
---@param height any
---@return Widget
function lurek.terminal.newList(col, row, width, height) end

--- Creates a new container panel widget at 1-based coordinates.
---@param col any
---@param row any
---@param width? any (optional)
---@param height? any (optional)
---@return Widget
function lurek.terminal.newPanel(col, row, width, height) end

--- Creates a new terminal grid with the given dimensions.
---@param cols? any (optional)
---@param rows? any (optional)
---@return Terminal
function lurek.terminal.newTerminal(cols, rows) end

--- Creates a new single-line text box widget at 1-based coordinates.
---@param col any
---@param row any
---@param width any
---@return Widget
function lurek.terminal.newTextBox(col, row, width) end

--- Steps one entry forward in command history (toward newer commands).
---@param term_ud any
---@return string|nil
function lurek.terminal.nextCmd(term_ud) end

--- Returns the next candidate for `prefix`, cycling on repeated calls.
---@param prefix any
---@return string|nil
function lurek.terminal.nextCompletion(prefix) end

--- Parses `text` into coloured spans.  Returns an array of tables, each with
---@param text any
---@return table|nil
function lurek.terminal.parseAnsi(text) end

--- Steps one entry back in command history (toward older commands).
---@param term_ud any
---@return string|nil
function lurek.terminal.prevCmd(term_ud) end

--- Prints ANSI-escaped `text` onto terminal `t` starting at `(col, row)`.
---@param t_ud any
---@param col any
---@param row any
---@param text any
---@return nil
function lurek.terminal.printAnsi(t_ud, col, row, text) end

--- Prints text at 1-based `(col, row)` with per-keyword colour highlighting.
---@param terminal Terminal
---@param col integer
---@param row integer
---@param text string
---@param rules table
---@return nil
function lurek.terminal.printHighlighted(terminal, col, row, text, rules) end

--- Appends a command string to this terminal's history.
---@param term_ud any
---@param cmd any
---@return nil
function lurek.terminal.pushCmdHistory(term_ud, cmd) end

--- Appends a line to this terminal's scrollback buffer.
---@param term_ud any
---@param line any
---@return nil
function lurek.terminal.pushScrollback(term_ud, line) end

--- Removes a candidate string from the tab-completion engine.
---@param candidate any
---@return nil
function lurek.terminal.removeCompletion(candidate) end

--- Resets the cycling cursor without clearing the candidate list.
---@return nil
function lurek.terminal.resetCompletion() end

--- Returns the number of lines currently in this terminal's scrollback buffer.
---@param term_ud any
---@return integer
function lurek.terminal.scrollbackLen(term_ud) end

--- Sets the maximum number of lines retained in the scrollback buffer.
---@param term_ud any
---@param cap any
---@return nil
function lurek.terminal.setScrollbackCap(term_ud, cap) end

--- Strips all ANSI escape codes from `text` and returns the plain string.
---@param text any
---@return string
function lurek.terminal.stripAnsi(text) end

---@class lurek.thread
lurek.thread = {}

--- A synchronized message queue for cross-VM communication.
---@class Channel
local Channel = {}

--- Clears all items from the channel.
---@return nil
function Channel:clear() end

--- Blocks until a value is available or the timeout expires, then removes and returns it.
---@param timeout? any (optional)
---@return string|number|boolean|table|nil
function Channel:demand(timeout) end

--- Returns the number of items in the channel.
---@return integer
function Channel:getCount() end

--- Retrieves the value from the channel without removing it.
---@return string|number|boolean|table|nil
function Channel:peek() end

--- Retrieves and removes a value from the channel.
---@return string|number|boolean|table|nil
function Channel:pop() end

--- Pops a bytes value from the channel and returns it as a Lua string.
---@return string?
function Channel:popBytes() end

--- Pops a value from the channel expecting a table.
---@return table?
function Channel:popTable() end

--- Pushes a value to the channel.
---@param value any
---@return integer
function Channel:push(value) end

--- Pushes raw binary data (a Lua string treated as a byte array) to the channel.
---@param data any
---@return integer
function Channel:pushBytes(data) end

--- Serializes a Lua table and pushes it to the channel.
---@param value any
---@return integer
function Channel:pushTable(value) end

--- Blocks until the channel has space, then adds the value.
---@param value any
---@return nil
function Channel:supply(value) end

--- Returns the type of the object.
---@return string
function Channel:type() end

--- Checks if the object is of the specified type.
---@param name any
---@return boolean
function Channel:typeOf(name) end

--- Lua-side wrapper around a one-shot [`Promise`].
---@class Promise
local Promise = {}

--- Returns the worker error string if the promise failed, otherwise nil.
---@return string?
function Promise:getError() end

--- Returns true if the promise has a result or has errored (non-blocking).
---@return boolean
function Promise:isDone() end

--- Pops and returns the promise result, or nil if not yet ready.
---@return table|nil
function Promise:result() end

--- Returns the type name of this object.
---@return string
function Promise:type() end

--- Returns whether this object is of the given type.
---@param name any
---@return boolean
function Promise:typeOf(name) end

--- Lua-side wrapper around a background [`LuaThread`].
---@class ThreadHandle
local ThreadHandle = {}

--- Returns the error message if the thread failed, or nil.
---@return string?
function ThreadHandle:getError() end

--- Returns whether the thread is currently executing.
---@return boolean
function ThreadHandle:isRunning() end

--- Launches the background thread, passing optional arguments via varargs.
---@param args any
---@return nil
function ThreadHandle:start(args) end

--- Returns the type name of this object.
---@return string
function ThreadHandle:type() end

--- Returns whether this object is of the given type.
---@param name any
---@return boolean
function ThreadHandle:typeOf(name) end

--- Blocks the calling thread until the background thread finishes.
---@return nil
function ThreadHandle:wait() end

--- Lua-side wrapper around a [`ThreadPool`].
---@class ThreadPool
local ThreadPool = {}

--- Retrieves the next result from the pool's output channel (non-blocking).
---@return table|nil
function ThreadPool:collect() end

--- Returns the shared input Channel (main â†’ workers).
---@return Channel
function ThreadPool:getInputChannel() end

--- Returns the shared output Channel (workers â†’ main).
---@return Channel
function ThreadPool:getOutputChannel() end

--- Blocks until all workers in the pool have finished execution.
---@return nil
function ThreadPool:join() end

--- Returns the number of workers in this pool.
---@return integer
function ThreadPool:size() end

--- Submits a value to the pool's input channel for processing by a worker.
---@param value any
---@return nil
function ThreadPool:submit(value) end

--- Returns the type name of this object.
---@return string
function ThreadPool:type() end

--- Returns whether this object is of the given type.
---@param name any
---@return boolean
function ThreadPool:typeOf(name) end

--- Starts a one-shot background computation and returns a Promise.
---@param code any
---@param args any
---@return Promise
function lurek.thread.async(code, args) end

--- Gets or creates a named global channel shared across threads.
---@param name any
---@return Channel
function lurek.thread.getChannel(name) end

--- Creates an unnamed thread-safe channel for inter-thread communication.
---@return Channel
function lurek.thread.newChannel() end

--- Creates a thread pool of N workers all running the same Lua code.
---@param size any
---@param code any
---@return ThreadPool
function lurek.thread.newPool(size, code) end

--- Creates a new background thread from a Lua code string.
---@param code any
---@return Thread
function lurek.thread.newThread(code) end

---@class lurek.tilemap
lurek.tilemap = {}

--- Lua-side wrapper around an [`AutoTileSheet`].
---@class AutoTileSheet
local AutoTileSheet = {}

--- Returns the bitmask value associated with a 1-based local tile ID.
---@param tile_id any
---@return integer
function AutoTileSheet:getBitmaskForTile(tile_id) end

--- Returns the layout variant as a string.
---@return string
function AutoTileSheet:getLayout() end

--- Returns the atlas region rectangle for the 1-based tile ID.
---@param tile_id any
---@return number
function AutoTileSheet:getQuad(tile_id) end

--- Returns the number of tiles in this sheet.
---@return integer
function AutoTileSheet:getTileCount() end

--- Returns the 1-based tile ID for a given bitmask, or nil.
---@param bitmask any
---@return integer?
function AutoTileSheet:getTileForBitmask(bitmask) end

--- Returns the tile height in pixels.
---@return integer
function AutoTileSheet:getTileHeight() end

--- Returns the tile width in pixels.
---@return integer
function AutoTileSheet:getTileWidth() end

--- Lua-side wrapper around a [`ChunkMap`].
---@class ChunkMap
local ChunkMap = {}

--- Returns the tile coordinate range for chunk (cx, cy) as (x0, y0, x1, y1).
---@param cx any
---@param cy any
---@return integer
function ChunkMap:chunkTileRange(cx, cy) end

--- Clears the tile at (x, y) by setting its GID to 0.
---@param x any
---@param y any
---@return nil
function ChunkMap:clearTile(x, y) end

--- Returns the chunk size (tiles per side).
---@return integer
function ChunkMap:getChunkSize() end

--- Returns a table of all currently loaded chunk coordinates as {{cx, cy}, ...}.
---@return table
function ChunkMap:getLoadedChunks() end

--- Returns the GID at tile coordinate (x, y).
---@param x any
---@param y any
---@return integer
function ChunkMap:getTile(x, y) end

--- Pre-allocates the chunk at chunk coordinates (cx, cy).
---@param cx any
---@param cy any
---@return nil
function ChunkMap:loadChunk(cx, cy) end

--- Sets the GID at tile coordinate (x, y).
---@param x any
---@param y any
---@param gid any
---@return nil
function ChunkMap:setTile(x, y, gid) end

--- Removes the chunk at chunk coordinates (cx, cy) from memory.
---@param cx any
---@param cy any
---@return nil
function ChunkMap:unloadChunk(cx, cy) end

--- Lua-side wrapper around an [`IsoMap`].
---@class IsoMap
local IsoMap = {}

--- Appends a new empty Z-level and returns its 1-based index.
---@return integer
function IsoMap:addLevel() end

--- Fills every cell in level z with gid for the given part (1-based z; 0-based part).
---@param z any
---@param part any
---@param gid any
---@return nil
function IsoMap:fillLevel(z, part, gid) end

--- Returns the map height in tiles.
---@return integer
function IsoMap:getHeight() end

--- Returns the number of Z-levels currently in the map.
---@return integer
function IsoMap:getLevelCount() end

--- Returns the vertical pixel offset between consecutive Z-levels.
---@return integer
function IsoMap:getLevelHeight() end

--- Returns the number of GID slots per tile.
---@return integer
function IsoMap:getPartCount() end

--- Returns the current draw-order array (0-based part slot indices).
---@return table
function IsoMap:getPartOrder() end

--- Returns the tile footprint height in pixels.
---@return integer
function IsoMap:getTileHeight() end

--- Returns the tile footprint width in pixels.
---@return integer
function IsoMap:getTileWidth() end

--- Returns the map width in tiles.
---@return integer
function IsoMap:getWidth() end

--- Returns the visibility of a level (1-based z).
---@param z any
---@return boolean
function IsoMap:isLevelVisible(z) end

--- Converts screen pixel coordinates to isometric tile coordinates at Z-level 0.
---@param sx any
---@param sy any
---@return number
function IsoMap:screenToTile(sx, sy) end

--- Sets the visibility of a level (1-based z).
---@param z any
---@param visible any
---@return nil
function IsoMap:setLevelVisible(z, visible) end

--- Sets the screen pixel origin.
---@param x any
---@param y any
---@return nil
function IsoMap:setOrigin(x, y) end

--- Overrides the draw order for this IsoMap. Length must equal partCount.
---@param order any
---@return nil
function IsoMap:setPartOrder(order) end

--- Projects isometric tile coordinates (tx, ty, tz) to screen pixels.
---@param tx any
---@param ty any
---@param tz any
---@return number
function IsoMap:tileToScreen(tx, ty, tz) end

--- Lua-side wrapper around a [`LargeMapRenderer`] for chunk-level occlusion culling on large worlds.
---@class LargeMapRenderer
local LargeMapRenderer = {}

--- Returns the current chunk size.
---@return integer
function LargeMapRenderer:getChunkSize() end

--- Returns the map dimensions as (width, height) in tiles.
---@return integer
function LargeMapRenderer:getMapSize() end

--- Returns the tile ID at (x, y), or nil if out of bounds.
---@param x any
---@param y any
---@return integer?
function LargeMapRenderer:getTile(x, y) end

--- Returns the number of tileset atlas columns.
---@return integer
function LargeMapRenderer:getTilesetColumns() end

--- Returns the total number of chunks that cover the loaded map.
---@return integer
function LargeMapRenderer:getTotalChunks() end

--- Returns the number of chunks currently within the camera viewport.
---@return integer
function LargeMapRenderer:getVisibleChunks() end

--- Marks every chunk as dirty.
---@return nil
function LargeMapRenderer:invalidateAll() end

--- Marks a chunk at chunk-grid coordinates (cx, cy) as dirty,
---@param cx any
---@param cy any
---@return nil
function LargeMapRenderer:invalidateChunk(cx, cy) end

--- Returns whether LOD rendering is currently enabled.
---@return boolean
function LargeMapRenderer:isLodEnabled() end

--- Updates the camera position and zoom used for visibility culling.
---@param x any
---@param y any
---@param zoom any
---@return nil
function LargeMapRenderer:setCamera(x, y, zoom) end

--- Sets the chunk size used for culling (default 16).
---@param size any
---@return nil
function LargeMapRenderer:setChunkSize(size) end

--- Enables or disables level-of-detail rendering for distant chunks.
---@param enabled any
---@return nil
function LargeMapRenderer:setLodEnabled(enabled) end

--- Sets the distance thresholds (in tile units) at which each LOD level activates.
---@param levels any
---@return nil
function LargeMapRenderer:setLodThresholds(levels) end

--- Sets a single tile ID at (x, y).  Coordinates are 0-based.
---@param x any
---@param y any
---@param tile_id any
---@return nil
function LargeMapRenderer:setTile(x, y, tile_id) end

--- Sets the number of tile columns in the atlas texture used for UV calculation.
---@param cols any
---@return nil
function LargeMapRenderer:setTilesetColumns(cols) end

--- Sets the viewport dimensions in pixels used for visibility culling.
---@param w any
---@param h any
---@return nil
function LargeMapRenderer:setViewport(w, h) end

--- Lua-side wrapper around a [`MapBlock`].
---@class MapBlock
local MapBlock = {}

--- Returns the block dimensions as (width, height) in tiles.
---@return integer
function MapBlock:getDimensions() end

--- Returns the block height in tiles.
---@return integer
function MapBlock:getHeight() end

--- Returns the number of segments along the height.
---@return integer
function MapBlock:getHeightInSegments() end

--- Returns the number of layers in this block.
---@return integer
function MapBlock:getLayerCount() end

--- Returns the name of this block.
---@return string
function MapBlock:getName() end

--- Returns the segment size in tiles.
---@return integer
function MapBlock:getSegmentSize() end

--- Returns the side connection ID for a segment on a given edge.
---@param edge_str any
---@param segment any
---@return integer
function MapBlock:getSide(edge_str, segment) end

--- Returns the GID of the tile at (x, y) on the given layer (1-based).
---@param layer any
---@param x any
---@param y any
---@return integer
function MapBlock:getTile(layer, x, y) end

--- Returns the placement weight.
---@return number
function MapBlock:getWeight() end

--- Returns the block width in tiles.
---@return integer
function MapBlock:getWidth() end

--- Returns the number of segments along the width.
---@return integer
function MapBlock:getWidthInSegments() end

--- Sets the human-readable name of this block.
---@param name any
---@return nil
function MapBlock:setName(name) end

--- Sets the placement weight.
---@param weight any
---@return nil
function MapBlock:setWeight(weight) end

--- Lua-side wrapper around a [`MapGroup`].
---@class MapGroup
local MapGroup = {}

--- Adds a block to this group.
---@param block_ud any
---@return nil
function MapGroup:addBlock(block_ud) end

--- Adds a MapScript to this group.
---@param script_ud any
---@return nil
function MapGroup:addScript(script_ud) end

--- Returns the number of blocks in this group.
---@return integer
function MapGroup:getBlockCount() end

--- Returns the name of this group.
---@return string
function MapGroup:getName() end

--- Returns the number of scripts in this group.
---@return integer
function MapGroup:getScriptCount() end

--- Removes a block by 1-based index.
---@param idx any
---@return nil
function MapGroup:removeBlock(idx) end

--- Lua-side wrapper around a [`MapScript`] procedural generation script.
---@class MapScript
local MapScript = {}

--- Appends a generation step from a step-definition table.
---@param step_def any
---@return nil
function MapScript:addStep(step_def) end

--- Returns the number of steps in this script.
---@return integer
function MapScript:getStepCount() end

--- Lua-side wrapper around a [`TileMap`].
---@class TileMap
local TileMap = {}

--- Adds a new empty layer and returns its 1-based index.
---@param name any
---@param w any
---@param h any
---@return integer
function TileMap:addLayer(name, w, h) end

--- Adds a tileset to this map.
---@param ts_ud any
---@return nil
function TileMap:addTileSet(ts_ud) end

--- Clears a tile (sets GID to 0) at (x, y) on the given layer (1-based).
---@param layer any
---@param x any
---@param y any
---@return nil
function TileMap:clearTile(layer, x, y) end

--- Renders the tile map to a CPU ImageData using the given tile pixel size.
---@param tile_size any
---@return ImageData
function TileMap:drawToImage(tile_size) end

--- Fills an entire layer with the given GID (1-based layer).
---@param layer any
---@param gid any
---@return nil
function TileMap:fill(layer, gid) end

--- Fire the tile exit callback for the given GID (call when entity leaves tile).
---@param gid any
---@param entity any
---@param tx any
---@param ty any
---@return nil
function TileMap:fireTileExit(gid, entity, tx, ty) end

--- Fire the tile step callback for the given GID (call each frame while entity is on tile).
---@param gid any
---@param entity any
---@param tx any
---@param ty any
---@return nil
function TileMap:fireTileStep(gid, entity, tx, ty) end

--- Returns the chunk size used for spatial partitioning.
---@return integer
function TileMap:getChunkSize() end

--- Returns the RGBA tint color of a layer.
---@param idx any
---@return number
function TileMap:getLayerColor(idx) end

--- Returns the number of layers.
---@return integer
function TileMap:getLayerCount() end

--- Returns the name of a layer by 1-based index.
---@param idx any
---@return string?
function TileMap:getLayerName(idx) end

--- Returns the pixel offset of a layer.
---@param idx any
---@return number
function TileMap:getLayerOffset(idx) end

--- Returns the parallax factor of a layer.
---@param idx any
---@return number
function TileMap:getLayerParallax(idx) end

--- Returns layer visibility.
---@param idx any
---@return boolean
function TileMap:getLayerVisible(idx) end

--- Returns the map orientation as a string ("topdown", "sideview", "isometric", or "hexagonal").
---@return string
function TileMap:getOrientation() end

--- Returns the GID at (x, y) on the given layer (1-based).
---@param layer any
---@param x any
---@param y any
---@return integer
function TileMap:getTile(layer, x, y) end

--- Returns tile dimensions as (width, height).
---@return integer
function TileMap:getTileDimensions() end

--- Returns the tile height in pixels.
---@return integer
function TileMap:getTileHeight() end

--- Returns a tileset by 1-based index, or nil if out of range.
---@param idx any
---@return nil
function TileMap:getTileSet(idx) end

--- Returns the number of tilesets attached to this map.
---@return integer
function TileMap:getTileSetCount() end

--- Returns the tile width in pixels.
---@return integer
function TileMap:getTileWidth() end

--- Returns the viewport as (x, y, w, h) or nil if not set.
---@return number
function TileMap:getViewport() end

--- Returns true if the tile at (x, y) on layer is solid (1-based).
---@param layer any
---@param x any
---@param y any
---@return boolean
function TileMap:isSolid(layer, x, y) end

--- Register a callback for when an entity exits a tile with the given GID.
---@param gid any
---@param func any
---@return nil
function TileMap:onTileExit(gid, func) end

--- Register a callback for when an entity steps on a tile with the given GID.
---@param gid any
---@param func any
---@return nil
function TileMap:onTileStep(gid, func) end

--- Renders the tile map to the screen at the given offset.
---@param ox? any (optional)
---@param oy? any (optional)
---@return nil
function TileMap:render(ox, oy) end

--- Sets the map orientation from a string ("topdown", "sideview", "isometric", or "hexagonal").
---@param orientation any
---@return nil
function TileMap:setOrientation(orientation) end

--- Converts tile coordinates to world pixel coordinates (1-based input).
---@param tx any
---@param ty any
---@return number
function TileMap:tileToWorld(tx, ty) end

--- Advances tile animation timers by dt seconds.
---@param dt any
---@return nil
function TileMap:update(dt) end

--- Converts world pixel coordinates to tile coordinates.
---@param wx any
---@param wy any
---@return integer
function TileMap:worldToTile(wx, wy) end

--- Lua-side wrapper around a [`TileSet`].
---@class TileSet
local TileSet = {}

--- Returns the animation frames for a 1-based local tile ID as a table of {tileid, duration}, or nil.
---@param tile_id any
---@return table?
function TileSet:getAnimation(tile_id) end

--- Returns the number of tile columns in the atlas texture.
---@return integer
function TileSet:getColumns() end

--- Returns the first global ID assigned to this tileset.
---@return integer
function TileSet:getFirstGid() end

--- Returns the margin in pixels around the edges of the atlas.
---@return integer
function TileSet:getMargin() end

--- Computes the atlas source rectangle for a 1-based local tile ID.
---@param tile_id any
---@return nil
function TileSet:getQuad(tile_id) end

--- Returns the spacing in pixels between tiles in the atlas.
---@return integer
function TileSet:getSpacing() end

--- Returns the total number of tiles in this tileset.
---@return integer
function TileSet:getTileCount() end

--- Returns the tile dimensions as (width, height).
---@return integer
function TileSet:getTileDimensions() end

--- Returns the height of a single tile in pixels.
---@return integer
function TileSet:getTileHeight() end

--- Returns the width of a single tile in pixels.
---@return integer
function TileSet:getTileWidth() end

--- Returns whether a 1-based local tile ID is solid.
---@param tile_id any
---@return boolean
function TileSet:isSolid(tile_id) end

--- Sets whether a 1-based local tile ID is solid for collision purposes.
---@param tile_id any
---@param solid any
---@return nil
function TileSet:setSolid(tile_id, solid) end

--- Parses an LDtk JSON export string and returns a TileMap.
---@param json_str any
---@param level_name? any (optional)
---@return TileMap
function lurek.tilemap.fromLDtk(json_str, level_name) end

--- Converts screen position back to axial hex coordinates (pointy-top layout).
---@param sx any
---@param sy any
---@param size any
---@return integer
function lurek.tilemap.fromScreenHex(sx, sy, size) end

--- Converts screen position back to tile coordinates for diamond isometric projection.
---@param sx any
---@param sy any
---@param tw any
---@param th any
---@return number
function lurek.tilemap.fromScreenIso(sx, sy, tw, th) end

--- Returns all hex cells within radius distance (filled hex circle) as a table.
---@param q any
---@param r any
---@param radius any
---@return table
function lurek.tilemap.hexArea(q, r, radius) end

--- Returns the hex distance between two axial coordinates.
---@param q1 any
---@param r1 any
---@param q2 any
---@param r2 any
---@return integer
function lurek.tilemap.hexDistance(q1, r1, q2, r2) end

--- Returns all hex cells along a line between two axial coordinates as a table.
---@param q1 any
---@param r1 any
---@param q2 any
---@param r2 any
---@return table
function lurek.tilemap.hexLine(q1, r1, q2, r2) end

--- Returns the six axial neighbor coordinates as a table of {q, r} pairs.
---@param q any
---@param r any
---@return table
function lurek.tilemap.hexNeighbors(q, r) end

--- Reflects hex coordinates across an axis through the center.
---@param q any
---@param r any
---@param center_q any
---@param center_r any
---@param axis any
---@return integer
function lurek.tilemap.hexReflect(q, r, center_q, center_r, axis) end

--- Returns all cells at exactly radius distance from (q, r) as a table.
---@param q any
---@param r any
---@param radius any
---@return table
function lurek.tilemap.hexRing(q, r, radius) end

--- Rotates hex coordinates around a center by steps x 60 degrees clockwise.
---@param q any
---@param r any
---@param center_q any
---@param center_r any
---@param steps any
---@return integer
function lurek.tilemap.hexRotate(q, r, center_q, center_r, steps) end

--- Rounds fractional axial coordinates to the nearest hex cell.
---@param q any
---@param r any
---@return integer
function lurek.tilemap.hexRound(q, r) end

--- Returns all hex cells from center outward to radius, ring by ring, as a table.
---@param q any
---@param r any
---@param radius any
---@return table
function lurek.tilemap.hexSpiral(q, r, radius) end

--- Snaps an angle (in radians) to the nearest isometric direction (1-4).
---@param angle any
---@return integer
function lurek.tilemap.isoDirectionFromAngle(angle) end

--- Returns the name of an isometric direction (1-4).
---@param direction any
---@return string
function lurek.tilemap.isoDirectionName(direction) end

--- Rotates an isometric direction (1-4) clockwise by steps.
---@param direction any
---@param steps any
---@return integer
function lurek.tilemap.isoRotate(direction, steps) end

--- Parses a TMX XML string and returns a table with map metadata and layers.
---@param xml any
---@return table|nil
function lurek.tilemap.loadTMX(xml) end

--- Creates a new AutoTileSheet with the given tile dimensions and layout.
---@param tile_w any
---@param tile_h any
---@param layout_str any
---@return AutoTileSheet
function lurek.tilemap.newAutoTileSheet(tile_w, tile_h, layout_str) end

--- Creates a new ChunkMap with the given chunk size.
---@param chunk_size? any (optional)
---@return ChunkMap
function lurek.tilemap.newChunkMap(chunk_size) end

--- Creates a new IsoMap with no levels.
---@param width integer
---@param height integer
---@param tileW integer
---@param tileH integer
---@param levelHeight integer
---@param partCount? integer? (optional)
---@return IsoMap
function lurek.tilemap.newIsoMap(width, height, tileW, tileH, levelHeight, partCount) end

--- Creates a LargeMapRenderer for chunk-level occlusion culling on maps > 200Ă—200 tiles.
---@param tile_w any
---@param tile_h any
---@return LargeMapRenderer
function lurek.tilemap.newLargeMapRenderer(tile_w, tile_h) end

--- Creates a new MapBlock with the given dimensions.
---@param width any
---@param height any
---@param layers? any (optional)
---@param segment_size? any (optional)
---@return MapBlock
function lurek.tilemap.newMapBlock(width, height, layers, segment_size) end

--- Creates a MapGen from a MapGroup, a preset name or dimensions, and a segment size.
---@param group MapGroup
---@param preset string
---@param segmentSize integer
---@return MapGen
function lurek.tilemap.newMapGen(group, preset, segmentSize) end

--- Creates a new empty MapGroup with the given name.
---@param name any
---@return MapGroup
function lurek.tilemap.newMapGroup(name) end

--- Creates a new empty MapScript procedural generation script.
---@return MapScript
function lurek.tilemap.newMapScript() end

--- Creates a new TileMap with the given tile size and chunk size.
---@param tile_width any
---@param tile_height any
---@param chunk_size? any (optional)
---@return TileMap
function lurek.tilemap.newTileMap(tile_width, tile_height, chunk_size) end

--- Creates a new TileSet with the given atlas layout parameters.
---@param firstGid integer
---@param tileCount integer
---@param columns integer
---@param tileWidth integer
---@param tileHeight integer
---@param spacing? integer? (optional)
---@param margin? integer? (optional)
---@return TileSet
function lurek.tilemap.newTileSet(firstGid, tileCount, columns, tileWidth, tileHeight, spacing, margin) end

--- Converts axial hex coordinates to screen position (pointy-top layout).
---@param q any
---@param r any
---@param size any
---@return number
function lurek.tilemap.toScreenHex(q, r, size) end

--- Converts tile coordinates to screen position using diamond isometric projection.
---@param tx any
---@param ty any
---@param tw any
---@param th any
---@return number
function lurek.tilemap.toScreenIso(tx, ty, tw, th) end

---@class lurek.time
lurek.time = {}

--- Lua-side wrapper around a [`Scheduler`] with per-event callback storage.
---@class Scheduler
local Scheduler = {}

--- Schedules a callback to fire once after a delay.
---@param delay any
---@param func any
---@return integer
function Scheduler:after(delay, func) end

--- Schedules a callback to fire once after `n` frames.
---@param n any
---@param func any
---@return integer
function Scheduler:afterFrames(n, func) end

--- Cancels a scheduled event by its numeric ID.
---@param id any
---@return boolean
function Scheduler:cancel(id) end

--- Cancels all scheduled events and returns the count removed.
---@return integer
function Scheduler:cancelAll() end

--- Cancels a scheduled event by its string name.
---@param name any
---@return boolean
function Scheduler:cancelNamed(name) end

--- Returns the number of active scheduled events.
---@return integer
function Scheduler:getCount() end

--- Returns the base interval in seconds for an event, or nil.
---@param id any
---@return number?
function Scheduler:getInterval(id) end

--- Returns the seconds remaining until the next fire for an event, or nil.
---@param id any
---@return number?
function Scheduler:getRemaining(id) end

--- Returns the repeat count remaining for an event, or nil.
---@param id any
---@return integer?
function Scheduler:getRepeatCount(id) end

--- Returns the current time-scale multiplier.
---@return number
function Scheduler:getTimeScale() end

--- Returns whether the scheduler has no active events.
---@return boolean
function Scheduler:isEmpty() end

--- Returns whether the given event is currently paused.
---@param id any
---@return boolean
function Scheduler:isPaused(id) end

--- Returns whether the named event is currently paused.
---@param name any
---@return boolean
function Scheduler:isPausedNamed(name) end

--- Pauses a scheduled event by its ID.
---@param id any
---@return boolean
function Scheduler:pause(id) end

--- Pauses a scheduled event by its string name.
---@param name any
---@return boolean
function Scheduler:pauseNamed(name) end

--- Resets an event's remaining time back to its original interval.
---@param id any
---@return boolean
function Scheduler:resetEvent(id) end

--- Resumes a paused event by its ID.
---@param id any
---@return boolean
function Scheduler:resume(id) end

--- Resumes a paused event by its string name.
---@param name any
---@return boolean
function Scheduler:resumeNamed(name) end

--- Changes the repeat interval of an existing event.
---@param id any
---@param interval any
---@return boolean
function Scheduler:setInterval(id, interval) end

--- Sets a global time-scale multiplier for this scheduler.
---@param scale any
---@return nil
function Scheduler:setTimeScale(scale) end

--- Advances all timers by dt seconds, firing due callbacks.
---@param dt any
---@return integer
function Scheduler:update(dt) end

--- Advances frame-based events by one frame, firing due callbacks.
---@return integer
function Scheduler:updateFrames() end

--- Schedules a one-shot callback that fires after `delay` wall-clock seconds,
---@param delay any
---@param func any
---@return nil
function lurek.time.afterReal(delay, func) end

--- Creates a new Scheduler loaded with a sequenced one-shot chain.
---@param steps any
---@return Scheduler
function lurek.time.chain(steps) end

--- Returns the rolling-average frame delta time in seconds.
---@return number
function lurek.time.getAverageDelta() end

--- Returns the delta time in seconds for the current frame.
---@return number
function lurek.time.getDelta() end

--- Returns the current frames-per-second measurement.
---@return number
function lurek.time.getFPS() end

--- Returns the total number of frames rendered since engine start.
---@return integer
function lurek.time.getFrameCount() end

--- Returns the high-resolution elapsed time since engine start in seconds.
---@return number
function lurek.time.getMicroTime() end

--- Returns the fixed timestep used by `process_physics` callbacks (seconds).
---@return number
function lurek.time.getPhysicsDelta() end

--- Returns the maximum number of physics sub-steps allowed per frame.
---@return integer
function lurek.time.getPhysicsMaxSteps() end

--- Returns the exponential moving-average of frame deltas in seconds.
---@return number
function lurek.time.getSmoothedDelta() end

--- Returns the total elapsed time since engine start in seconds.
---@return number
function lurek.time.getTime() end

--- Creates a new independent Scheduler for managing timed callbacks.
---@return Scheduler
function lurek.time.newScheduler() end

--- Sets the fixed timestep for `process_physics` callbacks (seconds).
---@param dt any
---@return nil
function lurek.time.setPhysicsDelta(dt) end

--- Sets the maximum number of physics sub-steps allowed per frame (clamped 1â€“64).
---@param n any
function lurek.time.setPhysicsMaxSteps(n) end

--- Sets the smoothing factor (alpha) for `getSmoothedDelta`. Must be in [0.01, 1.0].
---@param alpha any
---@return nil
function lurek.time.setSmoothingFactor(alpha) end

--- Suspends execution for the given number of seconds.
---@param seconds any
---@return nil
function lurek.time.sleep(seconds) end

--- Advances the timer by one frame, returning the delta time.
---@return number
function lurek.time.step() end

--- Advances all real-time timers by one tick; called automatically each frame.
---@return table|nil
function lurek.time.tickRealTimers() end

--- Advances all `lurek.timer.wait()` coroutines by one tick; called each frame.
---@return table|nil
function lurek.time.tickWaits() end

--- Yields the current Lua coroutine for at least `frames` engine frames.
---@param frames any
---@return nil
function lurek.time.waitFrames(frames) end

--- Yields the current Lua coroutine for at least `seconds` wall-clock seconds.
---@param seconds any
---@return nil
function lurek.time.waitSeconds(seconds) end

---@class lurek.tween
lurek.tween = {}

--- Lua-side spring handle: wraps [`SpringSystem`] and a registry reference to the target table.
---@class Spring
local Spring = {}

--- Stops the spring. The engine will drop it on the next `update(dt)` call.
---@return nil
function Spring:cancel() end

--- Returns the current interpolated position for the named field, or `nil`.
---@param field any
---@return number?
function Spring:getPosition(field) end

--- Returns `true` if the spring has not been cancelled or settled.
---@return boolean
function Spring:isActive() end

--- Returns `true` when all spring axes have converged within `precision`.
---@return boolean
function Spring:isSettled() end

--- Updates the damping coefficient on all axes.
---@param value any
---@return nil
function Spring:setDamping(value) end

--- Updates the stiffness constant on all axes.
---@param value any
---@return nil
function Spring:setStiffness(value) end

--- Updates target values for all fields present in `fields_table`.
---@param fields_tbl any
---@return nil
function Spring:setTarget(fields_tbl) end

--- Advances the spring by `dt` seconds and writes positions to the target table.
---@param dt any
---@return boolean
function Spring:update(dt) end

--- A managed interpolation from start to end values over time.
---@class Tween
local Tween = {}

--- Returns raw 0..1 playback progress (not eased, not accounting for yoyo).
---@return number
function Tween:getProgress() end

--- Returns true if the tween is still running (not completed or cancelled).
---@return boolean
function Tween:isActive() end

--- Pauses this tween; time stops advancing but the tween is not cancelled.
---@return nil
function Tween:pause() end

--- Resumes a paused tween, continuing from the position where it was paused.
---@return nil
function Tween:resume() end

--- Sets the number of extra play cycles after the first (0 = play once, -1 = infinite).
---@param n any
---@return nil
function Tween:setRepeat(n) end

--- Enables or disables yoyo (ping-pong) on each repeat cycle.
---@param enabled any
---@return nil
function Tween:setYoyo(enabled) end

--- A group of animations that run simultaneously over the same duration.
---@class TweenParallel
local TweenParallel = {}

--- Cancels the parallel group immediately.
---@return nil
function TweenParallel:cancel() end

--- Returns true if the parallel is running and not yet complete.
---@return boolean
function TweenParallel:isActive() end

--- A chained sequence of animations that run one after another.
---@class TweenSequence
local TweenSequence = {}

--- Cancels the sequence and stops all pending steps.
---@return nil
function TweenSequence:cancel() end

--- Returns true if the sequence has been started and has not yet completed.
---@return boolean
function TweenSequence:isActive() end

--- Lua-side wrapper around the pure-Rust [`TweenState`] timing core.
---@class TweenState
local TweenState = {}

--- Returns whether the tween state has completed.
---@return boolean
function TweenState:isComplete() end

--- Interpolates from `start` to `finish` using the eased tween progress.
---@param start any
---@param finish any
---@return number
function TweenState:lerp(start, finish) end

--- Resets the tween state to elapsed time zero.
---@return nil
function TweenState:reset() end

--- Returns the raw 0..1 playback progress.
---@return number
function TweenState:t() end

--- Advances the tween state by `dt` seconds.
---@param dt any
---@return boolean
function TweenState:tick(dt) end

--- Cancels all active tweens, sequences, parallels, and springs immediately.
---@return nil
function lurek.tween.cancelAll() end

--- Creates a no-op tween that waits `seconds`, then optionally calls `callback`.
---@param seconds any
---@param cb? any (optional)
---@return TweenSequence
function lurek.tween.delay(seconds, cb) end

--- Returns the number of currently active tween objects (tweens + seqs + pars).
---@return integer
function lurek.tween.getActiveCount() end

--- Returns a list of all available easing names (built-in + custom).
---@return table
function lurek.tween.getEasingNames() end

--- Creates a standalone tween timing state without registering it with the engine.
---@param duration any
---@param easing? any (optional)
---@return TweenState
function lurek.tween.newState(duration, easing) end

--- Creates an empty TweenParallel. Add entries with :tween() or :add(tween),
---@return TweenParallel
function lurek.tween.parallel() end

--- Registers a custom easing function under `name`. `fn(t)` receives 0..1, returns 0..1.
---@param name any
---@param f any
---@return nil
function lurek.tween.registerEasing(name, f) end

--- Creates an empty TweenSequence. Add steps with :tween(), :delay(), :callback(),
---@return TweenSequence
function lurek.tween.sequence() end

--- Creates a physics-based spring animation that drives named fields on `target_table`
---@param target_tbl any
---@param fields_tbl any
---@param opts? any (optional)
---@return Spring
function lurek.tween.spring(target_tbl, fields_tbl, opts) end

--- Sugar for `tween()` with `target` first â€” natural read order.
---@param target table
---@param fields table
---@param duration number
---@param easing? string? (optional)
---@return Tween
function lurek.tween.to(target, fields, duration, easing) end

--- Creates a new property tween and registers it for automatic updating.
---@param duration number
---@param target table
---@param fields table
---@param easing string
---@return Tween
function lurek.tween.tween(duration, target, fields, easing) end

--- Advances all active tweens, sequences, and parallels by `dt` seconds.
---@param dt any
---@return nil
function lurek.tween.update(dt) end

---@class lurek.ui
lurek.ui = {}

--- Adds Accordion-specific methods (1-based sections in Lua).
---@class Accordion
local Accordion = {}

--- Adds a section entry to this Accordion widget.
---@param title any
---@param content_idx? any (optional)
---@return nil
function Accordion:addSection(title, content_idx) end

--- Returns the section count of this Accordion widget.
---@return integer
function Accordion:getSectionCount() end

--- Returns the section title of this Accordion widget.
---@param section_idx any
---@return nil
function Accordion:getSectionTitle(section_idx) end

--- Returns true if exclusive is enabled for this Accordion widget.
---@return boolean
function Accordion:isExclusive() end

--- Returns true if section expanded is enabled for this Accordion widget.
---@param section_idx any
---@return boolean
function Accordion:isSectionExpanded(section_idx) end

--- Sets the exclusive for this Accordion widget.
---@param v any
---@return nil
function Accordion:setExclusive(v) end

--- Toggles the expanded/collapsed status of an Accordion section.
---@param section_idx any
---@return nil
function Accordion:toggleSection(section_idx) end

--- Lua wrapper for a stacked area chart renderer.
---@class AreaChart
local AreaChart = {}

--- Renders the area chart into an existing ImageData.
---@param target ImageData
---@return nil
function AreaChart:drawToImage(target) end

--- Sets the maximum Y value for axis scaling.
---@param v any
---@return nil
function AreaChart:setYMax(v) end

--- Adds Badge-specific methods to a widget table.
---@class Badge
local Badge = {}

--- Returns the raw count of this Badge widget.
---@return integer
function Badge:getCount() end

--- Returns the display text of this Badge widget, e.g. "99+" when over the max.
---@return string
function Badge:getDisplayText() end

--- Sets the count displayed on this Badge widget.
---@param count any
---@return nil
function Badge:setCount(count) end

--- Lua wrapper for a grouped bar chart renderer.
---@class BarChart
local BarChart = {}

--- Renders the bar chart into an existing ImageData.
---@param target ImageData
---@return nil
function BarChart:drawToImage(target) end

--- Adds Button-specific methods to a widget table.
---@class Button
local Button = {}

--- Returns the text of this Button widget.
---@return string
function Button:getText() end

--- Sets the text for this Button widget.
---@param text any
---@return nil
function Button:setText(text) end

--- Adds CheckBox-specific methods to a widget table.
---@class Checkbox
local Checkbox = {}

--- Returns the text of this Checkbox widget.
---@return string
function Checkbox:getText() end

--- Returns true if checked is enabled for this Checkbox widget.
---@return boolean
function Checkbox:isChecked() end

--- Sets the checked for this Checkbox widget.
---@param checked any
---@return nil
function Checkbox:setChecked(checked) end

--- Sets the text for this Checkbox widget.
---@param text any
---@return nil
function Checkbox:setText(text) end

--- Adds ColorPicker-specific methods.
---@class Color_Picker
local Color_Picker = {}

--- Returns the color of this Color_Picker widget.
---@return number
function Color_Picker:getColor() end

--- Returns the color mode of this Color_Picker widget.
---@return string
function Color_Picker:getColorMode() end

--- Returns the show alpha of this Color_Picker widget.
---@return boolean
function Color_Picker:getShowAlpha() end

--- Sets the color for this Color_Picker widget.
---@param r any
---@param green any
---@param b any
---@param a? any (optional)
---@return nil
function Color_Picker:setColor(r, green, b, a) end

--- Sets the color mode for this Color_Picker widget.
---@param mode any
---@return nil
function Color_Picker:setColorMode(mode) end

--- Registers a callback invoked when this widget's value changes.
---@param f any
---@return nil
function Color_Picker:setOnChange(f) end

--- Sets the show alpha for this Color_Picker widget.
---@param v any
---@return nil
function Color_Picker:setShowAlpha(v) end

--- Adds ComboBox-specific methods (1-based indices in Lua).
---@class Combo_Box
local Combo_Box = {}

--- Adds a item entry to this Combo_Box widget.
---@param text any
---@return nil
function Combo_Box:addItem(text) end

--- Clears all items entries from this Combo_Box widget.
---@return nil
function Combo_Box:clearItems() end

--- Returns the item of this Combo_Box widget.
---@param index any
---@return string
function Combo_Box:getItem(index) end

--- Returns the item count of this Combo_Box widget.
---@return integer
function Combo_Box:getItemCount() end

--- Returns the selected index of this Combo_Box widget.
---@return integer
function Combo_Box:getSelectedIndex() end

--- Returns the selected item of this Combo_Box widget.
---@return string
function Combo_Box:getSelectedItem() end

--- Removes the item from this Combo_Box widget.
---@param index any
---@return nil
function Combo_Box:removeItem(index) end

--- Sets the selected index for this Combo_Box widget.
---@param index any
---@return nil
function Combo_Box:setSelectedIndex(index) end

--- Adds Dialog-specific methods.
---@class Dialog
local Dialog = {}

--- Adds a button entry to this Dialog widget.
---@param text any
---@param cb? any (optional)
---@return nil
function Dialog:addButton(text, cb) end

--- Closes and removes this dialog from the screen.
---@return nil
function Dialog:close() end

--- Returns the content of this Dialog widget.
---@return integer
function Dialog:getContent() end

--- Returns the title of this Dialog widget.
---@return string
function Dialog:getTitle() end

--- Returns true if modal is enabled for this Dialog widget.
---@return boolean
function Dialog:isModal() end

--- Returns true if open is enabled for this Dialog widget.
---@return boolean
function Dialog:isOpen() end

--- Performs the open operation on this Dialog widget.
---@return nil
function Dialog:open() end

--- Sets the content for this Dialog widget.
---@param content_idx? any (optional)
---@return nil
function Dialog:setContent(content_idx) end

--- Sets the modal for this Dialog widget.
---@param v any
---@return nil
function Dialog:setModal(v) end

--- Registers a callback invoked when this dialog is closed.
---@param f any
---@return nil
function Dialog:setOnClose(f) end

--- Sets the title for this Dialog widget.
---@param title any
---@return nil
function Dialog:setTitle(title) end

--- Adds DockPanel-specific methods.
---@class Dock_Panel
local Dock_Panel = {}

--- Performs the dock operation on this Dock_Panel widget.
---@param child_idx any
---@param side any
---@return nil
function Dock_Panel:dock(child_idx, side) end

--- Returns the docked count of this Dock_Panel widget.
---@return integer
function Dock_Panel:getDockedCount() end

--- Returns the split size of this Dock_Panel widget.
---@param side any
---@return nil
function Dock_Panel:getSplitSize(side) end

--- Sets the split size for this Dock_Panel widget.
---@param side any
---@param size any
---@return nil
function Dock_Panel:setSplitSize(side, size) end

--- Performs the undock operation on this Dock_Panel widget.
---@param child_idx any
---@return nil
function Dock_Panel:undock(child_idx) end

--- Adds GUITable-specific methods (1-based rows/cols in Lua).
---@class Gui_Table
local Gui_Table = {}

--- Adds a column entry to this Gui_Table widget.
---@param header any
---@param width? any (optional)
---@return nil
function Gui_Table:addColumn(header, width) end

--- Adds a row entry to this Gui_Table widget.
---@param cells any
---@return nil
function Gui_Table:addRow(cells) end

--- Returns the cell of this Gui_Table widget.
---@param row any
---@param col any
---@return nil
function Gui_Table:getCell(row, col) end

--- Returns the column count of this Gui_Table widget.
---@return integer
function Gui_Table:getColumnCount() end

--- Returns the row count of this Gui_Table widget.
---@return integer
function Gui_Table:getRowCount() end

--- Returns the selected row of this Gui_Table widget.
---@return nil
function Gui_Table:getSelectedRow() end

--- Returns true if sortable is enabled for this Gui_Table widget.
---@return boolean
function Gui_Table:isSortable() end

--- Sets the cell for this Gui_Table widget.
---@param row any
---@param col any
---@param text any
---@return nil
function Gui_Table:setCell(row, col, text) end

--- Registers a callback invoked when a table row is selected.
---@param f any
---@return nil
function Gui_Table:setOnSelect(f) end

--- Sets the selected row for this Gui_Table widget.
---@param row? any (optional)
---@return nil
function Gui_Table:setSelectedRow(row) end

--- Sets the sortable for this Gui_Table widget.
---@param v any
---@return nil
function Gui_Table:setSortable(v) end

--- Adds GUIWindow-specific methods.
---@class Gui_Window
local Gui_Window = {}

--- Returns the title of this Gui_Window widget.
---@return string
function Gui_Window:getTitle() end

--- Returns true if closeable is enabled for this Gui_Window widget.
---@return boolean
function Gui_Window:isCloseable() end

--- Returns true if draggable is enabled for this Gui_Window widget.
---@return boolean
function Gui_Window:isDraggable() end

--- Returns true if resizable is enabled for this Gui_Window widget.
---@return boolean
function Gui_Window:isResizable() end

--- Sets the closeable for this Gui_Window widget.
---@param v any
---@return nil
function Gui_Window:setCloseable(v) end

--- Sets the draggable for this Gui_Window widget.
---@param v any
---@return nil
function Gui_Window:setDraggable(v) end

--- Registers a callback invoked when this window is closed.
---@param f any
---@return nil
function Gui_Window:setOnClose(f) end

--- Sets the resizable for this Gui_Window widget.
---@param v any
---@return nil
function Gui_Window:setResizable(v) end

--- Sets the title for this Gui_Window widget.
---@param title any
---@return nil
function Gui_Window:setTitle(title) end

--- Adds ImageWidget-specific methods.
---@class Image_Widget
local Image_Widget = {}

--- Queues a toast notification from a table.
---@param toast_table any
---@return nil
function Image_Widget:addToast(toast_table) end

--- Removes keyboard focus from this widget so key events go to the next focusable.
---@return nil
function Image_Widget:clearFocus() end

--- Invokes all registered on_draw callbacks, each receiving the widget's
---@return nil
function Image_Widget:draw() end

--- Renders the UI widget tree to a CPU ImageData at the given resolution.
---@param w any
---@param h any
---@return ImageData
function Image_Widget:drawToImage(w, h) end

--- Returns true if the widget tree changed since the last call, then resets the flag.
---@return boolean
function Image_Widget:flushCache() end

--- Moves focus to the next focusable widget.
---@return nil
function Image_Widget:focusNext() end

--- Moves focus to the previous focusable widget.
---@return nil
function Image_Widget:focusPrev() end

--- Returns the focused widget index or nil.
---@return number
function Image_Widget:getFocus() end

--- Returns the root panel widget table.
---@return table
function Image_Widget:getRoot() end

--- Returns the scale mode of this Image_Widget widget.
---@return string
function Image_Widget:getScaleMode() end

--- Returns whether a theme is set.
---@return boolean
function Image_Widget:getTheme() end

--- Returns the tint of this Image_Widget widget.
---@return number
function Image_Widget:getTint() end

--- Returns the number of active toasts.
---@return number
function Image_Widget:getToastCount() end

--- Returns the total widget count in the context.
---@return number
function Image_Widget:getWidgetCount() end

--- Forwards a key press event to the GUI.
---@param key any
---@return boolean
function Image_Widget:keypressed(key) end

--- Load a widget tree from a Lua table definition and attach it to the UI
---@param def table
---@return number
function Image_Widget:loadLayout(def) end

--- Load a widget tree from a TOML layout file and attach it to the UI root.
---@param path any
---@return number
function Image_Widget:loadLayoutFile(path) end

--- Forwards a mouse move event to the GUI.
---@param x any
---@param y any
---@return boolean
function Image_Widget:mousemoved(x, y) end

--- Forwards a mouse press event to the GUI.
---@param x any
---@param y any
---@param btn? any (optional)
---@return boolean
function Image_Widget:mousepressed(x, y, btn) end

--- Forwards a mouse release event to the GUI.
---@param x any
---@param y any
---@param btn? any (optional)
---@return boolean
function Image_Widget:mousereleased(x, y, btn) end

--- Creates a collapsible accordion widget.
---@return table
function Image_Widget:newAccordion() end

--- Creates a new stacked-area chart.
---@param opts any
---@return AreaChart
function Image_Widget:newAreaChart(opts) end

--- Creates a new stacked-area chart.
---@param opts any
---@return AreaChart
function Image_Widget:newAreaChart(opts) end

--- Creates a badge widget displaying a numeric count.
---@param count? any (optional)
---@return table
function Image_Widget:newBadge(count) end

--- Creates and returns a new bar chart widget attached to this image widget.
---@param opts any
---@return BarChart
function Image_Widget:newBarChart(opts) end

--- Creates and returns a new bar chart widget attached to this image widget.
---@param opts any
---@return BarChart
function Image_Widget:newBarChart(opts) end

--- Creates and returns a new interactive button widget as a child of this widget.
---@param text? any (optional)
---@return table
function Image_Widget:newButton(text) end

--- Creates a checkbox widget.
---@param text? any (optional)
---@return table
function Image_Widget:newCheckbox(text) end

--- Creates a color picker widget.
---@return table
function Image_Widget:newColorPicker() end

--- Creates a dropdown combo box widget.
---@return table
function Image_Widget:newComboBox() end

--- Creates a new widget with custom Lua-driven rendering.
---@param config? any (optional)
---@return table
function Image_Widget:newCustomWidget(config) end

--- Creates a modal dialog widget.
---@param title? any (optional)
---@return table
function Image_Widget:newDialog(title) end

--- Creates and returns a new docking panel that arranges children along its edges.
---@return table
function Image_Widget:newDockPanel() end

--- Creates an image display widget.
---@return table
function Image_Widget:newImageWidget() end

--- Creates a text label widget.
---@param text? any (optional)
---@return table
function Image_Widget:newLabel(text) end

--- Creates a flexbox layout container.
---@param direction? any (optional)
---@return table
function Image_Widget:newLayout(direction) end

--- Creates a new line chart.
---@param opts any
---@return LineChart
function Image_Widget:newLineChart(opts) end

--- Creates a new line chart.
---@param opts any
---@return LineChart
function Image_Widget:newLineChart(opts) end

--- Creates a selectable list widget.
---@return table
function Image_Widget:newList() end

--- Creates a menu bar widget.
---@return table
function Image_Widget:newMenuBar() end

--- Creates a menu item widget.
---@param text? any (optional)
---@return table
function Image_Widget:newMenuItem(text) end

--- Creates a 9-patch slicer widget.
---@return table
function Image_Widget:newNinePatch() end

--- Creates a container panel widget.
---@return table
function Image_Widget:newPanel() end

--- Creates and returns a new pie chart widget attached to this image widget.
---@param opts any
---@return PieChart
function Image_Widget:newPieChart(opts) end

--- Creates and returns a new pie chart widget attached to this image widget.
---@param opts any
---@return PieChart
function Image_Widget:newPieChart(opts) end

--- Creates a progress bar widget.
---@param min? any (optional)
---@param max? any (optional)
---@return table
function Image_Widget:newProgressBar(min, max) end

--- Creates a grouped radio button widget.
---@param text? any (optional)
---@param group? any (optional)
---@return table
function Image_Widget:newRadioButton(text, group) end

--- Creates a new scatter plot.
---@param opts any
---@return ScatterPlot
function Image_Widget:newScatterPlot(opts) end

--- Creates a new scatter plot.
---@param opts any
---@return ScatterPlot
function Image_Widget:newScatterPlot(opts) end

--- Creates a scroll bar widget.
---@param vertical? any (optional)
---@return table
function Image_Widget:newScrollBar(vertical) end

--- Creates a scrollable panel widget.
---@return table
function Image_Widget:newScrollPanel() end

--- Creates a separator line.
---@param vertical? any (optional)
---@return table
function Image_Widget:newSeparator(vertical) end

--- Creates a value slider widget.
---@param min? any (optional)
---@param max? any (optional)
---@return table
function Image_Widget:newSlider(min, max) end

--- Creates a spacing filler widget.
---@param w? any (optional)
---@param h? any (optional)
---@return table
function Image_Widget:newSpacer(w, h) end

--- Creates a numeric spin box widget with increment and decrement buttons.
---@param min? any (optional)
---@param max? any (optional)
---@return table
function Image_Widget:newSpinBox(min, max) end

--- Creates a resizable split panel.
---@param orientation? any (optional)
---@return table
function Image_Widget:newSplitPanel(orientation) end

--- Creates a status bar widget.
---@return table
function Image_Widget:newStatusBar() end

--- Creates a toggle switch widget.
---@param on? any (optional)
---@return table
function Image_Widget:newSwitch(on) end

--- Creates a tab bar widget.
---@return table
function Image_Widget:newTabBar() end

--- Creates a data table widget.
---@return table
function Image_Widget:newTable() end

--- Creates a text input widget.
---@return table
function Image_Widget:newTextInput() end

--- Creates a new theme instance.
---@return Theme
function Image_Widget:newTheme() end

--- Creates a toast notification widget.
---@param message? any (optional)
---@param duration? any (optional)
---@return table
function Image_Widget:newToast(message, duration) end

--- Creates a toolbar widget.
---@param orientation? any (optional)
---@return table
function Image_Widget:newToolbar(orientation) end

--- Creates a tooltip panel widget.
---@param text? any (optional)
---@return table
function Image_Widget:newTooltipPanel(text) end

--- Creates a collapsible tree view widget.
---@return table
function Image_Widget:newTreeView() end

--- Creates a draggable window widget.
---@param title? any (optional)
---@return table
function Image_Widget:newWindow(title) end

--- Parses a widget state string, returning the canonical form or nil if invalid.
---@param state any
---@return string?
function Image_Widget:parseWidgetState(state) end

--- Render the current UI widget tree to a PNG file for testing purposes.
---@param width any
---@param height any
---@param path any
function Image_Widget:renderToImage(width, height, path) end

--- Installs the built-in dark theme as the active GUI theme.
---@return nil
function Image_Widget:setDefaultTheme() end

--- Sets keyboard focus to a widget or clears it.
---@param widget? any (optional)
---@return nil
function Image_Widget:setFocus(widget) end

--- Sets the scale mode for this Image_Widget widget.
---@param mode any
---@return nil
function Image_Widget:setScaleMode(mode) end

--- Sets the active GUI theme.
---@param theme_ud any
---@return nil
function Image_Widget:setTheme(theme_ud) end

--- Sets the tint for this Image_Widget widget.
---@param r any
---@param green any
---@param b any
---@param a? any (optional)
---@return nil
function Image_Widget:setTint(r, green, b, a) end

--- Sets the viewport dimensions used for anchor constraints and layout.
---@param w any
---@param h any
---@return nil
function Image_Widget:setViewport(w, h) end

--- Forwards text input to the focused text input widget.
---@param text any
---@return boolean
function Image_Widget:textinput(text) end

--- Advances toast timers, removes expired toasts, and dispatches pending GUI events.
---@param dt any
---@return nil
function Image_Widget:update(dt) end

--- Updates all widgets that have a data-binding key registered via `:bind(key)`.
---@param data table
function Image_Widget:update_bindings(data) end

--- Forwards a mouse wheel event to the GUI.
---@param x any
---@param y any
---@return boolean
function Image_Widget:wheelmoved(x, y) end

--- Adds Label-specific methods to a widget table.
---@class Label
local Label = {}

--- Returns the text of this Label widget.
---@return string
function Label:getText() end

--- Sets the text for this Label widget.
---@param text any
---@return nil
function Label:setText(text) end

--- Adds Layout-specific methods.
---@class Layout
local Layout = {}

--- Returns the align of this Layout widget.
---@return string
function Layout:getAlign() end

--- Returns the direction of this Layout widget.
---@return string
function Layout:getDirection() end

--- Returns the justify of this Layout widget.
---@return string
function Layout:getJustify() end

--- Returns the spacing of this Layout widget.
---@return number
function Layout:getSpacing() end

--- Returns the wrap of this Layout widget.
---@return boolean
function Layout:getWrap() end

--- Sets the align for this Layout widget.
---@param align any
---@return nil
function Layout:setAlign(align) end

--- Sets the columns for this Layout widget.
---@param n any
---@return nil
function Layout:setColumns(n) end

--- Sets the direction for this Layout widget.
---@param dir any
---@return nil
function Layout:setDirection(dir) end

--- Sets the justify for this Layout widget.
---@param justify any
---@return nil
function Layout:setJustify(justify) end

--- Sets the spacing for this Layout widget.
---@param spacing any
---@return nil
function Layout:setSpacing(spacing) end

--- Sets the wrap for this Layout widget.
---@param wrap any
---@return nil
function Layout:setWrap(wrap) end

--- Lua wrapper for a line chart renderer.
---@class LineChart
local LineChart = {}

--- Renders the line chart into an existing ImageData.
---@param target ImageData
---@return nil
function LineChart:drawToImage(target) end

--- Sets the maximum X value for axis scaling.
---@param v any
---@return nil
function LineChart:setXMax(v) end

--- Sets the maximum Y value for axis scaling.
---@param v any
---@return nil
function LineChart:setYMax(v) end

--- Adds ListBox-specific methods (1-based indices in Lua).
---@class List_Box
local List_Box = {}

--- Adds a item entry to this List_Box widget.
---@param text any
---@return nil
function List_Box:addItem(text) end

--- Clears all items entries from this List_Box widget.
---@return nil
function List_Box:clearItems() end

--- Returns the item of this List_Box widget.
---@param index any
---@return string
function List_Box:getItem(index) end

--- Returns the item count of this List_Box widget.
---@return integer
function List_Box:getItemCount() end

--- Returns the selected index of this List_Box widget.
---@return integer
function List_Box:getSelectedIndex() end

--- Removes the item from this List_Box widget.
---@param index any
---@return nil
function List_Box:removeItem(index) end

--- Sets the item height for this List_Box widget.
---@param h any
---@return nil
function List_Box:setItemHeight(h) end

--- Sets the selected index for this List_Box widget.
---@param index any
---@return nil
function List_Box:setSelectedIndex(index) end

--- Adds MenuBar-specific methods.
---@class Menu_Bar
local Menu_Bar = {}

--- Adds a menu entry to this Menu_Bar widget.
---@param menu_idx any
---@return nil
function Menu_Bar:addMenu(menu_idx) end

--- Returns the menu count of this Menu_Bar widget.
---@return integer
function Menu_Bar:getMenuCount() end

--- Returns the menus of this Menu_Bar widget.
---@return nil
function Menu_Bar:getMenus() end

--- Removes the menu from this Menu_Bar widget.
---@param menu_idx any
---@return nil
function Menu_Bar:removeMenu(menu_idx) end

--- Adds MenuItem-specific methods.
---@class Menu_Item
local Menu_Item = {}

--- Adds a sub item entry to this Menu_Item widget.
---@param child_idx any
---@return nil
function Menu_Item:addSubItem(child_idx) end

--- Returns the shortcut of this Menu_Item widget.
---@return string
function Menu_Item:getShortcut() end

--- Returns the sub items of this Menu_Item widget.
---@return nil
function Menu_Item:getSubItems() end

--- Returns the text of this Menu_Item widget.
---@return string
function Menu_Item:getText() end

--- Returns true if checked is enabled for this Menu_Item widget.
---@return boolean
function Menu_Item:isChecked() end

--- Sets the checked for this Menu_Item widget.
---@param v any
---@return nil
function Menu_Item:setChecked(v) end

--- Registers a callback invoked when this menu item is clicked.
---@param f any
---@return nil
function Menu_Item:setOnClick(f) end

--- Sets the shortcut for this Menu_Item widget.
---@param shortcut any
---@return nil
function Menu_Item:setShortcut(shortcut) end

--- Sets the text for this Menu_Item widget.
---@param text any
---@return nil
function Menu_Item:setText(text) end

--- Adds NinePatch-specific methods.
---@class Nine_Patch
local Nine_Patch = {}

--- Returns the image dimensions of this Nine_Patch widget.
---@return integer
function Nine_Patch:getImageDimensions() end

--- Returns the insets of this Nine_Patch widget.
---@return integer
function Nine_Patch:getInsets() end

--- Returns the slices of this Nine_Patch widget.
---@return table
function Nine_Patch:getSlices() end

--- Sets the image dimensions for this Nine_Patch widget.
---@param w any
---@param h any
---@return nil
function Nine_Patch:setImageDimensions(w, h) end

--- Sets the insets for this Nine_Patch widget.
---@param left any
---@param top any
---@param right any
---@param bottom any
---@return nil
function Nine_Patch:setInsets(left, top, right, bottom) end

--- Adds Panel-specific methods.
---@class Panel
local Panel = {}

--- Returns the title of this Panel widget.
---@return string
function Panel:getTitle() end

--- Sets the scrollable for this Panel widget.
---@param scrollable any
---@return nil
function Panel:setScrollable(scrollable) end

--- Sets the title for this Panel widget.
---@param title any
---@return nil
function Panel:setTitle(title) end

--- Lua wrapper for a pie chart renderer.
---@class PieChart
local PieChart = {}

--- Renders the pie chart into an existing ImageData.
---@param target ImageData
---@return nil
function PieChart:drawToImage(target) end

--- Adds ProgressBar-specific methods to a widget table.
---@class Progress_Bar
local Progress_Bar = {}

--- Returns the max of this Progress_Bar widget.
---@return number
function Progress_Bar:getMax() end

--- Returns the min of this Progress_Bar widget.
---@return number
function Progress_Bar:getMin() end

--- Returns the progress of this Progress_Bar widget.
---@return number
function Progress_Bar:getProgress() end

--- Returns the value of this Progress_Bar widget.
---@return number
function Progress_Bar:getValue() end

--- Sets the range for this Progress_Bar widget.
---@param min any
---@param max any
---@return nil
function Progress_Bar:setRange(min, max) end

--- Sets the value for this Progress_Bar widget.
---@param v any
---@return nil
function Progress_Bar:setValue(v) end

--- Adds RadioButton-specific methods.
---@class Radio_Button
local Radio_Button = {}

--- Returns the group of this Radio_Button widget.
---@return string
function Radio_Button:getGroup() end

--- Returns the text of this Radio_Button widget.
---@return string
function Radio_Button:getText() end

--- Returns true if selected is enabled for this Radio_Button widget.
---@return boolean
function Radio_Button:isSelected() end

--- Sets the group for this Radio_Button widget.
---@param group any
---@return nil
function Radio_Button:setGroup(group) end

--- Registers a callback invoked when this widget's value changes.
---@param f any
---@return nil
function Radio_Button:setOnChange(f) end

--- Sets the selected for this Radio_Button widget.
---@param v any
---@return nil
function Radio_Button:setSelected(v) end

--- Sets the text for this Radio_Button widget.
---@param text any
---@return nil
function Radio_Button:setText(text) end

--- Lua wrapper for a scatter plot renderer.
---@class ScatterPlot
local ScatterPlot = {}

--- Renders the scatter plot into an existing ImageData.
---@param target ImageData
---@return nil
function ScatterPlot:drawToImage(target) end

--- Sets the X-axis data range.
---@param mn any
---@param mx any
---@return nil
function ScatterPlot:setXRange(mn, mx) end

--- Sets the Y-axis data range.
---@param mn any
---@param mx any
---@return nil
function ScatterPlot:setYRange(mn, mx) end

--- Adds ScrollBar-specific methods.
---@class Scroll_Bar
local Scroll_Bar = {}

--- Returns the content size of this Scroll_Bar widget.
---@return number
function Scroll_Bar:getContentSize() end

--- Returns the scroll position of this Scroll_Bar widget.
---@return number
function Scroll_Bar:getScrollPosition() end

--- Returns the view size of this Scroll_Bar widget.
---@return number
function Scroll_Bar:getViewSize() end

--- Returns true if vertical is enabled for this Scroll_Bar widget.
---@return boolean
function Scroll_Bar:isVertical() end

--- Sets the content size for this Scroll_Bar widget.
---@param v any
---@return nil
function Scroll_Bar:setContentSize(v) end

--- Registers a callback invoked when this widget's value changes.
---@param f any
---@return nil
function Scroll_Bar:setOnChange(f) end

--- Sets the scroll position for this Scroll_Bar widget.
---@param v any
---@return nil
function Scroll_Bar:setScrollPosition(v) end

--- Sets the view size for this Scroll_Bar widget.
---@param v any
---@return nil
function Scroll_Bar:setViewSize(v) end

--- Adds ScrollPanel-specific methods.
---@class Scroll_Panel
local Scroll_Panel = {}

--- Returns the content size of this Scroll_Panel widget.
---@return number
function Scroll_Panel:getContentSize() end

--- Returns the max scroll of this Scroll_Panel widget.
---@return number
function Scroll_Panel:getMaxScroll() end

--- Returns the scroll position of this Scroll_Panel widget.
---@return number
function Scroll_Panel:getScrollPosition() end

--- Returns the scroll speed of this Scroll_Panel widget.
---@return number
function Scroll_Panel:getScrollSpeed() end

--- Sets the content size for this Scroll_Panel widget.
---@param w any
---@param h any
---@return nil
function Scroll_Panel:setContentSize(w, h) end

--- Sets the scroll position for this Scroll_Panel widget.
---@param x any
---@param y any
---@return nil
function Scroll_Panel:setScrollPosition(x, y) end

--- Sets the scroll speed for this Scroll_Panel widget.
---@param speed any
---@return nil
function Scroll_Panel:setScrollSpeed(speed) end

--- Adds Separator-specific methods.
---@class Separator
local Separator = {}

--- Returns the thickness of this Separator widget.
---@return number
function Separator:getThickness() end

--- Returns true if vertical is enabled for this Separator widget.
---@return boolean
function Separator:isVertical() end

--- Sets the thickness for this Separator widget.
---@param thickness any
---@return nil
function Separator:setThickness(thickness) end

--- Sets the vertical for this Separator widget.
---@param v any
---@return nil
function Separator:setVertical(v) end

--- Adds Slider-specific methods to a widget table.
---@class Slider
local Slider = {}

--- Returns the max of this Slider widget.
---@return number
function Slider:getMax() end

--- Returns the min of this Slider widget.
---@return number
function Slider:getMin() end

--- Returns the value of this Slider widget.
---@return number
function Slider:getValue() end

--- Sets the range for this Slider widget.
---@param min any
---@param max any
---@return nil
function Slider:setRange(min, max) end

--- Sets the step for this Slider widget.
---@param step any
---@return nil
function Slider:setStep(step) end

--- Sets the value for this Slider widget.
---@param v any
---@return nil
function Slider:setValue(v) end

--- Adds SpinBox-specific methods to a widget table.
---@class Spin_Box
local Spin_Box = {}

--- Decrements the value by one step.
---@return nil
function Spin_Box:decrement() end

--- Returns the current value of this SpinBox widget.
---@return number
function Spin_Box:getValue() end

--- Increments the value by one step.
---@return nil
function Spin_Box:increment() end

--- Sets the valid range for this SpinBox widget.
---@param min any
---@param max any
---@return nil
function Spin_Box:setRange(min, max) end

--- Sets the increment step for this SpinBox widget.
---@param step any
---@return nil
function Spin_Box:setStep(step) end

--- Sets the value for this SpinBox widget.
---@param v any
---@return nil
function Spin_Box:setValue(v) end

--- Adds SplitPanel-specific methods.
---@class Split_Panel
local Split_Panel = {}

--- Returns the first child of this Split_Panel widget.
---@return nil
function Split_Panel:getFirstChild() end

--- Returns the min panel size of this Split_Panel widget.
---@return number
function Split_Panel:getMinPanelSize() end

--- Returns the orientation of this Split_Panel widget.
---@return string
function Split_Panel:getOrientation() end

--- Returns the second child of this Split_Panel widget.
---@return nil
function Split_Panel:getSecondChild() end

--- Returns the split position of this Split_Panel widget.
---@return number
function Split_Panel:getSplitPosition() end

--- Sets the first child for this Split_Panel widget.
---@param child_idx any
---@return nil
function Split_Panel:setFirstChild(child_idx) end

--- Sets the min panel size for this Split_Panel widget.
---@param v any
---@return nil
function Split_Panel:setMinPanelSize(v) end

--- Sets the orientation for this Split_Panel widget.
---@param v any
---@return nil
function Split_Panel:setOrientation(v) end

--- Sets the second child for this Split_Panel widget.
---@param child_idx any
---@return nil
function Split_Panel:setSecondChild(child_idx) end

--- Sets the split position for this Split_Panel widget.
---@param v any
---@return nil
function Split_Panel:setSplitPosition(v) end

--- Adds StatusBar-specific methods.
---@class Status_Bar
local Status_Bar = {}

--- Adds a section entry to this Status_Bar widget.
---@param text any
---@param width? any (optional)
---@return nil
function Status_Bar:addSection(text, width) end

--- Returns the section count of this Status_Bar widget.
---@return integer
function Status_Bar:getSectionCount() end

--- Returns the section text of this Status_Bar widget.
---@param section_idx any
---@return integer
function Status_Bar:getSectionText(section_idx) end

--- Resizes the section list for this Status_Bar widget.
---@param count any
---@return nil
function Status_Bar:setSectionCount(count) end

--- Sets the section text for this Status_Bar widget.
---@param section_idx any
---@param text any
---@return nil
function Status_Bar:setSectionText(section_idx, text) end

--- Compatibility shim for assigning a widget to a section.
---@param section_idx any
---@param widget any
---@return nil
function Status_Bar:setSectionWidget(section_idx, widget) end

--- Adds Switch-specific methods to a widget table.
---@class Switch
local Switch = {}

--- Returns the on/off state of this Switch widget.
---@return boolean
function Switch:isOn() end

--- Sets the on/off state of this Switch widget.
---@param on any
---@return nil
function Switch:setOn(on) end

--- Toggles the on/off state of this Switch widget.
---@return nil
function Switch:toggle() end

--- Adds TabBar-specific methods (1-based indices in Lua).
---@class Tab_Bar
local Tab_Bar = {}

--- Adds a tab entry to this Tab_Bar widget.
---@param label any
---@return nil
function Tab_Bar:addTab(label) end

--- Returns the active tab of this Tab_Bar widget.
---@return integer
function Tab_Bar:getActiveTab() end

--- Returns the tab of this Tab_Bar widget.
---@param index any
---@return integer
function Tab_Bar:getTab(index) end

--- Returns the tab count of this Tab_Bar widget.
---@return integer
function Tab_Bar:getTabCount() end

--- Removes the tab from this Tab_Bar widget.
---@param index any
---@return nil
function Tab_Bar:removeTab(index) end

--- Sets the active tab for this Tab_Bar widget.
---@param index any
---@return nil
function Tab_Bar:setActiveTab(index) end

--- Adds TextInput-specific methods to a widget table.
---@class Text_Input
local Text_Input = {}

--- Returns the cursor position of this Text_Input widget.
---@return integer
function Text_Input:getCursorPosition() end

--- Returns the placeholder of this Text_Input widget.
---@return string
function Text_Input:getPlaceholder() end

--- Returns the text of this Text_Input widget.
---@return string
function Text_Input:getText() end

--- Returns true if focused is enabled for this Text_Input widget.
---@return boolean
function Text_Input:isFocused() end

--- Sets the max length for this Text_Input widget.
---@param n any
---@return nil
function Text_Input:setMaxLength(n) end

--- Sets the placeholder for this Text_Input widget.
---@param text any
---@return nil
function Text_Input:setPlaceholder(text) end

--- Sets the text for this Text_Input widget.
---@param text any
---@return nil
function Text_Input:setText(text) end

--- Adds Toast-specific methods.
---@class Toast
local Toast = {}

--- Returns the duration of this Toast widget.
---@return number
function Toast:getDuration() end

--- Returns the message of this Toast widget.
---@return string
function Toast:getMessage() end

--- Returns the progress of this Toast widget.
---@return number
function Toast:getProgress() end

--- Returns true if expired is enabled for this Toast widget.
---@return boolean
function Toast:isExpired() end

--- Sets the duration for this Toast widget.
---@param d any
---@return nil
function Toast:setDuration(d) end

--- Sets the message for this Toast widget.
---@param msg any
---@return nil
function Toast:setMessage(msg) end

--- Adds Toolbar-specific methods.
---@class Toolbar
local Toolbar = {}

--- Adds a button entry to this Toolbar widget.
---@param id any
---@param tooltip? any (optional)
---@return nil
function Toolbar:addButton(id, tooltip) end

--- Adds a separator entry to this Toolbar widget.
---@return nil
function Toolbar:addSeparator() end

--- Adds a spacer entry to this Toolbar widget.
---@param size? any (optional)
---@return nil
function Toolbar:addSpacer(size) end

--- Returns the button of this Toolbar widget.
---@param id any
---@return boolean
function Toolbar:getButton(id) end

--- Returns the orientation of this Toolbar widget.
---@return string
function Toolbar:getOrientation() end

--- Returns true if button toggled is enabled for this Toolbar widget.
---@param id any
---@return boolean
function Toolbar:isButtonToggled(id) end

--- Sets the button enabled for this Toolbar widget.
---@param id any
---@param enabled any
---@return nil
function Toolbar:setButtonEnabled(id, enabled) end

--- Sets the button toggled for this Toolbar widget.
---@param id any
---@param toggled any
---@return nil
function Toolbar:setButtonToggled(id, toggled) end

--- Sets the orientation for this Toolbar widget.
---@param v any
---@return nil
function Toolbar:setOrientation(v) end

--- Adds TooltipPanel-specific methods.
---@class Tooltip_Panel
local Tooltip_Panel = {}

--- Returns the delay of this Tooltip_Panel widget.
---@return number
function Tooltip_Panel:getDelay() end

--- Returns the target of this Tooltip_Panel widget.
---@return nil
function Tooltip_Panel:getTarget() end

--- Returns the text of this Tooltip_Panel widget.
---@return string
function Tooltip_Panel:getText() end

--- Sets the delay for this Tooltip_Panel widget.
---@param v any
---@return nil
function Tooltip_Panel:setDelay(v) end

--- Sets the target for this Tooltip_Panel widget.
---@param target? any (optional)
---@return nil
function Tooltip_Panel:setTarget(target) end

--- Sets the text for this Tooltip_Panel widget.
---@param text any
---@return nil
function Tooltip_Panel:setText(text) end

--- Adds TreeView-specific methods (1-based indices in Lua).
---@class Tree_View
local Tree_View = {}

--- Adds a node entry to this Tree_View widget.
---@param text any
---@param parent_index? any (optional)
---@return nil
function Tree_View:addNode(text, parent_index) end

--- Clears all nodes entries from this Tree_View widget.
---@return nil
function Tree_View:clearNodes() end

--- Performs the collapse all operation on this Tree_View widget.
---@return nil
function Tree_View:collapseAll() end

--- Performs the collapse node operation on this Tree_View widget.
---@param index any
---@return nil
function Tree_View:collapseNode(index) end

--- Performs the expand all operation on this Tree_View widget.
---@return nil
function Tree_View:expandAll() end

--- Performs the expand node operation on this Tree_View widget.
---@param index any
---@return nil
function Tree_View:expandNode(index) end

--- Returns the child nodes of this Tree_View widget.
---@param index any
---@return nil
function Tree_View:getChildNodes(index) end

--- Returns the node count of this Tree_View widget.
---@return integer
function Tree_View:getNodeCount() end

--- Returns the node depth of this Tree_View widget.
---@param index any
---@return nil
function Tree_View:getNodeDepth(index) end

--- Returns the node text of this Tree_View widget.
---@param index any
---@return string
function Tree_View:getNodeText(index) end

--- Returns the parent node of this Tree_View widget.
---@param index any
---@return nil
function Tree_View:getParentNode(index) end

--- Returns the selected node of this Tree_View widget.
---@return integer
function Tree_View:getSelectedNode() end

--- Returns true if expanded is enabled for this Tree_View widget.
---@param index any
---@return boolean
function Tree_View:isExpanded(index) end

--- Returns true if node expanded is enabled for this Tree_View widget.
---@param index any
---@return boolean
function Tree_View:isNodeExpanded(index) end

--- Removes the node from this Tree_View widget.
---@param index any
---@return nil
function Tree_View:removeNode(index) end

--- Sets the node icon for this Tree_View widget.
---@param index any
---@param icon any
---@return nil
function Tree_View:setNodeIcon(index, icon) end

--- Sets the node text for this Tree_View widget.
---@param index any
---@param text any
---@return nil
function Tree_View:setNodeText(index, text) end

--- Sets the selected node for this Tree_View widget.
---@param index any
---@return nil
function Tree_View:setSelectedNode(index) end

--- Toggles the expanded/collapsed status of a Tree_View node.
---@param index any
---@return nil
function Tree_View:toggleNode(index) end

--- Adds a child widget to this container.
---@param child any
---@return nil
function lurek.ui.addChild(child) end

--- Anchors this widget to a world-space entity by its numeric ID.
---@param entity_id any
function lurek.ui.attachToEntity(entity_id) end

--- Registers a data-binding key on this widget.
---@param key any
function lurek.ui.bind(key) end

--- Removes all anchor constraints.
---@return nil
function lurek.ui.clearAnchor() end

--- Returns whether (x, y) is inside this widget.
---@param x any
---@param y any
---@return boolean
function lurek.ui.containsPoint(x, y) end

--- Removes the entity anchor from this widget, restoring normal layout positioning.
---@return nil
function lurek.ui.detachFromEntity() end

--- Instantly fades the widget in (sets alpha to `1.0`).
---@return nil
function lurek.ui.fadeIn() end

--- Instantly fades the widget out (sets alpha to `0.0` and hides it).
---@return nil
function lurek.ui.fadeOut() end

--- Recursively searches for a widget by id starting from this widget.
---@param id any
---@return table
function lurek.ui.findById(id) end

--- Returns the widget's current alpha transparency.
---@return number
function lurek.ui.getAlpha() end

--- Returns the number of children in this container.
---@return number
function lurek.ui.getChildCount() end

--- Returns this container's children as widget-handle tables.
---@return table
function lurek.ui.getChildren() end

--- Returns the flex-grow factor.
---@return number
function lurek.ui.getFlexGrow() end

--- Returns the flex-shrink factor.
---@return number
function lurek.ui.getFlexShrink() end

--- Returns the widget string identifier.
---@return string
function lurek.ui.getId() end

--- Returns the widget margin (top, right, bottom, left).
---@return number
function lurek.ui.getMargin() end

--- Returns the maximum widget size.
---@return number
function lurek.ui.getMaxSize() end

--- Returns the minimum widget size.
---@return number
function lurek.ui.getMinSize() end

--- Returns the widget padding (top, right, bottom, left).
---@return number
function lurek.ui.getPadding() end

--- Returns the widget position.
---@return number
function lurek.ui.getPosition() end

--- Returns the computed screen-space rectangle after layout.
---@return number
function lurek.ui.getRect() end

--- Returns the current width and height of the widget in UI pixels.
---@return number
function lurek.ui.getSize() end

--- Returns the widget interaction state name.
---@return string
function lurek.ui.getState() end

--- Returns the widget tooltip text.
---@return string
function lurek.ui.getTooltip() end

--- Returns the widget z-order.
---@return number
function lurek.ui.getZOrder() end

--- Returns whether the widget is enabled.
---@return boolean
function lurek.ui.isEnabled() end

--- Returns whether the widget is visible.
---@return boolean
function lurek.ui.isVisible() end

--- Removes a child widget from this container.
---@param child any
---@return nil
function lurek.ui.removeChild(child) end

--- Sets the widget's alpha transparency (`0.0` fully transparent, `1.0` opaque).
---@param alpha any
function lurek.ui.setAlpha(alpha) end

--- Sets anchor edges (left, top, right, bottom).
---@param left number
---@param top number
---@param right number
---@param bottom number
---@return nil
function lurek.ui.setAnchor(left, top, right, bottom) end

--- Sets center anchor offsets.
---@param cx? any (optional)
---@param cy? any (optional)
---@return nil
function lurek.ui.setAnchorCenter(cx, cy) end

--- Sets whether the widget is enabled.
---@param v any
---@return nil
function lurek.ui.setEnabled(v) end

--- Sets the flex-grow factor.
---@param grow any
---@return nil
function lurek.ui.setFlexGrow(grow) end

--- Sets the flex-shrink factor.
---@param shrink any
---@return nil
function lurek.ui.setFlexShrink(shrink) end

--- Sets the widget string identifier.
---@param id any
---@return nil
function lurek.ui.setId(id) end

--- Sets widget margin (CSS-like: top, right?, bottom?, left?).
---@param top any
---@param right? any (optional)
---@param bottom? any (optional)
---@param left? any (optional)
---@return nil
function lurek.ui.setMargin(top, right, bottom, left) end

--- Sets the maximum widget size.
---@param w any
---@param h any
---@return nil
function lurek.ui.setMaxSize(w, h) end

--- Sets the minimum widget size.
---@param w any
---@param h any
---@return nil
function lurek.ui.setMinSize(w, h) end

--- Registers a callback invoked when this widget's value changes.
---@param f any
---@return nil
function lurek.ui.setOnChange(f) end

--- Registers a callback invoked when this widget is clicked.
---@param f any
---@return nil
function lurek.ui.setOnClick(f) end

--- Stores a custom draw callback for later invocation.
---@param self any
---@param f any
---@return nil
function lurek.ui.setOnDraw(self, f) end

--- Sets widget padding (CSS-like: top, right?, bottom?, left?).
---@param top any
---@param right? any (optional)
---@param bottom? any (optional)
---@param left? any (optional)
---@return nil
function lurek.ui.setPadding(top, right, bottom, left) end

--- Sets the widget position.
---@param x any
---@param y any
---@return nil
function lurek.ui.setPosition(x, y) end

--- Sets the width and height of the widget in UI pixels.
---@param w any
---@param h any
---@return nil
function lurek.ui.setSize(w, h) end

--- Sets the widget tooltip text.
---@param text any
---@return nil
function lurek.ui.setTooltip(text) end

--- Shows or hides the widget; hidden widgets are not rendered or interactive.
---@param v any
---@return nil
function lurek.ui.setVisible(v) end

--- Sets the widget z-order for draw sorting.
---@param z any
---@return nil
function lurek.ui.setZOrder(z) end

--- Instantly moves the widget to `(x, y)` and makes it visible.
---@param x any
---@param y any
function lurek.ui.slideIn(x, y) end

--- Instantly moves the widget to the off-screen position `(x, y)` and hides it.
---@param x any
---@param y any
function lurek.ui.slideOut(x, y) end

--- Removes the data-binding key from this widget.
---@return nil
function lurek.ui.unbind() end

---@class lurek.window
lurek.window = {}

--- Requests the window to close.
---@return nil
function lurek.window.close() end

--- Requests the window manager to bring the window to the foreground.
---@return nil
function lurek.window.focus() end

--- Converts physical pixels to device-independent coordinates.
---@param value any
---@return number
function lurek.window.fromPixels(value) end

--- Returns the DPI scaling factor for the window.
---@return number
function lurek.window.getDPIScale() end

--- Returns the desktop resolution as width, height.
---@return integer
function lurek.window.getDesktopDimensions() end

--- Returns the window dimensions as width, height.
---@return integer
function lurek.window.getDimensions() end

--- Returns the number of connected displays.
---@return integer
function lurek.window.getDisplayCount() end

--- Returns the name of the current display.
---@param display? any (optional)
---@return string
function lurek.window.getDisplayName(display) end

--- Returns the current display orientation.
---@return string
function lurek.window.getDisplayOrientation() end

--- Returns the fullscreen state and type string.
---@return boolean
function lurek.window.getFullscreen() end

--- Returns all available fullscreen video modes.
---@return table
function lurek.window.getFullscreenModes() end

--- Returns the logical game height in virtual pixels.
---@return number
function lurek.window.getGameHeight() end

--- Returns the logical game width in virtual pixels.
---@return number
function lurek.window.getGameWidth() end

--- Returns the window height in pixels.
---@return integer
function lurek.window.getHeight() end

--- Returns the window dimensions and mode flags as width, height, flags.
---@return integer
function lurek.window.getMode() end

--- Returns the native DPI scale factor.
---@return number
function lurek.window.getNativeDPIScale() end

--- Returns the window dimensions in physical pixels.
---@return integer
function lurek.window.getPixelDimensions() end

--- Returns the window position as x, y in screen coordinates.
---@return integer
function lurek.window.getPosition() end

--- Returns the safe display area as x, y, w, h.
---@return number
function lurek.window.getSafeArea() end

--- Returns viewport scale and offset information as a table.
---@return table
function lurek.window.getScaleInfo() end

--- Returns the current viewport scale mode string.
---@return string
function lurek.window.getScaleMode() end

--- Returns the OS color theme preference.
---@return string
function lurek.window.getSystemTheme() end

--- Returns the current window title.
---@return string
function lurek.window.getTitle() end

--- Returns the current VSync mode integer.
---@return integer
function lurek.window.getVSync() end

--- Returns the window width in pixels.
---@return integer
function lurek.window.getWidth() end

--- Returns whether the window has keyboard focus.
---@return boolean
function lurek.window.hasFocus() end

--- Returns whether the mouse cursor is inside the window.
---@return boolean
function lurek.window.hasMouseFocus() end

--- Returns whether the window is in fullscreen mode.
---@return boolean
function lurek.window.isFullscreen() end

--- Returns whether high-DPI rendering is allowed.
---@return boolean
function lurek.window.isHighDPIAllowed() end

--- Returns whether the window is maximized.
---@return boolean
function lurek.window.isMaximized() end

--- Returns whether the window is minimized.
---@return boolean
function lurek.window.isMinimized() end

--- Returns whether the window is open.
---@return boolean
function lurek.window.isOpen() end

--- Returns whether the window can be resized by the user.
---@return boolean
function lurek.window.isResizable() end

--- Returns whether the window is visible.
---@return boolean
function lurek.window.isVisible() end

--- Maximizes the window to fill the desktop.
---@return nil
function lurek.window.maximize() end

--- Minimizes the window to the taskbar.
---@return nil
function lurek.window.minimize() end

--- Registers a callback invoked (with the new scale factor) when the display
---@param func any
---@return nil
function lurek.window.onDpiChange(func) end

--- Opens a blocking native file-open dialog. Returns the chosen path string
---@param opts? any (optional)
---@return string|nil
function lurek.window.openFileDialog(opts) end

--- Polls for a pending DPI change event and returns the new scale factor if any.
---@return table|nil
function lurek.window.pollDpiChange() end

--- Flashes the window in the taskbar to request user attention.
---@return nil
function lurek.window.requestAttention() end

--- Restores the window from minimized or maximized state.
---@return nil
function lurek.window.restore() end

--- Enables or disables fullscreen mode.
---@param enabled any
---@param fstype? any (optional)
---@return nil
function lurek.window.setFullscreen(enabled, fstype) end

--- Sets the window icon from a file path.
---@param path any
---@return nil
function lurek.window.setIcon(path) end

--- Resizes the window and optionally changes fullscreen and vsync.
---@param w any
---@param h any
---@param flags? any (optional)
---@return nil
function lurek.window.setMode(w, h, flags) end

--- Moves the window to the given screen position.
---@param x any
---@param y any
---@return nil
function lurek.window.setPosition(x, y) end

--- Sets the viewport scale mode.
---@param mode any
---@return nil
function lurek.window.setScaleMode(mode) end

--- Sets the window title bar text.
---@param title any
---@return nil
function lurek.window.setTitle(title) end

--- Sets the VSync mode (1=on, 0=off, -1=adaptive).
---@param mode any
---@return nil
function lurek.window.setVSync(mode) end

--- Shows a platform-native message box dialog.
---@param title string
---@param message string
---@param boxType? string? (optional)
---@param btnType? string? (optional)
---@return string
function lurek.window.showMessageBox(title, message, boxType, btnType) end

--- Converts a device-independent coordinate to physical pixels.
---@param value any
---@return number
function lurek.window.toPixels(value) end
