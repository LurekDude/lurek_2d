-- content/examples/ai.lua
-- Demonstrates every lurek.ai.* function with realistic game AI usage patterns.
-- Run: cargo run -- content/examples/ai.lua

--@api-stub: lurek.ai.newWorld
-- Creates an isolated AI world for agents, blackboards, and custom decision callbacks
do
  -- Use an AI world to manage all NPCs in a level. Each world is independent,
  -- so you can pause dungeon AI while overworld agents keep running.
  -- Scenario: open-world RPG with separate AI worlds per region.
  local world = lurek.ai.newWorld()
  world:addAgent("guard_01")
  -- Call world:update(dt) every frame to tick all registered agents.
  function lurek.process(dt) world:update(dt) end
end

--@api-stub: lurek.ai.newBlackboard
-- Creates an empty AI blackboard for typed local facts
do
  -- Blackboards are key-value stores for AI knowledge. Agents read/write facts
  -- here so decision logic stays decoupled from game state.
  -- Scenario: stealth game guard shares "alert_level" across patrol group.
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("alert_level", 0.3)
  bb:setBool("player_seen", false)
end

--@api-stub: lurek.ai.newStateMachine
-- Creates an empty finite state machine with Lua-backed states and transitions
do
  -- FSMs are ideal for NPCs with clear, discrete behavior phases.
  -- Each state has onEnter/onUpdate/onExit callbacks for clean transitions.
  -- Scenario: guard patrol AI — idle → patrol → alert → chase → attack.
  local fsm = lurek.ai.newStateMachine()
  fsm:addState("patrol", { onEnter = function() lurek.log.info("patrolling", "ai") end })
  fsm:addState("chase", {})
  fsm:setInitialState("patrol")
end

--@api-stub: lurek.ai.newBehaviorTree
-- Creates an empty behavior tree that can receive a root node
do
  -- Behavior trees compose complex AI from simple reusable nodes.
  -- Set a root node, then call bt:tick(dt) each frame to evaluate.
  -- Scenario: boss phase transitions — check HP, pick attack pattern, execute.
  local bt = lurek.ai.newBehaviorTree()
  local root = lurek.ai.newSequence()
  root:addChild(lurek.ai.newAction(function() return "success" end))
  bt:setRoot(root)
end

--@api-stub: lurek.ai.newSelector
-- Creates a behavior tree selector node with no children
do
  -- A selector tries each child until one succeeds (OR logic).
  -- Use it for fallback behaviors: try attack, else flee, else idle.
  -- Scenario: enemy AI picks first viable action from priority list.
  local sel = lurek.ai.newSelector()
  sel:addChild(lurek.ai.newCondition(function() return false end))
  sel:addChild(lurek.ai.newAction(function() return "success" end))
end

--@api-stub: lurek.ai.newSequence
-- Creates a behavior tree sequence node with no children
do
  -- A sequence runs children in order, stopping on first failure (AND logic).
  -- Use it for multi-step tasks: check condition → move → attack.
  -- Scenario: melee NPC must be in range AND have stamina before swinging.
  local seq = lurek.ai.newSequence()
  seq:addChild(lurek.ai.newCondition(function() return true end))
  seq:addChild(lurek.ai.newAction(function() return "success" end))
end

--@api-stub: lurek.ai.newParallel
-- Creates a behavior tree parallel node with optional success and failure policies
do
  -- Parallel nodes tick all children simultaneously each frame.
  -- Policies: "require_all" = all must succeed; "require_one" = one failure aborts.
  -- Scenario: NPC walks AND talks — both actions run concurrently.
  local par = lurek.ai.newParallel("require_all", "require_one")
  par:addChild(lurek.ai.newAction(function() return "success" end))
  par:addChild(lurek.ai.newAction(function() return "running" end))
end

--@api-stub: lurek.ai.newInverter
-- Creates a behavior tree inverter decorator with an empty sequence child
do
  -- Inverter flips child result: success→failure, failure→success.
  -- Useful for negating conditions without writing inverse logic.
  -- Scenario: "NOT player_visible" check reuses the same visibility condition.
  local inv = lurek.ai.newInverter()
  inv:setChild(lurek.ai.newCondition(function() return false end))
  local bt = lurek.ai.newBehaviorTree(); bt:setRoot(inv)
end

--@api-stub: lurek.ai.newRepeater
-- Creates a behavior tree repeater decorator with an optional repeat count
do
  -- Repeater re-runs its child N times (or infinitely if count is nil).
  -- The count parameter controls how many iterations before returning success.
  -- Scenario: fire 3 arrows in burst — repeat the "shoot" action 3 times.
  local rep = lurek.ai.newRepeater(3)
  rep:setChild(lurek.ai.newAction(function() return "success" end))
  local bt = lurek.ai.newBehaviorTree(); bt:setRoot(rep)
end

--@api-stub: lurek.ai.newSucceeder
-- Creates a behavior tree succeeder decorator with an empty sequence child
do
  -- Succeeder always returns success regardless of child result.
  -- Use it for optional actions that should never abort a sequence.
  -- Scenario: "try to taunt" in a sequence — even if taunt fails, continue.
  local suc = lurek.ai.newSucceeder()
  suc:setChild(lurek.ai.newAction(function() return "failure" end))
  local bt = lurek.ai.newBehaviorTree(); bt:setRoot(suc)
end

--@api-stub: lurek.ai.newAction
-- Creates a behavior tree action leaf backed by a Lua callback
do
  -- Action nodes do the actual work. The callback receives dt and must
  -- return "success", "failure", or "running" (for multi-frame actions).
  -- Scenario: "move_to_cover" returns "running" until the NPC arrives.
  local act = lurek.ai.newAction(function(dt)
      return "success"
  end)
end

--@api-stub: lurek.ai.newCondition
-- Creates a behavior tree condition leaf backed by a Lua callback
do
  -- Condition nodes test a predicate — return true for success, false for failure.
  -- They never return "running"; use them as guards before action nodes.
  -- Scenario: check "is HP below 30%?" before triggering heal behavior.
  local hp_low = lurek.ai.newCondition(function() return true end)
  local seq = lurek.ai.newSequence()
  seq:addChild(hp_low)
end

--@api-stub: lurek.ai.newSteeringManager
-- Creates an empty steering manager with support for built-in and custom behaviors
do
  -- Steering combines movement behaviors (seek, flee, wander) into one force.
  -- Weight parameter (last arg) controls how much each behavior contributes.
  -- Scenario: zombie wanders randomly but seeks the player when nearby.
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  sm:addWander(20, 40, 5, 0.3)
end

--@api-stub: LSteeringManager:setPath
-- Sets the path of this steering manager.
do
  -- Assigns a waypoint path for the steering manager to follow.
  -- Parameters: path, lookahead distance, weight. Larger lookahead = smoother curves.
  -- Scenario: RTS unit follows A* path with smooth cornering.
  local grid = lurek.pathfind.newPathGrid(10, 10, 32)
  local path = grid:findPath(1, 1, 10, 10)
  local sm = lurek.ai.newSteeringManager()
  if path then
    sm:setPath(path, 12.0, 1.0)
    if sm:hasPath() then
      local fx, fy = sm:calculate(0, 0, 0, 0, 120, 240, 1 / 60)
      lurek.log.info("path force: " .. tostring(fx) .. ", " .. tostring(fy), "ai")
    end
  end
end

--@api-stub: LSteeringManager:getPathProgress
-- Returns the path progress of this steering manager.
do
  -- Returns current waypoint index and total count — track how far along the path.
  -- Use this to trigger events at waypoints (e.g., stop at checkpoint 3).
  -- Scenario: courier NPC delivers packages at specific path milestones.
  local sm = lurek.ai.newSteeringManager()
  sm:setPath({ { x = 16, y = 16 }, { x = 48, y = 16 } })
  local idx, total = sm:getPathProgress()
  lurek.log.info("path progress " .. tostring(idx) .. "/" .. tostring(total), "ai")
  sm:clearPath()
end

--@api-stub: lurek.ai.newQLearner
-- Creates a Q-learner with fixed state and action counts
do
  -- Q-learning trains NPC behavior through reward signals over time.
  -- Parameters: state_count, action_count. Learning rate controls adaptation speed.
  -- Scenario: enemy learns which attack patterns work against the player.
  local ql = lurek.ai.newQLearner(16, 4)
  ql:setLearningRate(0.1)
  ql:setExplorationRate(0.2)
end

--@api-stub: lurek.ai.newUtilityAI
-- Creates an empty utility AI action scorer
do
  -- Utility AI scores all possible actions and picks the highest-value one.
  -- Each action has a scoring function (returns 0..1) and a weight multiplier.
  -- Scenario: survival NPC weighs eat vs sleep vs flee based on current needs.
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("flee", function() return 0.8 end, 1.0)
  uai:addAction("attack", function() return 0.4 end, 1.0)
end

--@api-stub: lurek.ai.newDialogueAI
-- Creates an empty dialogue selector for weighted topics and branches
do
  -- DialogueAI picks conversation topics based on game state and utility scores.
  -- Topics can require FSM state or BT status as prerequisites.
  -- Scenario: tavern NPC shifts from smalltalk to quest hints when trust is high.
  local d = lurek.ai.newDialogueAI()
  local t = d:type()
  local _is_dialogue = d:typeOf("DialogueAI")
  lurek.log.info("dialogue type: " .. tostring(t), "ai")
  d:addTopic("smalltalk", 0.2, nil, nil, "smalltalk_score")
  d:addTopic("combat", 0.2, "combat", "success", "combat_score")
  d:addBranch("combat", "taunt", 0.3, "combat", nil, "taunt_score")
  d:addBranch("combat", "threat", 0.2, "combat", nil, "threat_score")
  d:setFSMState("combat")
  d:setBTStatus("success")
  d:setUtilityScore("smalltalk_score", 0.1)
  d:setUtilityScore("combat_score", 0.9)
  d:setUtilityScore("taunt_score", 0.6)
  d:setUtilityScore("threat_score", 0.4)

  local topic = d:selectTopic()
  if topic then
    local branch = d:selectBranch(topic)
    lurek.log.info("dialogue: " .. tostring(topic) .. "/" .. tostring(branch), "ai")
  end
  local topic_count = d:getTopicCount()
  lurek.log.info("dialogue topics: " .. tostring(topic_count), "ai")
  d:clearUtilityScores()
end

--@api-stub: lurek.ai.newGOAPPlanner
-- Creates an empty GOAP planner for boolean world-state planning
do
  -- GOAP finds action sequences to reach a goal from the current world state.
  -- Actions have preconditions, effects, and cost — the planner picks cheapest path.
  -- Scenario: squad coordination — plan "get_ammo → reload → suppress" automatically.
  local planner = lurek.ai.newGOAPPlanner()
  planner:addAction("eat", 1.0, function() lurek.log.info("eating", "ai") end)
  planner:addGoal("not_hungry", 1.0)
end

--@api-stub: lurek.ai.newInfluenceMap
-- Creates a grid influence map with the supplied cell dimensions and world cell size
do
  -- Influence maps let AI reason about spatial control (threat zones, territory).
  -- Parameters: grid_w, grid_h, cell_size. Layers separate concerns (threat vs resources).
  -- Scenario: RTS units avoid high-threat cells and prefer resource-rich areas.
  local infl = lurek.ai.newInfluenceMap(64, 64, 16)
  infl:addLayer("threat")
  infl:stampInfluence("threat", 320, 240, 80, 1.0, 1.0)
end

--@api-stub: lurek.ai.newSquad
-- Creates an empty named squad
do
  -- Squads group agents for coordinated tactics (flanking, covering fire).
  -- Formation type and spacing control how members position relative to the leader.
  -- Scenario: tactical shooter — 4-man squad holds wedge formation while advancing.
  local squad = lurek.ai.newSquad("alpha")
  squad:addMember("guard_01")
  squad:setFormation("wedge", 32)
end

--@api-stub: lurek.ai.newCommandQueue
-- Creates an empty command queue for callback-backed AI commands
do
  -- Command queues serialize AI actions so they execute one-at-a-time in order.
  -- Each command has a name, callback, and optional params table for context.
  -- Scenario: boss fight — queue "roar", "charge", "slam" as sequential phases.
  local q = lurek.ai.newCommandQueue()
  q:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  q:enqueue("attack", function() end, { priority = 5 })
end

--@api-stub: lurek.ai.newTraitProfile
-- Creates an empty trait profile with modifier support
do
  -- Trait profiles store personality values (0..1) that influence AI decisions.
  -- Modifiers can temporarily shift traits (e.g., rage buff increases aggression).
  -- Scenario: cowardly goblin flees at 50% HP; brave knight fights to the end.
  local traits = lurek.ai.newTraitProfile()
  traits:set("aggression", 0.7)
  traits:set("courage", 0.4)
end

--@api-stub: lurek.ai.newStimulusWorld
-- Creates an empty stimulus world for visual and auditory stimulus records
do
  -- Stimulus world tracks sensory events (sounds, sights) that agents can perceive.
  -- Auditory params: x, y, loudness, radius, decay_rate, tag. Stimuli fade over time.
  -- Scenario: stealth game — footsteps create auditory stimuli that alert guards.
  local sw = lurek.ai.newStimulusWorld()
  sw:addAuditory(100, 200, 1.0, 150, 0.5, "footstep")
  function lurek.process(dt) sw:update(dt) end
end

--@api-stub: lurek.ai.newContextSteering
-- Creates a context steering model with the requested directional slot count
do
  -- Context steering uses directional slots to blend seek/avoid into one smooth heading.
  -- More slots = finer direction resolution but slightly higher cost. 8-16 is typical.
  -- Scenario: crowd of zombies navigating around obstacles toward the player.
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  cs:addAvoidPoint(250, 200, 64, 1.0)
end

--@api-stub: lurek.ai.newNeedSystem
-- Creates an empty need system for decaying named needs
do
  -- Need system models Sims-style drives that decay over time and drive behavior.
  -- Parameters per need: name, decay_rate, threshold, weight. Highest urgency wins.
  -- Scenario: survival game NPC eats when hunger > threshold, sleeps when energy low.
  local needs = lurek.ai.newNeedSystem()
  needs:addNeed("hunger", 0.05, 0.6, 1.5)
  function lurek.process(dt) needs:update(dt) end
end

--@api-stub: lurek.ai.newAIDirector
-- Creates an AI director for tension, phase, and pacing factor calculations
do
  -- AI Director manages game pacing by tracking tension and spawning enemies accordingly.
  -- Tension 0..1 ramps up during combat, decays during rest — like Left 4 Dead's director.
  -- Scenario: horde game — director spawns harder waves when tension drops too low.
  local dir = lurek.ai.newAIDirector()
  dir:setTension(0.4)
  function lurek.process(dt) dir:update(dt) end
end

--@api-stub: lurek.ai.newHTNDomain
-- Creates an empty hierarchical task network domain
do
  -- HTN decomposes high-level goals into ordered primitive tasks via methods.
  -- Primitives have preconditions, effects, and deletions on world state.
  -- Scenario: "defeat_enemy" decomposes into "approach → aim → fire → confirm_kill".
  local d = lurek.ai.newHTNDomain()
  d:addPrimitive("attack", { "has_weapon" }, { "enemy_dead" }, {})
end

--@api-stub: lurek.ai.newMCTSEngine
-- Creates a Monte Carlo tree search engine with deterministic configuration
do
  -- MCTS simulates random playouts to find strong moves in large decision spaces.
  -- Parameters: iterations, exploration_c, max_depth, seed. More iterations = stronger play.
  -- Scenario: board game AI (chess, Go) or turn-based tactical combat decision making.
  local mcts = lurek.ai.newMCTSEngine(200, 1.41, 32, 12345)
  local actions = function(s) return { 1, 2, 3 } end
  local apply = function(s, a) return s + a end
  local eval = function(s) return s % 7 end
end

--@api-stub: lurek.ai.newEmotionModel
-- Creates an empty emotion model for named decaying emotion values
do
  -- Emotion model tracks named feelings that rise from events and decay over time.
  -- Parameters per emotion: name, initial_value, decay_rate, max_value.
  -- Scenario: NPC's fear builds when attacked, causing flee behavior at high levels.
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.1, 0.2)
  em:add("anger", 0.0, 0.05, 0.15)
end

--@api-stub: lurek.ai.newORCASolver
-- Creates an ORCA avoidance solver with the supplied prediction horizon
do
  -- ORCA computes collision-free velocities for crowds without explicit pathfinding.
  -- Prediction horizon (seconds) controls how far ahead agents anticipate collisions.
  -- Scenario: 200 villagers navigating a market square without overlapping each other.
  local orca = lurek.ai.newORCASolver(2.0)
  local idx = orca:addAgent(100, 100, 16, 80)
  orca:setPreferredVelocity(idx, 50, 0)
end

--@api-stub: lurek.ai.newNeuralNet
-- Creates an empty feed-forward neural network
do
  -- Feed-forward neural net maps inputs to outputs through weighted layers.
  -- addLayer(inputs, outputs, activation) — "relu", "sigmoid", "softmax" supported.
  -- Scenario: NPC learns to dodge projectiles from sensor inputs (distances, angles).
  local nn = lurek.ai.newNeuralNet()
  nn:addLayer(4, 8, "relu")
  nn:addLayer(8, 2, "softmax")
end

--@api-stub: lurek.ai.newGeneticAlgorithm
-- Creates a genetic algorithm population with fixed chromosome length
do
  -- GA evolves a population of solutions by selection, crossover, and mutation.
  -- Parameters: population_size, chromosome_length, seed. Set fitness per individual.
  -- Scenario: evolving enemy stat distributions that challenge the player optimally.
  local ga = lurek.ai.newGeneticAlgorithm(50, 16, 42)
  ga:setFitness(1, 0.7)
  function lurek.process(dt) ga:evolve() end
end

--@api-stub: lurek.ai.newBandit
-- Creates a multi-armed bandit with a named selection strategy
do
  -- Multi-armed bandit balances exploration vs exploitation across N choices.
  -- Strategies: "ucb1", "epsilon_greedy", "softmax". Epsilon controls random exploration.
  -- Scenario: dynamic difficulty — pick which enemy type to spawn based on player deaths.
  local b = lurek.ai.newBandit(4, "ucb1", 0.1, 99)
  local arm = b:select()
  b:update(arm, 1.0)
end

--@api-stub: lurek.ai.newNeuroevolution
-- Creates a neuroevolution population from a layer specification table
do
  -- Neuroevolution combines neural nets with genetic algorithms — no backprop needed.
  -- Layer spec defines network topology; population_size and seed control evolution.
  -- Scenario: evolving flocking creatures whose brains improve across generations.
  local layers = { { inputs = 4, outputs = 8, activation = "relu" }, { inputs = 8, outputs = 2, activation = "softmax" } }
  local ne = lurek.ai.newNeuroevolution(layers, 30, 1)
  function lurek.process(dt) ne:evolve() end
end

--@api-stub: lurek.ai.newStrategyAI
-- Creates a strategy AI that reevaluates goals on a fixed interval
do
  -- Strategy AI periodically re-ranks goals and picks the best one to pursue.
  -- Interval (seconds) controls how often the AI reconsiders — lower = more reactive.
  -- Scenario: RTS faction AI switches between "expand", "defend", "attack" every 2s.
  local s = lurek.ai.newStrategyAI(2.0)
  s:addGoal("expand")
  s:addGoal("defend")
end

--@api-stub: lurek.ai.newAILod
-- Creates a default AI level-of-detail tier selector
do
  -- AI LOD reduces update frequency for distant or off-screen agents to save CPU.
  -- shouldUpdate(tier, distance) returns true only when the agent's budget allows.
  -- Scenario: 500 NPCs in open world — only nearby ones get full AI updates each frame.
  local lod = lurek.ai.newAILod()
  if lod:shouldUpdate(1, 60) then lurek.log.debug("tier 1 update", "ai") end
end
-- do  -- AIWorld:addAgent
--   local world = lurek.ai.newWorld()
--   local guard = world:addAgent("guard_01")
--   guard:setPosition(100, 100)
-- end

--@api-stub: LAIWorld:getAgent
-- Returns the agent of this ai world.
do
  local world = lurek.ai.newWorld()
  world:addAgent("guard_01")
  local a = world:getAgent("guard_01")
  if a then a:addTag("alive") end
end

--@api-stub: LAIWorld:removeAgent
-- Removes a agent from this ai world.
do
  local world = lurek.ai.newWorld()
  local tmp = world:addAgent("temp")
  world:removeAgent(tmp)
end

--@api-stub: LAIWorld:getAgentCount
-- Returns the number of agent items in this ai world.
do
  local world = lurek.ai.newWorld()
  world:addAgent("a"); world:addAgent("b")
  lurek.log.info("agents=" .. world:getAgentCount(), "ai")
end

--@api-stub: LAIWorld:getGlobalBlackboard
-- Returns the global blackboard of this ai world.
do
  -- The global blackboard is shared state visible to ALL agents in the world.
  -- Use it for world-level facts: alarm status, time of day, player position.
  -- Scenario: one guard spots the player → sets "alarm" on global BB → all guards react.
  local world = lurek.ai.newWorld()
  local bb = world:getGlobalBlackboard()
  bb:setNumber("alarm", 0.0)
end

--@api-stub: LStrategyAI:update
-- Advances this ai world by the given delta time.
do
  local world = lurek.ai.newWorld()
  world:addAgent("npc")
  function lurek.process(dt) world:update(dt) end
end

--@api-stub: LAILod:type
-- Returns the Lua-visible type name string for this ai world handle.
do
  local world = lurek.ai.newWorld()
  if world:type() == "AIWorld" then lurek.log.debug("got world", "ai") end
end

--@api-stub: LAILod:typeOf
-- Returns true if this ai world handle matches the given type name string.
do
  local world = lurek.ai.newWorld()
  if world:typeOf("Object") then lurek.log.debug("inherits Object", "ai") end
end

--@api-stub: LSquad:getName
-- Returns the name of this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  local name = agent:getName()
  lurek.log.debug("agent=" .. name, "ai")
end

--@api-stub: LORCASolver:setPosition
-- Sets the position of this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setPosition(320, 240)
end

--@api-stub: LAgent:getPosition
-- Returns the position of this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setPosition(50, 75)
  local x, y = agent:getPosition()
  lurek.log.debug("pos=" .. x .. "," .. y, "ai")
end

--@api-stub: LAgent:setVelocity
-- Sets the velocity of this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setVelocity(40, 0)
end

--@api-stub: LAgent:getVelocity
-- Returns the velocity of this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setVelocity(40, 30)
  local vx, vy = agent:getVelocity()
  if vx*vx + vy*vy > 100 then lurek.log.debug("moving", "ai") end
end

--@api-stub: LAgent:setMaxSpeed
-- Sets the max speed of this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setMaxSpeed(150)
end

--@api-stub: LAgent:getMaxSpeed
-- Returns the max speed of this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  local cap = agent:getMaxSpeed()
  agent:setVelocity(cap, 0)
end

--@api-stub: LAgent:setMaxForce
-- Sets the max force of this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setMaxForce(300)
end

--@api-stub: LAgent:getMaxForce
-- Returns the max force of this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  local f = agent:getMaxForce()
  lurek.log.debug("max force=" .. f, "ai")
end

--@api-stub: LAgent:setPriority
-- Sets the priority of this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setPriority(10)
end

--@api-stub: LAgent:getPriority
-- Returns the priority of this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setPriority(5)
  if agent:getPriority() > 0 then lurek.log.debug("prio agent", "ai") end
end

--@api-stub: LAgent:setDecisionModel
-- Sets the decision model of this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setDecisionModel("bt")
end

--@api-stub: LAgent:getDecisionModel
-- Returns the decision model of this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  if agent:getDecisionModel() == "fsm" then lurek.log.debug("uses fsm", "ai") end
end

--@api-stub: LStrategyAI:addTag
-- Adds a tag to this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:addTag("alive")
  agent:addTag("scout")
end

--@api-stub: LStrategyAI:removeTag
-- Removes a tag from this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:addTag("burning")
  agent:removeTag("burning")
end

--@api-stub: LAgent:hasTag
-- Returns true if this agent has a tag.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:addTag("boss")
  if agent:hasTag("boss") then lurek.log.info("boss alert", "ai") end
end

--@api-stub: LSquad:getBlackboard
-- Returns the blackboard of this agent.
do
  -- Per-agent blackboard stores private state only this agent reads/writes.
  -- Use for HP, target_id, last_known_position — data other agents shouldn't see.
  -- Scenario: guard tracks "last_heard_sound_pos" independently from other guards.
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  local bb = agent:getBlackboard()
  bb:setNumber("hp", 100)
end

--@api-stub: LAILod:type
-- Returns the Lua-visible type name string for this agent handle.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  if agent:type() == "Agent" then lurek.log.debug("ok", "ai") end
end

--@api-stub: LAILod:typeOf
-- Returns true if this agent handle matches the given type name string.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  if agent:typeOf("Object") then lurek.log.debug("inherits Object", "ai") end
end

--@api-stub: LAIBlackboard:setNumber
-- Sets the number of this blackboard.
do
  -- Blackboards are typed key-value stores shared between AI subsystems.
  -- Use setNumber for numeric state: HP, distances, cooldown timers, threat scores.
  -- Scenario: guard stores alert_level (0-1); FSM transitions to "investigate" at 0.5.
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("hp", 100)
  bb:setNumber("alert_level", 0.6)
end

--@api-stub: LAIBlackboard:setBool
-- Sets the bool of this blackboard.
do
  local bb = lurek.ai.newBlackboard()
  bb:setBool("player_seen", true)
  bb:setBool("door_open", false)
end

--@api-stub: LAIBlackboard:setString
-- Sets the string of this blackboard.
do
  local bb = lurek.ai.newBlackboard()
  bb:setString("target_id", "player_01")
  bb:setString("last_state", "patrol")
end

--@api-stub: LTraitProfile:has
-- Returns true if this blackboard has a .
do
  local bb = lurek.ai.newBlackboard()
  bb:setBool("alive", true)
  if bb:has("alive") then lurek.log.debug("entry exists", "ai") end
end

--@api-stub: LStimulusWorld:remove
-- Removes a  from this blackboard.
do
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("temp", 1)
  bb:remove("temp")
end

--@api-stub: LStimulusWorld:clear
-- Clears all items from this blackboard.
do
  -- Wipes all entries — use when an agent respawns or changes role entirely.
  -- Scenario: enemy dies and respawns → clear blackboard so stale target data is gone.
  local bb = lurek.ai.newBlackboard()
  bb:setBool("dirty", true)
  bb:clear()
end

--@api-stub: LAIBlackboard:getKeys
-- Returns the keys of this blackboard.
do
  -- Returns all stored key names as an array — useful for serialization or debug display.
  -- Scenario: save system iterates keys to persist agent memory between levels.
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("hp", 100); bb:setBool("alive", true)
  for _, k in ipairs(bb:getKeys()) do lurek.log.debug("key=" .. k, "ai") end
end

--@api-stub: LAIBlackboard:getSize
-- Returns the size of this blackboard.
do
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("hp", 100)
  lurek.log.debug("entries=" .. bb:getSize(), "ai")
end

--@api-stub: LAILod:type
-- Returns the Lua-visible type name string for this blackboard handle.
do
  local bb = lurek.ai.newBlackboard()
  if bb:type() == "Blackboard" then lurek.log.debug("got bb", "ai") end
end

--@api-stub: LAILod:typeOf
-- Returns true if this blackboard handle matches the given type name string.
do
  local bb = lurek.ai.newBlackboard()
  if bb:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: LStateMachine:addState
-- Adds a state to this state machine.
do
  -- Each state can have onEnter, onUpdate, onExit callbacks.
  -- Use onEnter to reset timers/animations; onUpdate for per-frame logic (e.g. path follow).
  -- Scenario: an enemy patrols waypoints, then switches to chase when it sees the player.
  local fsm = lurek.ai.newStateMachine()
  fsm:addState("patrol", { onEnter = function() lurek.log.info("patrol", "ai") end })
  fsm:addState("chase", { onUpdate = function(dt) end })
end

--@api-stub: LStateMachine:setInitialState
-- Sets the initial state of this state machine.
do
  local fsm = lurek.ai.newStateMachine()
  fsm:addState("idle", {})
  fsm:setInitialState("idle")
end

--@api-stub: LStateMachine:getCurrentState
-- Returns the current state of this state machine.
do
  -- Query the active state to drive animations, sound, or UI indicators.
  -- Scenario: HUD shows "ALERT" icon when guard is in "chase" state.
  local fsm = lurek.ai.newStateMachine()
  fsm:addState("patrol", {}); fsm:setInitialState("patrol")
  local s = fsm:getCurrentState()
  if s then lurek.log.debug("state=" .. s, "ai") end
end

--@api-stub: LStateMachine:forceState
-- Performs the force state operation on this state machine.
do
  -- Bypasses transitions — use for interrupts like stun, death, or cutscene override.
  -- Calls onExit of old state and onEnter of new state immediately.
  -- Scenario: player lands a critical hit → force enemy into "stunned" regardless of current state.
  local fsm = lurek.ai.newStateMachine()
  fsm:addState("stunned", {}); fsm:setInitialState("stunned")
  fsm:forceState("stunned")
end

--@api-stub: LStateMachine:getTimeInState
-- Returns the time in state of this state machine.
do
  -- Elapsed seconds since entering the current state (resets on transition).
  -- Useful for timeout transitions: "if idle for 5s, switch to wander".
  -- Scenario: shopkeeper returns to counter after standing idle too long.
  local fsm = lurek.ai.newStateMachine()
  fsm:addState("idle", {}); fsm:setInitialState("idle")
  if fsm:getTimeInState() > 5.0 then fsm:forceState("idle") end
end

--@api-stub: LAILod:type
-- Returns the Lua-visible type name string for this state machine handle.
do
  local fsm = lurek.ai.newStateMachine()
  if fsm:type() == "StateMachine" then lurek.log.debug("ok", "ai") end
end

--@api-stub: LAILod:typeOf
-- Returns true if this state machine handle matches the given type name string.
do
  local fsm = lurek.ai.newStateMachine()
  if fsm:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: LBehaviorTree:setRoot
-- Sets the root of this behavior tree.
do
  -- The root node is the entry point ticked every frame. Typically a Selector or Sequence.
  -- Build the tree bottom-up: create leaf nodes first, compose into branches, then setRoot.
  -- Scenario: root Selector tries "attack" branch first, falls back to "patrol" branch.
  local bt = lurek.ai.newBehaviorTree()
  local root = lurek.ai.newSelector()
  root:addChild(lurek.ai.newAction(function() return "success" end))
  bt:setRoot(root)
end

--@api-stub: LBehaviorTree:getLastStatus
-- Returns the last status of this behavior tree.
do
  -- Returns "success", "failure", or "running" from the last tick.
  -- Use to detect when a behavior completes and trigger follow-up logic.
  -- Scenario: if last tick returned "failure", play a confused animation.
  local bt = lurek.ai.newBehaviorTree()
  local root = lurek.ai.newSequence()
  root:addChild(lurek.ai.newAction(function() return "success" end))
  bt:setRoot(root)
  local s = bt:getLastStatus()
  lurek.log.debug("bt status=" .. s, "ai")
end

--@api-stub: LBehaviorTree:getDebugState
-- Returns the debug state of this behavior tree.
do
  -- Returns a table with node_count, last_status, and active path for dev tools.
  -- Useful for drawing a BT visualizer overlay or logging which branch is active.
  -- Scenario: debug HUD shows "attack→aim→fire" path highlighted in green.
  local bt = lurek.ai.newBehaviorTree()
  local root = lurek.ai.newSequence()
  root:addChild(lurek.ai.newAction(function() return "success" end))
  bt:setRoot(root)
  local dbg = bt:getDebugState()
  lurek.log.debug("nodes=" .. dbg.node_count .. " status=" .. dbg.last_status, "ai")
end

--@api-stub: LAILod:type
-- Returns the Lua-visible type name string for this behavior tree handle.
do
  local bt = lurek.ai.newBehaviorTree()
  if bt:type() == "BehaviorTree" then lurek.log.debug("ok", "ai") end
end

--@api-stub: LAILod:typeOf
-- Returns true if this behavior tree handle matches the given type name string.
do
  local bt = lurek.ai.newBehaviorTree()
  if bt:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: LBTNode:addChild
-- Adds a child to this bt node.
do
  -- Sequence runs children left-to-right; stops on first failure (AND logic).
  -- Selector tries children left-to-right; stops on first success (OR logic).
  -- Scenario: Sequence["has_ammo?", "aim", "fire"] — skips aim+fire if no ammo.
  local seq = lurek.ai.newSequence()
  seq:addChild(lurek.ai.newCondition(function() return true end))
  seq:addChild(lurek.ai.newAction(function() return "success" end))
end

--@api-stub: LBTNode:getChildCount
-- Returns the number of child items in this bt node.
do
  local seq = lurek.ai.newSequence()
  seq:addChild(lurek.ai.newAction(function() return "success" end))
  lurek.log.debug("children=" .. seq:getChildCount(), "ai")
end

--@api-stub: LBandit:reset
-- Resets this bt node to its default state.
do
  -- Clears running state and iteration counters for this node and its subtree.
  -- Call when re-entering a branch after an interrupt or state machine transition.
  -- Scenario: player breaks line-of-sight → reset the chase subtree so it re-evaluates cleanly.
  local rep = lurek.ai.newRepeater(3)
  rep:setChild(lurek.ai.newAction(function() return "success" end))
  rep:reset()
end

--@api-stub: LBTNode:setChild
-- Sets the child of this bt node.
do
  local inv = lurek.ai.newInverter()
  inv:setChild(lurek.ai.newCondition(function() return false end))
  local bt = lurek.ai.newBehaviorTree(); bt:setRoot(inv)
end

--@api-stub: LBTNode:setCount
-- Sets the count of this bt node.
do
  local rep = lurek.ai.newRepeater(0)
  rep:setCount(5)
  rep:setChild(lurek.ai.newAction(function() return "success" end))
end

--@api-stub: LCommandQueue:getCount
-- Returns the total count of items held by this bt node.
do
  local rep = lurek.ai.newRepeater(7)
  if rep:getCount() == 7 then lurek.log.debug("count ok", "ai") end
end

--@api-stub: LBTNode:setSuccessPolicy
-- Sets the success policy of this bt node.
do
  local par = lurek.ai.newParallel("require_one", "require_one")
  par:setSuccessPolicy("require_all")
  par:addChild(lurek.ai.newAction(function() return "success" end))
end

--@api-stub: LBTNode:setFailurePolicy
-- Sets the failure policy of this bt node.
do
  local par = lurek.ai.newParallel("require_one", "require_one")
  par:setFailurePolicy("require_all")
  par:addChild(lurek.ai.newAction(function() return "running" end))
end

--@api-stub: LBTNode:getNodeType
-- Returns the node type of this bt node.
do
  local seq = lurek.ai.newSequence()
  if seq:getNodeType() == "sequence" then lurek.log.debug("seq ok", "ai") end
end

--@api-stub: LAILod:type
-- Returns the Lua-visible type name string for this bt node handle.
do
  local seq = lurek.ai.newSequence()
  if seq:type() == "BTNode" then lurek.log.debug("ok", "ai") end
end

--@api-stub: LAILod:typeOf
-- Returns true if this bt node handle matches the given type name string.
do
  local sel = lurek.ai.newSelector()
  if sel:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: LSteeringManager:getBehaviorCount
-- Returns the number of behavior items in this steering manager.
do
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  sm:addWander(20, 40, 5, 0.3)
  lurek.log.debug("behaviours=" .. sm:getBehaviorCount(), "ai")
end

--@api-stub: LSteeringManager:setCombineMode
-- Sets the combine mode of this steering manager.
do
  -- "weighted_sum" blends all forces; "priority" uses highest-weight behavior only.
  -- Priority avoids jittery blending when behaviors conflict (e.g. seek vs flee).
  -- Scenario: fleeing from danger overrides seek-to-waypoint via priority mode.
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  sm:setCombineMode("priority")
end

--@api-stub: LSteeringManager:getCombineMode
-- Returns the combine mode of this steering manager.
do
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  if sm:getCombineMode() == "weighted_sum" then lurek.log.debug("blend mode", "ai") end
end

--@api-stub: LSteeringManager:getLastSteering
-- Returns the last steering of this steering manager.
do
  -- Returns the (fx, fy) force vector computed on the last calculate() call.
  -- Apply this as velocity or acceleration to your entity's position each frame.
  -- Scenario: multiply by dt and add to NPC position for smooth movement toward a target.
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  local fx, fy = sm:getLastSteering()
  if fx ~= 0 or fy ~= 0 then lurek.log.debug("steering active", "ai") end
end

--@api-stub: LAILod:type
-- Returns the Lua-visible type name string for this steering manager handle.
do
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  if sm:type() == "SteeringManager" then lurek.log.debug("ok", "ai") end
end

--@api-stub: LAILod:typeOf
-- Returns true if this steering manager handle matches the given type name string.
do
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  if sm:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: LSteeringManager:setSpatialHashCellSize
-- Sets the spatial hash cell size of this steering manager.
do
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  sm:enableSpatialHash(true)
  sm:setSpatialHashCellSize(64)
end

--@api-stub: LSteeringManager:enableSpatialHash
-- Performs the enable spatial hash operation on this steering manager.
do
  -- Spatial hashing accelerates neighbor queries for separation/cohesion behaviors.
  -- Enable when you have many agents (50+) to avoid O(n^2) distance checks.
  -- Scenario: 200 fish in a school — spatial hash keeps flocking at 60 FPS.
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  sm:enableSpatialHash(true)
end

--@api-stub: LQLearner:chooseAction
-- Performs the choose action operation on this q learner.
do
  -- Epsilon-greedy: picks the best-known action most of the time, random otherwise.
  -- The exploration rate controls how often it tries new actions vs exploiting known good ones.
  -- Scenario: grid-world NPC learns optimal patrol route by trial and error over episodes.
  local ql = lurek.ai.newQLearner(8, 4)
  local action = ql:chooseAction(1)
  lurek.log.debug("action=" .. action, "ai")
end

--@api-stub: LQLearner:bestAction
-- Performs the best action operation on this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  local action = ql:bestAction(1)
  if action >= 1 then lurek.log.debug("greedy=" .. action, "ai") end
end

--@api-stub: LQLearner:getQValue
-- Returns the q value of this q learner.
do
  -- Q(state, action) estimates the expected cumulative reward for taking action in state.
  -- Higher Q = better long-term outcome. Updated incrementally via the learn() call.
  -- Scenario: inspect Q-values to visualize which directions the NPC prefers in each cell.
  local ql = lurek.ai.newQLearner(8, 4)
  ql:learn(1, 2, 1.0, 3)
  local q = ql:getQValue(1, 2)
  lurek.log.debug("Q(1,2)=" .. q, "ai")
end

--@api-stub: LQLearner:endEpisode
-- Performs the end episode operation on this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  ql:learn(1, 1, 0.5, 2)
  ql:endEpisode()
end

--@api-stub: LQLearner:getEpisodeCount
-- Returns the number of episode items in this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  ql:endEpisode()
  lurek.log.debug("episodes=" .. ql:getEpisodeCount(), "ai")
end

--@api-stub: LQLearner:getStateCount
-- Returns the number of state items in this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  lurek.log.debug("states=" .. ql:getStateCount(), "ai")
end

--@api-stub: LGOAPPlanner:getActionCount
-- Returns the number of action items in this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  for a = 1, ql:getActionCount() do lurek.log.debug("a=" .. a, "ai") end
end

--@api-stub: LQLearner:setLearningRate
-- Sets the learning rate of this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  ql:setLearningRate(0.05)
end

--@api-stub: LQLearner:getLearningRate
-- Returns the learning rate of this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  lurek.log.debug("alpha=" .. ql:getLearningRate(), "ai")
end

--@api-stub: LQLearner:setDiscountFactor
-- Sets the discount factor of this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  ql:setDiscountFactor(0.95)
end

--@api-stub: LQLearner:getDiscountFactor
-- Returns the discount factor of this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  lurek.log.debug("gamma=" .. ql:getDiscountFactor(), "ai")
end

--@api-stub: LQLearner:setExplorationRate
-- Sets the exploration rate of this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  ql:setExplorationRate(0.1)
end

--@api-stub: LQLearner:getExplorationRate
-- Returns the exploration rate of this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  if ql:getExplorationRate() < 0.05 then lurek.log.info("exploit phase", "ai") end
end

--@api-stub: LQLearner:setExplorationDecay
-- Sets the exploration decay of this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  ql:setExplorationDecay(0.995)
end

--@api-stub: LQLearner:getExplorationDecay
-- Returns the exploration decay of this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  lurek.log.debug("decay=" .. ql:getExplorationDecay(), "ai")
end

--@api-stub: LQLearner:serialize
-- Performs the serialize operation on this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  ql:learn(1, 1, 1.0, 2)
  local json = ql:serialize()
  lurek.log.info("saved " .. #json .. " bytes", "ai")
end

--@api-stub: LQLearner:deserialize
-- Performs the deserialize operation on this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  local saved = ql:serialize()
  ql:deserialize(saved)
end

--@api-stub: LAILod:type
-- Returns the Lua-visible type name string for this q learner handle.
do
  local ql = lurek.ai.newQLearner(8, 4)
  if ql:type() == "QLearner" then lurek.log.debug("ok", "ai") end
end

--@api-stub: LAILod:typeOf
-- Returns true if this q learner handle matches the given type name string.
do
  local ql = lurek.ai.newQLearner(8, 4)
  if ql:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: LContextSteering:evaluate
-- Performs the evaluate operation on this utility ai.
do
  -- Scores all registered actions and picks the highest. Scores are 0.0-1.0 floats.
  -- Unlike FSM/BT, utility AI adapts smoothly — no explicit transitions to author.
  -- Scenario: NPC with low HP scores "flee" at 0.9, "attack" at 0.2 → flees automatically.
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("flee", function() return 0.8 end)
  uai:addAction("attack", function() return 0.4 end)
  local choice = uai:evaluate()
  if choice then lurek.log.info("chose " .. choice, "ai") end
end

--@api-stub: LGOAPPlanner:getActionCount
-- Returns the number of action items in this utility ai.
do
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("flee", function() return 0.8 end)
  uai:addAction("attack", function() return 0.4 end)
  lurek.log.debug("actions=" .. uai:getActionCount(), "ai")
end

--@api-stub: LUtilityAI:getLastAction
-- Returns the last action of this utility ai.
do
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("flee", function() return 0.8 end)
  uai:addAction("attack", function() return 0.4 end)
  uai:evaluate()
  local last = uai:getLastAction()
  if last then lurek.log.debug("last=" .. last, "ai") end
end

--@api-stub: LAILod:type
-- Returns the Lua-visible type name string for this utility ai handle.
do
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("flee", function() return 0.8 end)
  uai:addAction("attack", function() return 0.4 end)
  if uai:type() == "UtilityAI" then lurek.log.debug("ok", "ai") end
end

--@api-stub: LAILod:typeOf
-- Returns true if this utility ai handle matches the given type name string.
do
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("flee", function() return 0.8 end)
  uai:addAction("attack", function() return 0.4 end)
  if uai:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: LGOAPPlanner:getActionCount
-- Returns the number of action items in this goap planner.
do
  local p = lurek.ai.newGOAPPlanner()
  p:addAction("eat", 1.0, function() end)
  p:addGoal("not_hungry", 1.0)
  lurek.log.debug("actions=" .. p:getActionCount(), "ai")
end

--@api-stub: LGOAPPlanner:getGoalCount
-- Returns the number of goal items in this goap planner.
do
  local p = lurek.ai.newGOAPPlanner()
  p:addAction("eat", 1.0, function() end)
  p:addGoal("not_hungry", 1.0)
  if p:getGoalCount() == 0 then lurek.log.warn("no goals", "ai") end
end

--@api-stub: LGOAPPlanner:getMaxIterations
-- Returns the max iterations of this goap planner.
do
  local p = lurek.ai.newGOAPPlanner()
  p:addAction("eat", 1.0, function() end)
  p:addGoal("not_hungry", 1.0)
  lurek.log.debug("max iters=" .. p:getMaxIterations(), "ai")
end

--@api-stub: LGOAPPlanner:setMaxIterations
-- Sets the max iterations of this goap planner.
do
  local p = lurek.ai.newGOAPPlanner()
  p:addAction("eat", 1.0, function() end)
  p:addGoal("not_hungry", 1.0)
  p:setMaxIterations(500)
end

--@api-stub: LAILod:type
-- Returns the Lua-visible type name string for this goap planner handle.
do
  local p = lurek.ai.newGOAPPlanner()
  p:addAction("eat", 1.0, function() end)
  p:addGoal("not_hungry", 1.0)
  if p:type() == "GOAPPlanner" then lurek.log.debug("ok", "ai") end
end

--@api-stub: LAILod:typeOf
-- Returns true if this goap planner handle matches the given type name string.
do
  local p = lurek.ai.newGOAPPlanner()
  p:addAction("eat", 1.0, function() end)
  p:addGoal("not_hungry", 1.0)
  if p:typeOf("Object") then lurek.log.debug("ok", "ai") end
end
-- do  -- InfluenceMap:addLayer
--   local im = lurek.ai.newInfluenceMap(32, 32, 16)
--   im:addLayer("threat")
--   im:addLayer("loot")
-- end

--@api-stub: LInfluenceMap:hasLayer
-- Returns true if this influence map has a layer.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  if im:hasLayer("threat") then lurek.log.debug("layer ok", "ai") end
end

--@api-stub: LInfluenceMap:decay
-- Performs the decay operation on this influence map.
do
  -- Multiplies every cell by the decay factor each frame, fading old influence over time.
  -- Without decay, stamps accumulate forever and the map becomes useless.
  -- Scenario: gunshot stamps threat=1.0; after 2 seconds it fades to ~0.5, so guards lose interest.
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:stampInfluence("threat", 100, 100, 64, 1.0, 1.0)
  function lurek.process(dt) im:decay("threat", 0.97) end
end

--@api-stub: LInfluenceMap:clearLayer
-- Clears all layer items from this influence map.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:stampInfluence("threat", 100, 100, 64, 1.0, 1.0)
  im:clearLayer("threat")
end

--@api-stub: LInfluenceMap:clearAll
-- Clears all all items from this influence map.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:clearAll()
end

--@api-stub: LInfluenceMap:getMaxPosition
-- Returns the max position of this influence map.
do
  -- Returns the (x, y) world position of the cell with the highest influence value.
  -- Use to find the most dangerous/attractive spot on the map for decision-making.
  -- Scenario: AI commander sends reinforcements toward the highest-threat cell.
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:stampInfluence("threat", 200, 100, 32, 1.0, 1.0)
  local mx, my = im:getMaxPosition("threat")
  lurek.log.debug("hot=" .. mx .. "," .. my, "ai")
end

--@api-stub: LInfluenceMap:getMinPosition
-- Returns the min position of this influence map.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:stampInfluence("threat", 200, 100, 32, 1.0, 1.0)
  local sx, sy = im:getMinPosition("threat")
  lurek.log.debug("safe=" .. sx .. "," .. sy, "ai")
end

--@api-stub: LInfluenceMap:getWidth
-- Returns the width of this influence map.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  lurek.log.debug("w=" .. im:getWidth(), "ai")
end

--@api-stub: LInfluenceMap:getHeight
-- Returns the height of this influence map.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  lurek.log.debug("h=" .. im:getHeight(), "ai")
end

--@api-stub: LInfluenceMap:getCellSize
-- Returns the cell size of this influence map.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  lurek.log.debug("cell=" .. im:getCellSize(), "ai")
end

--@api-stub: LAILod:type
-- Returns the Lua-visible type name string for this influence map handle.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  if im:type() == "InfluenceMap" then lurek.log.debug("ok", "ai") end
end

--@api-stub: LAILod:typeOf
-- Returns true if this influence map handle matches the given type name string.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  if im:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: LSquad:getName
-- Returns the name of this squad.
do
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  lurek.log.debug("squad=" .. sq:getName(), "ai")
end

--@api-stub: LSquad:addMember
-- Adds a member to this squad.
do
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  sq:addMember("guard_02")
  sq:addMember("scout_03")
end

--@api-stub: LSquad:removeMember
-- Removes a member from this squad.
do
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  sq:addMember("doomed")
  sq:removeMember("doomed")
end

--@api-stub: LSquad:getMemberCount
-- Returns the number of member items in this squad.
do
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  if sq:getMemberCount() == 0 then lurek.log.warn("squad wiped", "ai") end
end

--@api-stub: LSquad:getMembers
-- Returns the members of this squad.
do
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  sq:addMember("guard_02")
  for _, m in ipairs(sq:getMembers()) do lurek.log.debug("m=" .. m, "ai") end
end

--@api-stub: LSquad:setLeader
-- Sets the leader of this squad.
do
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  sq:setLeader("guard_01")
end

--@api-stub: LSquad:getLeader
-- Returns the leader of this squad.
do
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  sq:setLeader("guard_01")
  local l = sq:getLeader()
  if l then lurek.log.debug("leader=" .. l, "ai") end
end

--@api-stub: LSquad:getFormation
-- Returns the formation of this squad.
do
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  sq:setFormation("wedge", 32)
  if sq:getFormation() == "wedge" then lurek.log.debug("v formation", "ai") end
end

--@api-stub: LSquad:getFormationSpacing
-- Returns the formation spacing of this squad.
do
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  sq:setFormation("line", 48)
  lurek.log.debug("spacing=" .. sq:getFormationSpacing(), "ai")
end

--@api-stub: LSquad:getBlackboard
-- Returns the blackboard of this squad.
do
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  local bb = sq:getBlackboard()
  bb:setString("objective", "capture_point_a")
end

--@api-stub: LAILod:type
-- Returns the Lua-visible type name string for this squad handle.
do
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  if sq:type() == "Squad" then lurek.log.debug("ok", "ai") end
end

--@api-stub: LAILod:typeOf
-- Returns true if this squad handle matches the given type name string.
do
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  if sq:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: LCommandQueue:cancelCurrent
-- Performs the cancel current operation on this command queue.
do
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  if cq:cancelCurrent() then lurek.log.debug("cancelled", "ai") end
end

--@api-stub: LStimulusWorld:clear
-- Clears all items from this command queue.
do
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  cq:enqueue("attack", function() end)
  cq:clear()
end

--@api-stub: LCommandQueue:getCount
-- Returns the total count of items held by this command queue.
do
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  lurek.log.debug("queue=" .. cq:getCount(), "ai")
end

--@api-stub: LCommandQueue:isEmpty
-- Returns true if this command queue contains no items.
do
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  cq:clear()
  if cq:isEmpty() then lurek.log.debug("idle", "ai") end
end

--@api-stub: LCommandQueue:getCurrentType
-- Returns the current type of this command queue.
do
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  local kind = cq:getCurrentType()
  if kind then lurek.log.debug("doing " .. kind, "ai") end
end

--@api-stub: LCommandQueue:getCurrentTarget
-- Returns the current target of this command queue.
do
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  local tx, ty = cq:getCurrentTarget()
  lurek.log.debug("target=" .. tx .. "," .. ty, "ai")
end

--@api-stub: LAILod:type
-- Returns the Lua-visible type name string for this command queue handle.
do
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  if cq:type() == "CommandQueue" then lurek.log.debug("ok", "ai") end
end

--@api-stub: LAILod:typeOf
-- Returns true if this command queue handle matches the given type name string.
do
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  if cq:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: LTraitProfile:set
-- Sets the  of this trait profile.
do
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  tp:set("courage", 0.5)
end

--@api-stub: LEmotionModel:get
-- Returns the  of this trait profile.
do
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  local v = tp:get("aggression")
  if v > 0.6 then lurek.log.debug("aggressive", "ai") end
end

--@api-stub: LTraitProfile:getBase
-- Returns the base of this trait profile.
do
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  local base = tp:getBase("aggression")
  lurek.log.debug("base=" .. base, "ai")
end

--@api-stub: LTraitProfile:removeModifiers
-- Removes a modifiers from this trait profile.
do
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  tp:addModifier("aggression", 0.2, 10.0, "rage_potion")
  tp:removeModifiers("rage_potion")
end

--@api-stub: LStrategyAI:update
-- Advances this trait profile by the given delta time.
do
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  tp:addModifier("aggression", 0.2, 5.0, "buff")
  function lurek.process(dt) tp:update(dt) end
end

--@api-stub: LTraitProfile:has
-- Returns true if this trait profile has a .
do
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  if tp:has("aggression") then lurek.log.debug("trait set", "ai") end
end

--@api-stub: LTraitProfile:traitCount
-- Performs the trait count operation on this trait profile.
do
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  lurek.log.debug("traits=" .. tp:traitCount(), "ai")
end

--@api-stub: LTraitProfile:archetype
-- Performs the archetype operation on this trait profile.
do
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  local arch = tp:archetype()
  if arch then lurek.log.info("archetype=" .. arch, "ai") end
end

--@api-stub: LStimulusWorld:remove
-- Removes a  from this stimulus world.
do
  local sw = lurek.ai.newStimulusWorld()
  local id = sw:addAuditory(100, 200, 1.0, 150, 0.5, "footstep")
  if sw:remove(id) then lurek.log.debug("removed " .. id, "ai") end
end

--@api-stub: LStrategyAI:update
-- Advances this stimulus world by the given delta time.
do
  local sw = lurek.ai.newStimulusWorld()
  local id = sw:addAuditory(100, 200, 1.0, 150, 0.5, "footstep")
  function lurek.process(dt) sw:update(dt) end
end

--@api-stub: LStimulusWorld:clear
-- Clears all items from this stimulus world.
do
  local sw = lurek.ai.newStimulusWorld()
  local id = sw:addAuditory(100, 200, 1.0, 150, 0.5, "footstep")
  sw:clear()
end

--@api-stub: LContextSteering:addWander
-- Adds a wander to this context steering.
do
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  cs:addWander(0.5, 0.3)
end

--@api-stub: LContextSteering:addAvoidBounds
-- Adds a avoid bounds to this context steering.
do
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  cs:addAvoidBounds(0, 0, 1280, 720, 32, 1.0)
end

--@api-stub: LContextSteering:clearBehaviors
-- Clears all behaviors items from this context steering.
do
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  cs:clearBehaviors()
end

--@api-stub: LContextSteering:chosenMagnitude
-- Performs the chosen magnitude operation on this context steering.
do
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  cs:evaluate(0, 0, 0, 0)
  lurek.log.debug("mag=" .. cs:chosenMagnitude(), "ai")
end

--@api-stub: LContextSteering:slotCount
-- Performs the slot count operation on this context steering.
do
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  lurek.log.debug("slots=" .. cs:slotCount(), "ai")
end

--@api-stub: LNeedSystem:addNeed
-- Adds a need to this need system.
do
  local ns = lurek.ai.newNeedSystem()
  ns:addNeed("hunger", 0.05, 0.6, 1.5)
  ns:addNeed("thirst", 0.08, 0.5, 2.0)
end

--@api-stub: LStrategyAI:update
-- Advances this need system by the given delta time.
do
  local ns = lurek.ai.newNeedSystem()
  ns:addNeed("hunger", 0.05, 0.6, 1.5)
  function lurek.process(dt) ns:update(dt) end
end

--@api-stub: LNeedSystem:mostUrgent
-- Performs the most urgent operation on this need system.
do
  local ns = lurek.ai.newNeedSystem()
  ns:addNeed("hunger", 0.05, 0.6, 1.5)
  local n = ns:mostUrgent()
  if n then lurek.log.debug("urgent: " .. n, "ai") end
end

--@api-stub: LNeedSystem:satisfy
-- Performs the satisfy operation on this need system.
do
  local ns = lurek.ai.newNeedSystem()
  ns:addNeed("hunger", 0.05, 0.6, 1.5)
  ns:satisfy("hunger", 0.4)
end

--@api-stub: LNeedSystem:valueOf
-- Performs the value of operation on this need system.
do
  local ns = lurek.ai.newNeedSystem()
  ns:addNeed("hunger", 0.05, 0.6, 1.5)
  if ns:valueOf("hunger") > 0.8 then lurek.log.warn("starving", "ai") end
end

--@api-stub: LAIDirector:pushEvent
-- Performs the push event operation on this ai director.
do
  local dir = lurek.ai.newAIDirector()
  dir:pushEvent(0.7)
end

--@api-stub: LStrategyAI:update
-- Advances this ai director by the given delta time.
do
  local dir = lurek.ai.newAIDirector()
  function lurek.process(dt) dir:update(dt) end
end

--@api-stub: LAIDirector:tension
-- Performs the tension operation on this ai director.
do
  local dir = lurek.ai.newAIDirector()
  dir:pushEvent(0.5)
  lurek.log.debug("tension=" .. dir:tension(), "ai")
end

--@api-stub: LAIDirector:phase
-- Performs the phase operation on this ai director.
do
  local dir = lurek.ai.newAIDirector()
  if dir:phase() == "peak" then lurek.log.info("intense moment", "ai") end
end

--@api-stub: LAIDirector:spawnRateFactor
-- Performs the spawn rate factor operation on this ai director.
do
  local dir = lurek.ai.newAIDirector()
  local mult = dir:spawnRateFactor()
  lurek.log.debug("spawn x" .. mult, "ai")
end

--@api-stub: LAIDirector:lootFactor
-- Performs the loot factor operation on this ai director.
do
  local dir = lurek.ai.newAIDirector()
  lurek.log.debug("loot x" .. dir:lootFactor(), "ai")
end

--@api-stub: LAIDirector:ambientIntensity
-- Performs the ambient intensity operation on this ai director.
do
  local dir = lurek.ai.newAIDirector()
  local amb = dir:ambientIntensity()
  if amb > 0.5 then lurek.log.debug("loud ambience", "ai") end
end

--@api-stub: LAIDirector:setTension
-- Sets the tension of this ai director.
do
  local dir = lurek.ai.newAIDirector()
  dir:setTension(0.9)
end

--@api-stub: LBandit:reset
-- Resets this ai director to its default state.
do
  local dir = lurek.ai.newAIDirector()
  dir:reset()
end

--@api-stub: LHTNDomain:addPrimitive
-- Adds a primitive to this htn domain.
do
  local d = lurek.ai.newHTNDomain()
  d:addPrimitive("attack", { "has_weapon", "in_range" }, { "enemy_dead" }, { "in_range" })
end

--@api-stub: LHTNDomain:taskCount
-- Performs the task count operation on this htn domain.
do
  local d = lurek.ai.newHTNDomain()
  d:addPrimitive("rest", {}, { "rested" }, {})
  lurek.log.debug("tasks=" .. d:taskCount(), "ai")
end

--@api-stub: LEmotionModel:trigger
-- Performs the trigger operation on this emotion model.
do
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.1, 0.2)
  em:trigger("fear", 0.5)
end

--@api-stub: LEmotionModel:get
-- Returns the  of this emotion model.
do
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.1, 0.2)
  em:trigger("fear", 0.4)
  if em:get("fear") > 0.3 then lurek.log.debug("scared", "ai") end
end

--@api-stub: LEmotionModel:dominant
-- Performs the dominant operation on this emotion model.
do
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.1, 0.2)
  em:trigger("fear", 0.6)
  local d = em:dominant()
  if d then lurek.log.info("feeling " .. d, "ai") end
end

--@api-stub: LEmotionModel:isActive
-- Returns true if this emotion model is currently active.
do
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.1, 0.2)
  em:trigger("fear", 0.5)
  if em:isActive("fear") then lurek.log.debug("show fear face", "ai") end
end

--@api-stub: LStrategyAI:update
-- Advances this emotion model by the given delta time.
do
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.1, 0.2)
  function lurek.process(dt) em:update(dt) end
end

--@api-stub: LBandit:reset
-- Resets this emotion model to its default state.
do
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.1, 0.2)
  em:reset()
end

--@api-stub: LORCASolver:setPosition
-- Sets the position of this orca solver.
do
  local orca = lurek.ai.newORCASolver(2.0)
  local idx = orca:addAgent(100, 100, 16, 80)
  orca:setPosition(idx, 120, 100)
end

--@api-stub: LORCASolver:compute
-- Performs the compute operation on this orca solver.
do
  local orca = lurek.ai.newORCASolver(2.0)
  local idx = orca:addAgent(100, 100, 16, 80)
  function lurek.process(dt) orca:compute(dt) end
end

--@api-stub: LORCASolver:getSafeVelocity
-- Returns the safe velocity of this orca solver.
do
  local orca = lurek.ai.newORCASolver(2.0)
  local idx = orca:addAgent(100, 100, 16, 80)
  orca:compute(0.016)
  local vx, vy = orca:getSafeVelocity(idx)
  lurek.log.debug("safe v=" .. vx .. "," .. vy, "ai")
end

--@api-stub: LORCASolver:agentCount
-- Performs the agent count operation on this orca solver.
do
  local orca = lurek.ai.newORCASolver(2.0)
  local idx = orca:addAgent(100, 100, 16, 80)
  lurek.log.debug("agents=" .. orca:agentCount(), "ai")
end

--@api-stub: LNeuralNet:forward
-- Performs the forward operation on this neural net.
do
  local nn = lurek.ai.newNeuralNet()
  nn:addLayer(4, 8, "relu")
  nn:addLayer(8, 2, "softmax")
  local out = nn:forward({ 0.1, 0.2, 0.3, 0.4 })
  lurek.log.debug("y=" .. out[1] .. "," .. out[2], "ai")
end

--@api-stub: LNeuralNet:setWeights
-- Sets the weights of this neural net.
do
  local nn = lurek.ai.newNeuralNet()
  nn:addLayer(4, 8, "relu")
  nn:addLayer(8, 2, "softmax")
  local count = nn:paramCount()
  local zeros = {}; for i = 1, count do zeros[i] = 0.01 end
  nn:setWeights(zeros)
end

--@api-stub: LNeuralNet:getWeights
-- Returns the weights of this neural net.
do
  local nn = lurek.ai.newNeuralNet()
  nn:addLayer(4, 8, "relu")
  nn:addLayer(8, 2, "softmax")
  local w = nn:getWeights()
  lurek.log.debug("weights=" .. #w, "ai")
end

--@api-stub: LNeuralNet:paramCount
-- Performs the param count operation on this neural net.
do
  local nn = lurek.ai.newNeuralNet()
  nn:addLayer(4, 8, "relu")
  nn:addLayer(8, 2, "softmax")
  lurek.log.debug("params=" .. nn:paramCount(), "ai")
end

--@api-stub: LNeuralNet:layerCount
-- Performs the layer count operation on this neural net.
do
  local nn = lurek.ai.newNeuralNet()
  nn:addLayer(4, 8, "relu")
  nn:addLayer(8, 2, "softmax")
  lurek.log.debug("layers=" .. nn:layerCount(), "ai")
end

--@api-stub: LNeuroevolution:evolve
-- Performs the evolve operation on this genetic algorithm.
do
  local ga = lurek.ai.newGeneticAlgorithm(20, 8, 42)
  for i = 1, ga:popSize() do ga:setFitness(i - 1, 0.5) end
  ga:evolve()
end

--@api-stub: LNeuroevolution:generation
-- Performs the generation operation on this genetic algorithm.
do
  local ga = lurek.ai.newGeneticAlgorithm(20, 8, 42)
  if ga:generation() >= 100 then lurek.log.info("done", "ai") end
end

--@api-stub: LNeuroevolution:popSize
-- Performs the pop size operation on this genetic algorithm.
do
  local ga = lurek.ai.newGeneticAlgorithm(20, 8, 42)
  lurek.log.debug("pop=" .. ga:popSize(), "ai")
end

--@api-stub: LNeuroevolution:setFitness
-- Sets the fitness of this genetic algorithm.
do
  local ga = lurek.ai.newGeneticAlgorithm(20, 8, 42)
  for i = 0, ga:popSize() - 1 do ga:setFitness(i, math.random()) end
end

--@api-stub: LGeneticAlgorithm:getGenes
-- Returns the genes of this genetic algorithm.
do
  local ga = lurek.ai.newGeneticAlgorithm(20, 8, 42)
  local genes = ga:getGenes(0)
  lurek.log.debug("g0=" .. genes[1], "ai")
end

--@api-stub: LGeneticAlgorithm:bestGenes
-- Performs the best genes operation on this genetic algorithm.
do
  local ga = lurek.ai.newGeneticAlgorithm(20, 8, 42)
  ga:setFitness(0, 1.0)
  local best = ga:bestGenes()
  lurek.log.debug("best[1]=" .. best[1], "ai")
end

--@api-stub: LBandit:select
-- Performs the select operation on this bandit.
do
  local b = lurek.ai.newBandit(4, "ucb1", 0.1, 99)
  local arm = b:select()
  lurek.log.debug("arm=" .. arm, "ai")
end

--@api-stub: LStrategyAI:update
-- Advances this bandit by the given delta time.
do
  local b = lurek.ai.newBandit(4, "ucb1", 0.1, 99)
  local arm = b:select()
  b:update(arm, 1.0)
end

--@api-stub: LBandit:bestArm
-- Performs the best arm operation on this bandit.
do
  local b = lurek.ai.newBandit(4, "ucb1", 0.1, 99)
  b:update(0, 0.7); b:update(1, 0.3)
  lurek.log.debug("best arm=" .. b:bestArm(), "ai")
end

--@api-stub: LBandit:reset
-- Resets this bandit to its default state.
do
  local b = lurek.ai.newBandit(4, "ucb1", 0.1, 99)
  b:reset()
end

--@api-stub: LBandit:armCount
-- Performs the arm count operation on this bandit.
do
  local b = lurek.ai.newBandit(4, "ucb1", 0.1, 99)
  lurek.log.debug("arms=" .. b:armCount(), "ai")
end

--@api-stub: LBandit:totalPulls
-- Performs the total pulls operation on this bandit.
do
  local b = lurek.ai.newBandit(4, "ucb1", 0.1, 99)
  b:select(); b:select()
  lurek.log.debug("pulls=" .. b:totalPulls(), "ai")
end

--@api-stub: LNeuroevolution:evolve
-- Performs the evolve operation on this neuroevolution.
do
  local layers = { { inputs = 2, outputs = 4, activation = "relu" }, { inputs = 4, outputs = 1, activation = "tanh" } }
  local ne = lurek.ai.newNeuroevolution(layers, 10, 1)
  for i = 0, ne:popSize() - 1 do ne:setFitness(i, 0.5) end
  ne:evolve()
end

--@api-stub: LNeuroevolution:setFitness
-- Sets the fitness of this neuroevolution.
do
  local layers = { { inputs = 2, outputs = 4, activation = "relu" }, { inputs = 4, outputs = 1, activation = "tanh" } }
  local ne = lurek.ai.newNeuroevolution(layers, 10, 1)
  ne:setFitness(0, 0.85)
end

--@api-stub: LNeuroevolution:chromosomeToNet
-- Performs the chromosome to net operation on this neuroevolution.
do
  local layers = { { inputs = 2, outputs = 4, activation = "relu" }, { inputs = 4, outputs = 1, activation = "tanh" } }
  local ne = lurek.ai.newNeuroevolution(layers, 10, 1)
  local net = ne:chromosomeToNet(0)
  if net then lurek.log.debug("net layers=" .. net:layerCount(), "ai") end
end

--@api-stub: LNeuroevolution:bestNetwork
-- Performs the best network operation on this neuroevolution.
do
  local layers = { { inputs = 2, outputs = 4, activation = "relu" }, { inputs = 4, outputs = 1, activation = "tanh" } }
  local ne = lurek.ai.newNeuroevolution(layers, 10, 1)
  ne:setFitness(0, 1.0)
  local best = ne:bestNetwork()
  if best then lurek.log.debug("ok", "ai") end
end

--@api-stub: LNeuroevolution:bestFitness
-- Performs the best fitness operation on this neuroevolution.
do
  local layers = { { inputs = 2, outputs = 4, activation = "relu" }, { inputs = 4, outputs = 1, activation = "tanh" } }
  local ne = lurek.ai.newNeuroevolution(layers, 10, 1)
  ne:setFitness(0, 0.7)
  lurek.log.debug("best=" .. ne:bestFitness(), "ai")
end

--@api-stub: LNeuroevolution:popSize
-- Performs the pop size operation on this neuroevolution.
do
  local layers = { { inputs = 2, outputs = 4, activation = "relu" }, { inputs = 4, outputs = 1, activation = "tanh" } }
  local ne = lurek.ai.newNeuroevolution(layers, 10, 1)
  lurek.log.debug("pop=" .. ne:popSize(), "ai")
end

--@api-stub: LNeuroevolution:generation
-- Performs the generation operation on this neuroevolution.
do
  local layers = { { inputs = 2, outputs = 4, activation = "relu" }, { inputs = 4, outputs = 1, activation = "tanh" } }
  local ne = lurek.ai.newNeuroevolution(layers, 10, 1)
  if ne:generation() >= 50 then lurek.log.info("converged", "ai") end
end

--@api-stub: LStrategyAI:addGoal
-- Adds a goal to this strategy ai.
do
  local s = lurek.ai.newStrategyAI(2.0)
  s:addGoal("expand")
  s:addGoal("defend")
end

--@api-stub: LStrategyAI:addTag
-- Adds a tag to this strategy ai.
do
  local s = lurek.ai.newStrategyAI(2.0)
  s:addTag("early_game")
end

--@api-stub: LStrategyAI:removeTag
-- Removes a tag from this strategy ai.
do
  local s = lurek.ai.newStrategyAI(2.0)
  s:addTag("scout_phase")
  s:removeTag("scout_phase")
end

--@api-stub: LStrategyAI:update
-- Advances this strategy ai by the given delta time.
do
  local s = lurek.ai.newStrategyAI(2.0)
  s:addGoal("expand")
  function lurek.process(dt) s:update(dt, function(goal) return 0.5 end) end
end

--@api-stub: LStrategyAI:forceEvaluate
-- Performs the force evaluate operation on this strategy ai.
do
  local s = lurek.ai.newStrategyAI(2.0)
  s:addGoal("retreat")
  s:forceEvaluate(function(goal) return goal == "retreat" and 1.0 or 0.0 end)
end

--@api-stub: LStrategyAI:activeGoal
-- Performs the active goal operation on this strategy ai.
do
  local s = lurek.ai.newStrategyAI(2.0)
  s:addGoal("hold"); s:forceEvaluate(function(g) return 1.0 end)
  local g = s:activeGoal()
  if g then lurek.log.info("strategy=" .. g, "ai") end
end

--@api-stub: LStrategyAI:timeUntilNext
-- Performs the time until next operation on this strategy ai.
do
  local s = lurek.ai.newStrategyAI(2.0)
  lurek.log.debug("next eval in " .. s:timeUntilNext(), "ai")
end

--@api-stub: LAILod:shouldUpdate
-- Performs the should update operation on this ai lod.
do
  local lod = lurek.ai.newAILod()
  if lod:shouldUpdate(1, 60) then lurek.log.debug("tier 1 tick", "ai") end
end

--@api-stub: LAILod:tierCount
-- Performs the tier count operation on this ai lod.
do
  local lod = lurek.ai.newAILod()
  lurek.log.debug("tiers=" .. lod:tierCount(), "ai")
end

--@api-stub: LAILod:tierName
-- Performs the tier name operation on this ai lod.
do
  local lod = lurek.ai.newAILod()
  local n = lod:tierName(0)
  if n then lurek.log.debug("tier 0=" .. n, "ai") end
end


--@api-stub: LAgent:setCustomModel
-- Sets the custom model of this agent.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("custom_agent")
  agent:setCustomModel(function(ag, bb, dt)
    -- Read from blackboard and steer accordingly
    local dist = bb:getNumber("target_dist", 999)
    if dist < 50 then
      ag:setVelocity(0, 0)
    end
  end)
  world:update(0.016)
  lurek.log.debug("custom model: " .. agent:getDecisionModel(), "ai")
end

--@api-stub: lurek.ai.newGuard
-- Creates a guard decorator that runs a predicate before ticking its child
do
  local action = lurek.ai.newAction(function(ag, bb, dt) return "success" end)
  local guard = lurek.ai.newGuard(
    function(ag, bb) return bb:getNumber("health", 1.0) > 0.0 end,
    action
  )
  lurek.log.debug("guard type=" .. guard:getNodeType(), "ai")
  lurek.log.debug("guard children=" .. guard:getChildCount(), "ai")
end

--@api-stub: LUtilityAI:addConsideration
-- Adds a consideration to this utility ai.
do
  local ua = lurek.ai.newUtilityAI()
  ua:addAction("patrol", function() return 0.4 end, 1.0)
  ua:addConsideration(
    "patrol",
    "health_curve",
    function() return 0.8 end,
    "quadratic"
  )
  lurek.log.debug("considerations registered without error", "ai")
end

--@api-stub: LSteeringManager:addCustomBehavior
-- Adds a custom behavior to this steering manager.
do
  local sm = lurek.ai.newSteeringManager()
  sm:addCustomBehavior(function(ag, dt)
    return 100, 0   -- constant rightward force
  end, 1.0)
  lurek.log.debug("custom behaviors=" .. sm:getBehaviorCount(), "ai")
end

--@api-stub: LSteeringManager:applyCustomSteering
-- Applies custom steering to this steering manager.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("steered")
  local sm = lurek.ai.newSteeringManager()
  sm:addCustomBehavior(function(ag, dt)
    return 50, 25
  end, 1.0)
  -- applyCustomSteering passes the agent userdata to each callback
  local fx, fy = sm:applyCustomSteering(agent, 0.016)
  lurek.log.debug("custom force=" .. fx .. "," .. fy, "ai")
end

--@api-stub: LEmotionModel:add
-- Adds a  to this emotion model.
do
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.08, 1.0)
  em:add("anger", 0.0, 0.06, 1.0)
  lurek.log.info("emotions registered", "ai")
end

--@api-stub: LGOAPPlanner:addAction
-- Adds a action to this goap planner.
do
  local planner = lurek.ai.newGOAPPlanner()
  planner:addAction("pickupKey", 2.0, function() lurek.log.info("pickup key", "ai") end)
  planner:addAction("unlockDoor", 1.0, function() lurek.log.info("unlock door", "ai") end)
  planner:addGoal("door_open", 1.0)
end

--@api-stub: LGOAPPlanner:addAction
-- Adds a action to this utility ai.
do
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("heal", function() return 0.9 end)
  uai:addAction("attack", function() return 0.4 end)
  local best = uai:evaluate()
  lurek.log.info("best action: " .. (best or "none"), "ai")
end

--@api-stub: LORCASolver:addAgent
-- Adds a agent to this ai world.
do
  local world = lurek.ai.newWorld()
  world:addAgent("guard_01")
  world:addAgent("guard_02")
  lurek.log.info("agents: " .. world:getAgentCount(), "ai")
end

--@api-stub: LSteeringManager:addArrive
-- Adds a arrive to this steering manager.
do
  local sm = lurek.ai.newSteeringManager()
  sm:addArrive(400, 300, 1.0)
  local fx, fy = sm:calculate(200, 200, 0, 0, 100, 50, 1 / 60)
  lurek.log.info("arrive: " .. fx .. "," .. fy, "ai")
end

--@api-stub: LStimulusWorld:addAuditory
-- Adds a auditory to this stimulus world.
do
  local sw = lurek.ai.newStimulusWorld()
  sw:addAuditory(200, 150, 1.2, 100, 0.8, "footstep")
  lurek.log.info("stimuli: " .. sw:count(), "ai")
end

--@api-stub: LContextSteering:addAvoidPoint
-- Adds a avoid point to this context steering.
do
  local cs = lurek.ai.newContextSteering(16)
  cs:addAvoidPoint(300, 200, 64, 1.5)
  cs:addAvoidPoint(100, 350, 48, 1.0)
  local fx, fy = cs:evaluate(150, 150, 0, 0)
  lurek.log.info("context steer: " .. fx .. "," .. fy, "ai")
end

--@api-stub: LHTNDomain:addCompound
-- Adds a compound to this htn domain.
do
  local d = lurek.ai.newHTNDomain()
  d:addPrimitive("attack", {"has_weapon"}, {"enemy_dead"}, {})
  d:addCompound("defeat_enemy", {{"has_weapon"}, {"use_weapon"}})
  lurek.log.info("htn tasks: " .. d:taskCount(), "ai")
end

--@api-stub: LSteeringManager:addEvade
-- Adds a evade to this steering manager.
do
  local sm = lurek.ai.newSteeringManager()
  sm:addEvade("player", 1.0)
  local fx, fy = sm:calculate(200, 200, 0, 0, 100, 50, 1 / 60)
  lurek.log.info("evade: " .. fx .. "," .. fy, "ai")
end

--@api-stub: LSteeringManager:addFlee
-- Adds a flee to this steering manager.
do
  local sm = lurek.ai.newSteeringManager()
  sm:addFlee(400, 300, 1.0)
  local fx, fy = sm:calculate(200, 200, 0, 0, 100, 50, 1 / 60)
  lurek.log.info("flee: " .. fx .. "," .. fy, "ai")
end

--@api-stub: LSteeringManager:addFlock
-- Adds a flock to this steering manager.
do
  local sm = lurek.ai.newSteeringManager()
  sm:addFlock(80, 1.0, 0.8, 0.6)
  local fx, fy = sm:calculate(200, 200, 10, 0, 100, 50, 1 / 60)
  lurek.log.info("flock: " .. fx .. "," .. fy, "ai")
end

--@api-stub: LStrategyAI:addGoal
-- Adds a goal to this goap planner.
do
  local planner = lurek.ai.newGOAPPlanner()
  planner:addAction("rest", 1.0, function() end)
  planner:addGoal("is_rested", 1.0)
  planner:addGoal("is_safe", 2.0)
  lurek.log.info("goal count: " .. planner:getGoalCount(), "ai")
end

--@api-stub: LNeuralNet:addLayer
-- Adds a layer to this influence map.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:addLayer("resource")
  lurek.log.info("has threat layer: " .. tostring(im:hasLayer("threat")), "ai")
end

--@api-stub: LTraitProfile:addModifier
-- Adds a modifier to this trait profile.
do
  local traits = lurek.ai.newTraitProfile()
  traits:set("courage", 0.5)
  traits:addModifier("courage", -0.3, 5.0, "fear_potion")
  lurek.log.info("effective courage: " .. traits:get("courage"), "ai")
end

--@api-stub: LSteeringManager:addPursue
-- Adds a pursue to this steering manager.
do
  local sm = lurek.ai.newSteeringManager()
  sm:addPursue("player", 1.0)
  local fx, fy = sm:calculate(200, 200, 0, 0, 100, 50, 1 / 60)
  lurek.log.info("pursue: " .. fx .. "," .. fy, "ai")
end

--@api-stub: LSteeringManager:addSeek
-- Adds a seek to this steering manager.
do
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(500, 400, 1.0)
  local fx, fy = sm:calculate(100, 100, 0, 0, 150, 50, 1 / 60)
  lurek.log.info("seek force: " .. fx .. "," .. fy, "ai")
end

--@api-stub: LContextSteering:addSeekTarget
-- Adds a seek target to this context steering.
do
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  cs:addSeekTarget(400, 400, 0.6)
  local fx, fy = cs:evaluate(200, 200, 0, 0)
  lurek.log.info("context direction: " .. fx .. "," .. fy, "ai")
end

--@api-stub: LStateMachine:addTransition
-- Adds a transition to this state machine.
do
  local fsm = lurek.ai.newStateMachine()
  fsm:addState("patrol", {})
  fsm:addState("alert", {})
  fsm:addTransition("patrol", "alert", function() return true end)
  fsm:setInitialState("patrol")
  lurek.log.info("state: " .. (fsm:getCurrentState() or "nil"), "ai")
end

--@api-stub: LStimulusWorld:addVisual
-- Adds a visual to this stimulus world.
do
  local sw = lurek.ai.newStimulusWorld()
  sw:addVisual(300, 200, 1.0, 200, "player")
  sw:addAuditory(300, 200, 1.0, 80, 0.5, "footstep")
  lurek.log.info("stimuli count: " .. sw:count(), "ai")
end

--@api-stub: LContextSteering:addWander
-- Adds a wander to this steering manager.
do
  local sm = lurek.ai.newSteeringManager()
  sm:addWander(25, 50, 8, 0.4)
  local fx, fy = sm:calculate(200, 200, 0, 0, 100, 50, 1 / 60)
  lurek.log.info("wander: " .. fx .. "," .. fy, "ai")
end

--@api-stub: LInfluenceMap:blend
-- Performs the blend operation on this influence map.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:addLayer("resource")
  im:stampInfluence("threat", 256, 256, 64, 1.0, 1.0)
  im:blend("threat", 0.5, "resource", 0.5, "resource")
  lurek.log.info("blend complete", "ai")
end

--@api-stub: LSteeringManager:calculate
-- Performs the calculate operation on this steering manager.
do
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  local fx, fy = sm:calculate(100, 100, 0, 0, 120, 50, 1 / 60)
  lurek.log.info("steering force: " .. fx .. "," .. fy, "ai")
end

--@api-stub: LStimulusWorld:count
-- Returns the total count of items held by this stimulus world.
do
  local sw = lurek.ai.newStimulusWorld()
  sw:addAuditory(200, 100, 1.0, 80, 0.8, "gunshot")
  local n = sw:count()
  lurek.log.info("active stimuli: " .. n, "ai")
end

--@api-stub: LCommandQueue:enqueue
-- Performs the enqueue operation on this command queue.
do
  local q = lurek.ai.newCommandQueue()
  q:enqueue("move", function() end, {x=300, y=200})
  q:enqueue("attack", function() end, {targetId="enemy_01"})
  lurek.log.info("queue count: " .. q:getCount(), "ai")
end

--@api-stub: LContextSteering:evaluate
-- Performs the evaluate operation on this context steering.
do
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  cs:addAvoidPoint(350, 250, 50, 1.0)
  local fx, fy = cs:evaluate(200, 200, 0, 0)
  lurek.log.info("evaluated: " .. fx .. "," .. fy, "ai")
end

--@api-stub: LAIBlackboard:getBool
-- Returns the bool of this blackboard.
do
  local bb = lurek.ai.newBlackboard()
  bb:setBool("player_spotted", true)
  local spotted = bb:getBool("player_spotted")
  lurek.log.info("player spotted: " .. tostring(spotted), "ai")
end

--@api-stub: LSquad:getFormationPosition
-- Returns the formation position of this squad.
do
  local squad = lurek.ai.newSquad("alpha")
  squad:addMember("guard_01")
  squad:setFormation("wedge", 32)
  local px, py = squad:getFormationPosition(1, 400, 300)
  lurek.log.info("slot: " .. px .. "," .. py, "ai")
end

--@api-stub: LInfluenceMap:getInfluence
-- Returns the influence of this influence map.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:stampInfluence("threat", 256, 256, 64, 1.0, 0.9)
  local v = im:getInfluence("threat", 16, 16)
  lurek.log.info("influence at centre: " .. v, "ai")
end

--@api-stub: LAIBlackboard:getNumber
-- Returns the number of this blackboard.
do
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("threat_level", 0.75)
  local t = bb:getNumber("threat_level")
  lurek.log.info("threat: " .. t, "ai")
end

--@api-stub: LAIBlackboard:getString
-- Returns the string of this blackboard.
do
  local bb = lurek.ai.newBlackboard()
  bb:setString("last_enemy", "goblin_03")
  local name = bb:getString("last_enemy")
  lurek.log.info("last enemy: " .. name, "ai")
end

--@api-stub: LQLearner:learn
-- Performs the learn operation on this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  ql:setLearningRate(0.1)
  ql:learn(2, 1, 1.0, 3)
  local qv = ql:getQValue(2, 1)
  lurek.log.info("Q(2,1)=" .. qv, "ai")
end

--@api-stub: LHTNDomain:plan
-- Performs the plan operation on this goap planner.
do
  local planner = lurek.ai.newGOAPPlanner()
  planner:addAction("eat", 1.0, function() end)
  planner:addGoal("not_hungry", 1.0)
  local actions = planner:plan({hungry=true})
  lurek.log.info("plan length: " .. (actions and #actions or 0), "ai")
end

--@api-stub: LHTNDomain:plan
-- Performs the plan operation on this htn domain.
do
  local d = lurek.ai.newHTNDomain()
  d:addPrimitive("move", {}, {}, {})
  d:addCompound("patrol", {{"move"}})
  local plan = d:plan("patrol", {})
  lurek.log.info("htn plan steps: " .. (plan and #plan or 0), "ai")
end

--@api-stub: LInfluenceMap:propagate
-- Performs the propagate operation on this influence map.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:stampInfluence("threat", 256, 256, 48, 1.0, 0.8)
  im:propagate("threat", 0.85)
  lurek.log.info("propagation done", "ai")
end

--@api-stub: LCommandQueue:pushFront
-- Performs the push front operation on this command queue.
do
  local q = lurek.ai.newCommandQueue()
  q:enqueue("patrol", function() end, {})
  q:pushFront("flee", function() end, {threatX=300, threatY=200})
  lurek.log.info("front command: " .. q:getCurrentType(), "ai")
end

--@api-stub: LInfluenceMap:queryRect
-- Performs the query rect operation on this influence map.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("resource")
  im:setInfluence("resource", 10, 10, 1.0)
  local total = im:queryRect("resource", 100, 100, 300, 300)
  lurek.log.info("influence sum: " .. total, "ai")
end

--@api-stub: LCommandQueue:replace
-- Performs the replace operation on this command queue.
do
  local q = lurek.ai.newCommandQueue()
  q:enqueue("move", function() end, {x=200, y=100})
  q:replace("attack", function() end, {targetId="bandit_01"})
  lurek.log.info("replaced: " .. q:getCurrentType(), "ai")
end

--@api-stub: LMCTSEngine:search
-- Performs the search operation on this mcts engine.
do
  local mcts = lurek.ai.newMCTSEngine(100, 1.41, 16, 42)
  local actions = function(s) return {1, 2, 3} end
  local apply   = function(s, a) return s + a end
  local eval    = function(s) return s % 5 end
  local best = mcts:search(0, actions, apply, eval)
  lurek.log.info("best action: " .. best, "ai")
end

--@api-stub: LGOAPPlanner:setEffect
-- Sets the effect of this goap planner.
do
  local planner = lurek.ai.newGOAPPlanner()
  planner:addAction("openDoor", 1.0, function() end)
  planner:setEffect("openDoor", "door_locked", false)
  lurek.log.info("effect registered", "ai")
end

--@api-stub: LSquad:setFormation
-- Sets the formation of this squad.
do
  local squad = lurek.ai.newSquad("bravo")
  squad:addMember("soldier_01")
  squad:addMember("soldier_02")
  squad:setFormation("wedge", 40)
  lurek.log.info("formation: " .. squad:getFormation(), "ai")
end

--@api-stub: LGOAPPlanner:setGoalState
-- Sets the goal state of this goap planner.
do
  local planner = lurek.ai.newGOAPPlanner()
  planner:addGoal("enemy_dead", 1.0)
  planner:setGoalState("enemy_dead", "is_dead", true)
  lurek.log.info("goal state set", "ai")
end

--@api-stub: LInfluenceMap:setInfluence
-- Sets the influence of this influence map.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("hazard")
  im:setInfluence("hazard", 8, 8, 1.0)
  lurek.log.info("cell 8,8 hazard: " .. im:getInfluence("hazard", 8, 8), "ai")
end

--@api-stub: LGOAPPlanner:setPrecondition
-- Sets the precondition of this goap planner.
do
  local planner = lurek.ai.newGOAPPlanner()
  planner:addAction("shoot", 1.0, function() end)
  planner:setPrecondition("shoot", "has_ammo", true)
  lurek.log.info("precondition set", "ai")
end

--@api-stub: LORCASolver:setPreferredVelocity
-- Sets the preferred velocity of this orca solver.
do
  local orca = lurek.ai.newORCASolver(2.0)
  local idx = orca:addAgent(100, 100, 14, 80)
  orca:setPreferredVelocity(idx, 60, 0)
  orca:compute(1 / 60)
  local vx, vy = orca:getSafeVelocity(idx)
  lurek.log.info("safe vel: " .. vx .. "," .. vy, "ai")
end

--@api-stub: LQLearner:setQValue
-- Sets the q value of this q learner.
do
  local ql = lurek.ai.newQLearner(8, 4)
  ql:setQValue(0, 2, 0.85)
  local v = ql:getQValue(0, 2)
  lurek.log.info("Q(0,2)=" .. v, "ai")
end

--@api-stub: LInfluenceMap:stampInfluence
-- Performs the stamp influence operation on this influence map.
do
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:stampInfluence("threat", 256, 256, 96, 1.0, 0.75)
  lurek.log.info("stamped threat blob", "ai")
end

--@api-stub: LAILod:tierFor
-- Performs the tier for operation on this ai lod.
do
  local lod = lurek.ai.newAILod()
  local tier = lod:tierFor(350, 0, 0, 0)
  lurek.log.info("lod tier at 350: " .. tier, "ai")
end

--@api-stub: LORCASolver:addAgent
-- Adds a agent to this orca solver.
do
  local solver = lurek.ai.newORCASolver(2.0)
  solver:addAgent(200, 300, 50, 100)
  solver:compute(1 / 60)
  lurek.log.info("ORCA agent added", "ai")
end

--@api-stub: LNeuralNet:addLayer
-- Adds a layer to this neural net.
do
  local net = lurek.ai.newNeuralNet()
  net:addLayer(2, 4, "relu")
  net:addLayer(4, 1, "relu")
  local out = net:forward({0.25, 0.75})
  lurek.log.info("forward count: " .. #out, "ai")
end

-- -----------------------------------------------------------------------------
-- LAIBlackboard methods
-- -----------------------------------------------------------------------------

--@api-stub: LAIBlackboard:setNumber
-- Stores a numeric fact under the given blackboard key
do
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("health", 100)
  bb:setNumber("aggro_timer", 3.5)
  lurek.log.info("health=" .. bb:getNumber("health", 0), "ai")
end
--@api-stub: LAIBlackboard:getNumber
-- Returns a numeric blackboard fact or the provided fallback when the key is missing or not numeric
do
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("speed", 5.0)
  local v = bb:getNumber("speed", 0.0)
  local missing = bb:getNumber("nonexistent", -1.0)
  lurek.log.info("speed=" .. v .. " missing=" .. missing, "ai")
end
--@api-stub: LAIBlackboard:setBool
-- Stores a boolean fact under the given blackboard key
do
  local bb = lurek.ai.newBlackboard()
  bb:setBool("is_alerted", true)
  bb:setBool("can_attack", false)
  lurek.log.info("alerted=" .. tostring(bb:getBool("is_alerted", false)), "ai")
end
--@api-stub: LAIBlackboard:getBool
-- Returns a boolean blackboard fact or the provided fallback when the key is missing or not boolean
do
  local bb = lurek.ai.newBlackboard()
  bb:setBool("player_visible", true)
  lurek.log.info("visible=" .. tostring(bb:getBool("player_visible", false)), "ai")
  lurek.log.info("default=" .. tostring(bb:getBool("unknown_key", false)), "ai")
end
--@api-stub: LAIBlackboard:setString
-- Stores a string fact under the given blackboard key
do
  local bb = lurek.ai.newBlackboard()
  bb:setString("state", "patrol")
  bb:setString("target_id", "player_1")
  lurek.log.info("state=" .. bb:getString("state", "idle"), "ai")
end
--@api-stub: LAIBlackboard:getString
-- Returns a string blackboard fact or the provided fallback when the key is missing or not a string
do
  local bb = lurek.ai.newBlackboard()
  bb:setString("last_command", "patrol_waypoint_3")
  local cmd = bb:getString("last_command", "idle")
  lurek.log.info("last_command=" .. cmd, "ai")
end
--@api-stub: LTraitProfile:has
-- Returns whether the blackboard contains any entry for the given key
do
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("ammo", 12)
  lurek.log.info("has ammo: " .. tostring(bb:has("ammo")), "ai")
  lurek.log.info("has mana: " .. tostring(bb:has("mana")), "ai")
end
--@api-stub: LStimulusWorld:remove
-- Removes the given key from the blackboard if it exists
do
  local bb = lurek.ai.newBlackboard()
  bb:setString("target", "goblin_5")
  lurek.log.info("before remove: " .. tostring(bb:has("target")), "ai")
  bb:remove("target")
  lurek.log.info("after remove: " .. tostring(bb:has("target")), "ai")
end
--@api-stub: LStimulusWorld:clear
-- Removes every local entry from this blackboard
do
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("hp", 80)
  bb:setBool("alerted", true)
  lurek.log.info("size before clear=" .. bb:getSize(), "ai")
  bb:clear()
  lurek.log.info("size after clear=" .. bb:getSize(), "ai")
end
--@api-stub: LAIBlackboard:getKeys
-- Returns every local blackboard key in an array-style Lua table
do
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("energy", 50)
  bb:setBool("charging", false)
  bb:setString("phase", "attack")
  local keys = bb:getKeys()
  lurek.log.info("key count=" .. #keys, "ai")
end
--@api-stub: LAIBlackboard:getSize
-- Returns the number of entries currently stored in this blackboard
do
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("x", 10)
  bb:setNumber("y", 20)
  lurek.log.info("size=" .. bb:getSize(), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this blackboard handle
do
  local a_i_blackboard_obj = lurek.ai.newBlackboard()
  local t = a_i_blackboard_obj:type()
  lurek.log.info("LAIBlackboard:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this blackboard handle matches a supported type name
do
  local a_i_blackboard_obj = lurek.ai.newBlackboard()
  lurek.log.info("is LAIBlackboard: " .. tostring(a_i_blackboard_obj:typeOf("LAIBlackboard")), "ai")
  lurek.log.info("is wrong: " .. tostring(a_i_blackboard_obj:typeOf("Unknown")), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this AI director handle
do
  local a_i_director_obj = lurek.ai.newAIDirector()
  local t = a_i_director_obj:type()
  lurek.log.info("LAIDirector:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this AI director handle matches a supported type name
do
  local a_i_director_obj = lurek.ai.newAIDirector()
  lurek.log.info("is LAIDirector: " .. tostring(a_i_director_obj:typeOf("LAIDirector")), "ai")
  lurek.log.info("is wrong: " .. tostring(a_i_director_obj:typeOf("Unknown")), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this AI LOD handle
do
  local a_i_lod_obj = lurek.ai.newAILod()
  local t = a_i_lod_obj:type()
  lurek.log.info("LAILod:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this AI LOD handle matches a supported type name
do
  local a_i_lod_obj = lurek.ai.newAILod()
  lurek.log.info("is LAILod: " .. tostring(a_i_lod_obj:typeOf("LAILod")), "ai")
  lurek.log.info("is wrong: " .. tostring(a_i_lod_obj:typeOf("Unknown")), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this bandit handle
do
  local bandit_obj = lurek.ai.newBandit(4, "epsilon-greedy", 0.1, 42)
  local t = bandit_obj:type()
  lurek.log.info("LBandit:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this bandit handle matches a supported type name
do
  local bandit_obj = lurek.ai.newBandit(4, "epsilon-greedy", 0.1, 42)
  lurek.log.info("is LBandit: " .. tostring(bandit_obj:typeOf("LBandit")), "ai")
  lurek.log.info("is wrong: " .. tostring(bandit_obj:typeOf("Unknown")), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this context steering handle
do
  local context_steering_obj = lurek.ai.newContextSteering(8)
  local t = context_steering_obj:type()
  lurek.log.info("LContextSteering:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this context steering handle matches a supported type name
do
  local context_steering_obj = lurek.ai.newContextSteering(8)
  lurek.log.info("is LContextSteering: " .. tostring(context_steering_obj:typeOf("LContextSteering")), "ai")
  lurek.log.info("is wrong: " .. tostring(context_steering_obj:typeOf("Unknown")), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this emotion model handle
do
  local emotion_model_obj = lurek.ai.newEmotionModel()
  local t = emotion_model_obj:type()
  lurek.log.info("LEmotionModel:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this emotion model handle matches a supported type name
do
  local emotion_model_obj = lurek.ai.newEmotionModel()
  lurek.log.info("is LEmotionModel: " .. tostring(emotion_model_obj:typeOf("LEmotionModel")), "ai")
  lurek.log.info("is wrong: " .. tostring(emotion_model_obj:typeOf("Unknown")), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this genetic algorithm handle
do
  local genetic_algorithm_obj = lurek.ai.newGeneticAlgorithm(20, 8, 42)
  local t = genetic_algorithm_obj:type()
  lurek.log.info("LGeneticAlgorithm:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this genetic algorithm handle matches a supported type name
do
  local genetic_algorithm_obj = lurek.ai.newGeneticAlgorithm(20, 8, 42)
  lurek.log.info("is LGeneticAlgorithm: " .. tostring(genetic_algorithm_obj:typeOf("LGeneticAlgorithm")), "ai")
  lurek.log.info("is wrong: " .. tostring(genetic_algorithm_obj:typeOf("Unknown")), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this HTN domain handle
do
  local h_t_n_domain_obj = lurek.ai.newHTNDomain()
  local t = h_t_n_domain_obj:type()
  lurek.log.info("LHTNDomain:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this HTN domain handle matches a supported type name
do
  local h_t_n_domain_obj = lurek.ai.newHTNDomain()
  lurek.log.info("is LHTNDomain: " .. tostring(h_t_n_domain_obj:typeOf("LHTNDomain")), "ai")
  lurek.log.info("is wrong: " .. tostring(h_t_n_domain_obj:typeOf("Unknown")), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this MCTS engine handle
do
  local m_c_t_s_engine_obj = lurek.ai.newMCTSEngine(100, 1.41, 5, 42)
  local t = m_c_t_s_engine_obj:type()
  lurek.log.info("LMCTSEngine:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this MCTS engine handle matches a supported type name
do
  local m_c_t_s_engine_obj = lurek.ai.newMCTSEngine(100, 1.41, 5, 42)
  lurek.log.info("is LMCTSEngine: " .. tostring(m_c_t_s_engine_obj:typeOf("LMCTSEngine")), "ai")
  lurek.log.info("is wrong: " .. tostring(m_c_t_s_engine_obj:typeOf("Unknown")), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this need system handle
do
  local need_system_obj = lurek.ai.newNeedSystem()
  local t = need_system_obj:type()
  lurek.log.info("LNeedSystem:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this need system handle matches a supported type name
do
  local need_system_obj = lurek.ai.newNeedSystem()
  lurek.log.info("is LNeedSystem: " .. tostring(need_system_obj:typeOf("LNeedSystem")), "ai")
  lurek.log.info("is wrong: " .. tostring(need_system_obj:typeOf("Unknown")), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this neural network handle
do
  local neural_net_obj = lurek.ai.newNeuralNet()
  local t = neural_net_obj:type()
  lurek.log.info("LNeuralNet:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this neural network handle matches a supported type name
do
  local neural_net_obj = lurek.ai.newNeuralNet()
  lurek.log.info("is LNeuralNet: " .. tostring(neural_net_obj:typeOf("LNeuralNet")), "ai")
  lurek.log.info("is wrong: " .. tostring(neural_net_obj:typeOf("Unknown")), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this neuroevolution handle
do
  local ne_layers = { {inputs=4, outputs=8, activation="relu"}, {inputs=8, outputs=4, activation="softmax"} }
  local ok_ne, neuroevolution_obj = pcall(lurek.ai.newNeuroevolution, ne_layers, 20, 42)
  local t = (ok_ne and neuroevolution_obj) and neuroevolution_obj:type() or "LNeuroevolution"
  lurek.log.info("LNeuroevolution:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this neuroevolution handle matches a supported type name
do
  local ne_layers = { {inputs=4, outputs=8, activation="relu"}, {inputs=8, outputs=4, activation="softmax"} }
  local ok_ne, neuroevolution_obj = pcall(lurek.ai.newNeuroevolution, ne_layers, 20, 42)
  lurek.log.info("is LNeuroevolution: " .. tostring((ok_ne and neuroevolution_obj) and neuroevolution_obj:typeOf("LNeuroevolution") or false), "ai")
  lurek.log.info("is wrong: " .. tostring((ok_ne and neuroevolution_obj) and neuroevolution_obj:typeOf("Unknown") or false), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this ORCA solver handle
do
  local o_r_c_a_solver_obj = lurek.ai.newORCASolver(0.5)
  local t = o_r_c_a_solver_obj:type()
  lurek.log.info("LORCASolver:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this ORCA solver handle matches a supported type name
do
  local o_r_c_a_solver_obj = lurek.ai.newORCASolver(0.5)
  lurek.log.info("is LORCASolver: " .. tostring(o_r_c_a_solver_obj:typeOf("LORCASolver")), "ai")
  lurek.log.info("is wrong: " .. tostring(o_r_c_a_solver_obj:typeOf("Unknown")), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this stimulus world handle
do
  local stimulus_world_obj = lurek.ai.newStimulusWorld()
  local t = stimulus_world_obj:type()
  lurek.log.info("LStimulusWorld:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this stimulus world handle matches a supported type name
do
  local stimulus_world_obj = lurek.ai.newStimulusWorld()
  lurek.log.info("is LStimulusWorld: " .. tostring(stimulus_world_obj:typeOf("LStimulusWorld")), "ai")
  lurek.log.info("is wrong: " .. tostring(stimulus_world_obj:typeOf("Unknown")), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this strategy AI handle
do
  local strategy_a_i_obj = lurek.ai.newStrategyAI(0.25)
  local t = strategy_a_i_obj:type()
  lurek.log.info("LStrategyAI:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this strategy AI handle matches a supported type name
do
  local strategy_a_i_obj = lurek.ai.newStrategyAI(0.25)
  lurek.log.info("is LStrategyAI: " .. tostring(strategy_a_i_obj:typeOf("LStrategyAI")), "ai")
  lurek.log.info("is wrong: " .. tostring(strategy_a_i_obj:typeOf("Unknown")), "ai")
end
--@api-stub: LAILod:type
-- Returns the Lua-visible type name for this trait profile handle
do
  local trait_profile_obj = lurek.ai.newTraitProfile()
  local t = trait_profile_obj:type()
  lurek.log.info("LTraitProfile:type = " .. t, "ai")
end
--@api-stub: LAILod:typeOf
-- Returns whether this trait profile handle matches a supported type name
do
  local trait_profile_obj = lurek.ai.newTraitProfile()
  lurek.log.info("is LTraitProfile: " .. tostring(trait_profile_obj:typeOf("LTraitProfile")), "ai")
  lurek.log.info("is wrong: " .. tostring(trait_profile_obj:typeOf("Unknown")), "ai")
end

--@api-stub: LBTNode:addChild
-- Adds a child node to a parent node id in this behavior tree and returns the new node id.
do
  -- BehaviorTree nodes are created with lurek.ai.newSequence/newSelector/newAction/etc.
  -- then linked via node:addChild(). This is LBTNode:addChild, not a bt method.
  local seq = lurek.ai.newSequence()
  local check_hp = lurek.ai.newCondition(function() return true end)
  local attack = lurek.ai.newAction(function() return "success" end)
  seq:addChild(check_hp)   -- add condition as first child
  seq:addChild(attack)     -- add action as second child
  local bt = lurek.ai.newBehaviorTree()
  bt:setRoot(seq)
  lurek.log.debug("BT built: seq with " .. seq:getChildCount() .. " children", "ai")
end

--@api-stub: LBehaviorTree:addInverter
-- Adds an inverter decorator node under a parent node and returns the new node id.
do
  -- newInverter() wraps a child node and flips success ↔ failure.
  -- Use setChild() on the inverter (decorator pattern), not addChild.
  local action = lurek.ai.newAction(function() return "failure" end)
  local inv = lurek.ai.newInverter()
  inv:setChild(action)     -- inverter turns failure → success
  local bt = lurek.ai.newBehaviorTree()
  bt:setRoot(inv)
  lurek.log.debug("BT with inverter, childCount=" .. inv:getChildCount(), "ai")
end

--@api-stub: LBehaviorTree:addLeaf
-- Adds a named leaf action node under a parent node and returns the new node id.
do
  -- Leaf nodes are created with lurek.ai.newAction(fn) or lurek.ai.newCondition(fn).
  -- newAction executes a callback each tick and returns "success"/"failure"/"running".
  local leaf = lurek.ai.newAction(function()
    -- Leaf logic: e.g., move toward target, play animation, etc.
    return "success"
  end)
  local bt = lurek.ai.newBehaviorTree()
  bt:setRoot(leaf)
  lurek.log.debug("BT with action leaf ready", "ai")
end

--@api-stub: LBehaviorTree:addParallel
-- Adds a parallel composite node under a parent node and returns the new node id.
do
  -- newParallel() runs ALL children simultaneously each tick.
  -- Both succeed, both fail, or one runs independently of the other.
  local par = lurek.ai.newParallel()
  local patrol = lurek.ai.newAction(function() return "running" end)
  local scan   = lurek.ai.newAction(function() return "running" end)
  par:addChild(patrol)
  par:addChild(scan)
  local bt = lurek.ai.newBehaviorTree()
  bt:setRoot(par)
  lurek.log.debug("BT with parallel, children=" .. par:getChildCount(), "ai")
end

--@api-stub: LBehaviorTree:addRepeat
-- Adds a repeat decorator node that runs its child N times under a parent and returns the node id.
do
  -- newRepeater(count) repeats its child N times before reporting success.
  -- Use setChild() for decorator nodes (single child).
  local action = lurek.ai.newAction(function() return "success" end)
  local rep = lurek.ai.newRepeater(3)
  rep:setChild(action)
  local bt = lurek.ai.newBehaviorTree()
  bt:setRoot(rep)
  lurek.log.debug("BT with repeater(3), count=" .. rep:getCount(), "ai")
end

--@api-stub: LBehaviorTree:addSelector
-- Adds a selector composite node under a parent node and returns the new node id.
do
  -- newSelector() tries children left-to-right; succeeds on the first success.
  -- Use for "try this, if it fails try that" AI fallback logic.
  local sel = lurek.ai.newSelector()
  local preferred = lurek.ai.newAction(function() return "failure" end)  -- fails → try next
  local fallback  = lurek.ai.newAction(function() return "success" end)  -- succeeds
  sel:addChild(preferred)
  sel:addChild(fallback)
  local bt = lurek.ai.newBehaviorTree()
  bt:setRoot(sel)
  lurek.log.debug("BT with selector, children=" .. sel:getChildCount(), "ai")
end

--@api-stub: LBehaviorTree:addSequence
-- Adds a sequence composite node under a parent node and returns the new node id.
do
  -- newSequence() runs children in order; stops and fails on first failure.
  -- Use for "do A, then B, then C" chains that abort early on failure.
  local seq = lurek.ai.newSequence()
  local step1 = lurek.ai.newAction(function() return "success" end)
  local step2 = lurek.ai.newAction(function() return "success" end)
  seq:addChild(step1)
  seq:addChild(step2)
  local bt = lurek.ai.newBehaviorTree()
  bt:setRoot(seq)
  lurek.log.debug("BT with sequence, children=" .. seq:getChildCount(), "ai")
end

--@api-stub: LInfluenceMap:clearAll
-- Removes all nodes from this behavior tree and resets it to an empty state.
do
  -- LuaBehaviorTree has no clearAll(); to reset, create a new BT
  -- or call node:reset() on individual nodes to clear execution state.
  local bt = lurek.ai.newBehaviorTree()
  local seq = lurek.ai.newSequence()
  bt:setRoot(seq)
  -- "clear" by creating a fresh tree and discarding the old reference
  bt = lurek.ai.newBehaviorTree()
  seq:reset()  -- clear node execution state
  lurek.log.debug("BT node state cleared via reset()", "ai")
end

--@api-stub: LBehaviorTree:nodeCount
-- Returns the total number of nodes currently in this behavior tree.
do
  -- LuaBehaviorTree has no nodeCount(). Use getChildCount() on composite nodes
  -- to count direct children. Full subtree counting is done manually in Lua.
  local seq = lurek.ai.newSequence()
  seq:addChild(lurek.ai.newAction(function() return "success" end))
  seq:addChild(lurek.ai.newAction(function() return "success" end))
  lurek.log.debug("seq childCount=" .. seq:getChildCount(), "ai")
end

--@api-stub: LBehaviorTree:resetState
-- Resets the execution state of all nodes in this behavior tree to idle.
do
  -- Call node:reset() on each node that needs execution state cleared.
  -- Composite nodes (sequence, selector, parallel) all support reset().
  local seq = lurek.ai.newSequence()
  local action = lurek.ai.newAction(function() return "running" end)
  seq:addChild(action)
  seq:reset()    -- clear tick state; next tick starts from the beginning
  action:reset()
  local bt = lurek.ai.newBehaviorTree()
  bt:setRoot(seq)
  lurek.log.debug("node execution state reset", "ai")
end

--@api-stub: LBehaviorTree:setLeaf
-- Replaces the action name of an existing leaf node by id in this behavior tree.
do
  -- LuaBehaviorTree has no setLeaf(). To "replace" a leaf, create a new action
  -- node and swap it using the parent node's setChild().
  local old_action = lurek.ai.newAction(function() return "success" end)
  local new_action = lurek.ai.newAction(function() return "running" end)
  local inv = lurek.ai.newInverter()
  inv:setChild(old_action)
  inv:setChild(new_action)  -- replace old with new
  local bt = lurek.ai.newBehaviorTree()
  bt:setRoot(inv)
  lurek.log.debug("leaf swapped via setChild()", "ai")
end

--@api-stub: LBehaviorTree:tick
-- Runs one tick of this behavior tree with a blackboard table and returns the root status.
do
  -- LuaBehaviorTree has no tick(). The tree is driven by the AI world's update loop.
  -- Set the root node and let the engine tick it each frame via world:update().
  -- getLastStatus() and getDebugState() read results after the engine ticks.
  local seq = lurek.ai.newSequence()
  seq:addChild(lurek.ai.newAction(function() return "success" end))
  local bt = lurek.ai.newBehaviorTree()
  bt:setRoot(seq)
  -- After engine ticks this bt: bt:getLastStatus() and bt:getDebugState()
  lurek.log.debug("BT ready; engine drives ticks via world:update()", "ai")
end

--@api-stub: LDialogueAI:addBranch
-- Adds a response branch with a label and condition to a topic in this dialogue AI.
do
  local d = lurek.ai.newDialogueAI()
  d:addTopic("greet")
  -- addBranch(topic_id, branch_id, weight?, fsm_state?, bt_status?, utility_key?)
  d:addBranch("greet", "friendly", 1.0)
end

--@api-stub: LDialogueAI:addTopic
-- Adds a named dialogue topic to this dialogue AI for later selection.
do
  local d = lurek.ai.newDialogueAI()
  d:addTopic("greet")
end

--@api-stub: LDialogueAI:clearUtilityScores
-- Resets all utility scores in this dialogue AI to zero.
do
  local d = lurek.ai.newDialogueAI()
  d:setUtilityScore("greet", 1.0)
  d:clearUtilityScores()
end

--@api-stub: LDialogueAI:getTopicCount
-- Returns the number of topics currently registered in this dialogue AI.
do
  local d = lurek.ai.newDialogueAI()
  d:addTopic("greet")
  lurek.log.debug("topics=" .. d:getTopicCount(), "ai")
end

--@api-stub: LDialogueAI:selectBranch
-- Selects the highest-scoring active branch for a topic and returns its label.
do
  local d = lurek.ai.newDialogueAI()
  d:addTopic("greet")
  d:addBranch("greet", "friendly", 1.0)
  local branch = d:selectBranch("greet")
  lurek.log.debug("branch=" .. tostring(branch), "ai")
end

--@api-stub: LDialogueAI:selectTopic
-- Returns the topic with the highest utility score that passes its condition.
do
  local d = lurek.ai.newDialogueAI()
  d:addTopic("greet")
  d:setUtilityScore("greet", 0.9)
  local topic = d:selectTopic()
  lurek.log.debug("topic=" .. tostring(topic), "ai")
end

--@api-stub: LDialogueAI:setBTStatus
-- Sets the behavior tree status used as context for dialogue condition evaluation.
do
  local d = lurek.ai.newDialogueAI()
  d:setBTStatus("running")
end

--@api-stub: LDialogueAI:setFSMState
-- Sets the FSM state name used as context for dialogue condition evaluation.
do
  local d = lurek.ai.newDialogueAI()
  d:setFSMState("combat")
end

--@api-stub: LDialogueAI:setUtilityScore
-- Sets the utility score for a named topic in this dialogue AI.
do
  local d = lurek.ai.newDialogueAI()
  d:addTopic("greet")
  d:setUtilityScore("greet", 0.8)
end

--@api-stub: LAILod:type
-- Returns the Lua-visible type name string for this dialogue AI handle.
do
  local d = lurek.ai.newDialogueAI()
  lurek.log.info(d:type(), "ai")
end

--@api-stub: LAILod:typeOf
-- Returns true if this dialogue AI handle matches the given type name string.
do
  local d = lurek.ai.newDialogueAI()
  lurek.log.info(tostring(d:typeOf("LDialogueAI")), "ai")
end

--@api-stub: LSteeringManager:clearPath
-- Clears the current movement path from this steering manager.
do
  local sm = lurek.ai.newSteeringManager()
  sm:clearPath()
end

--@api-stub: LSteeringManager:getPathProgress
-- Returns the current path progress as a fraction from 0.0 to 1.0.
do
  local sm = lurek.ai.newSteeringManager()
  local prog = sm:getPathProgress()
  lurek.log.debug("progress=" .. prog, "ai")
end

--@api-stub: LSteeringManager:hasPath
-- Returns true if this steering manager currently has a path to follow.
do
  local sm = lurek.ai.newSteeringManager()
  lurek.log.debug("has path=" .. tostring(sm:hasPath()), "ai")
end

--@api-stub: LSteeringManager:setPath
-- Sets the waypoint path for this steering manager to follow.
do
  local sm = lurek.ai.newSteeringManager()
  sm:setPath({{x=0,y=0},{x=100,y=0},{x=100,y=100}})
end

print("content/examples/ai.lua")

-- -----------------------------------------------------------------------------
-- LAIDirector methods (additional coverage)
-- -----------------------------------------------------------------------------

--@api-stub: LAIDirector:update
-- Advances director tension decay and phase evaluation.
do
  -- Call update(dt) each frame to decay tension and re-evaluate the current phase.
  -- Scenario: horde-mode director ticks tension down between waves.
  local dir = lurek.ai.newAIDirector()
  dir:setTension(0.8)
  dir:update(0.5)
  lurek.log.info("tension after decay: " .. dir:tension(), "ai")
end

--@api-stub: LAIDirector:reset
-- Resets director tension and phase state to defaults.
do
  -- Reset after a level transition or when the player enters a safe zone.
  -- Scenario: player reaches a checkpoint — reset director for the next area.
  local dir = lurek.ai.newAIDirector()
  dir:setTension(0.9)
  dir:reset()
  lurek.log.info("tension after reset: " .. dir:tension(), "ai")
end

-- -----------------------------------------------------------------------------
-- LAIWorld methods (additional coverage)
-- -----------------------------------------------------------------------------

--@api-stub: LAIWorld:addAgent
-- Creates a named agent in this world and returns a handle that can edit its movement and decision state.
do
  -- Register NPCs in the AI world so they can perceive and be perceived by others.
  -- Scenario: spawn a patrol guard at level start.
  local world = lurek.ai.newWorld()
  local guard = world:addAgent("patrol_guard")
  guard:setPosition(200, 150)
  lurek.log.info("spawned agent: " .. guard:getName(), "ai")
end

--@api-stub: LAIWorld:update
-- Advances the world simulation and invokes custom decision callbacks for agents that use a custom model.
do
  -- Tick the world each frame to update all agent decision models.
  -- Scenario: dungeon level with 3 guards running FSM-based AI.
  local world = lurek.ai.newWorld()
  world:addAgent("sentry_a")
  world:addAgent("sentry_b")
  world:update(0.016)
  lurek.log.info("world ticked, agents: " .. world:getAgentCount(), "ai")
end

--@api-stub: LAIWorld:type
-- Returns the Lua-visible type name for this AI world handle.
do
  local world = lurek.ai.newWorld()
  lurek.log.info("world type: " .. world:type(), "ai")
end

--@api-stub: LAIWorld:typeOf
-- Returns whether this AI world handle matches a supported type name.
do
  local world = lurek.ai.newWorld()
  lurek.log.info("is AIWorld: " .. tostring(world:typeOf("AIWorld")), "ai")
end

-- -----------------------------------------------------------------------------
-- LAgent methods (additional coverage)
-- -----------------------------------------------------------------------------

--@api-stub: LAgent:getName
-- Returns this agent's stable world name.
do
  -- Use getName() to identify agents for logging or UI labels.
  -- Scenario: display NPC name above their head in the game.
  local world = lurek.ai.newWorld()
  local npc = world:addAgent("merchant_01")
  lurek.log.info("agent name: " .. npc:getName(), "ai")
end

--@api-stub: LAgent:setPosition
-- Sets this agent's world position when the agent still exists in its world.
do
  -- Teleport or reposition an agent during gameplay.
  -- Scenario: guard returns to post after losing sight of the player.
  local world = lurek.ai.newWorld()
  local guard = world:addAgent("gate_guard")
  guard:setPosition(400, 300)
  local x, y = guard:getPosition()
  lurek.log.info("guard at: " .. x .. "," .. y, "ai")
end

--@api-stub: LAgent:addTag
-- Adds a tag string to this agent when the agent still exists in its world.
do
  -- Tags classify agents for query filtering (e.g., "hostile", "civilian").
  -- Scenario: mark a freshly-aggro'd NPC as hostile.
  local world = lurek.ai.newWorld()
  local npc = world:addAgent("villager")
  npc:addTag("civilian")
  npc:addTag("quest_giver")
  lurek.log.info("tagged villager as civilian + quest_giver", "ai")
end

--@api-stub: LAgent:removeTag
-- Removes a tag string from this agent when the agent still exists in its world.
do
  -- Remove a tag when status changes (e.g., enemy becomes friendly).
  -- Scenario: charmed enemy loses "hostile" tag.
  local world = lurek.ai.newWorld()
  local enemy = world:addAgent("goblin")
  enemy:addTag("hostile")
  enemy:removeTag("hostile")
  lurek.log.info("goblin no longer hostile: " .. tostring(enemy:hasTag("hostile")), "ai")
end

--@api-stub: LAgent:getBlackboard
-- Returns a blackboard snapshot for this agent or an empty blackboard when the agent has been removed.
do
  -- Each agent has its own private blackboard for local AI state.
  -- Scenario: store this guard's current patrol waypoint index.
  local world = lurek.ai.newWorld()
  local guard = world:addAgent("wall_guard")
  local bb = guard:getBlackboard()
  bb:setNumber("waypoint_idx", 0)
  lurek.log.info("bb size: " .. bb:getSize(), "ai")
end

--@api-stub: LAgent:type
-- Returns the Lua-visible type name for this agent handle.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("test_agent")
  lurek.log.info("agent type: " .. agent:type(), "ai")
end

--@api-stub: LAgent:typeOf
-- Returns whether this agent handle matches a supported type name.
do
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("test_agent")
  lurek.log.info("is Agent: " .. tostring(agent:typeOf("Agent")), "ai")
end

-- -----------------------------------------------------------------------------
-- LBTNode methods (additional coverage)
-- -----------------------------------------------------------------------------

--@api-stub: LBTNode:reset
-- Resets this behavior tree node's runtime state.
do
  -- Clear running/success state so the node re-evaluates from scratch.
  -- Scenario: player breaks line-of-sight; reset the chase sequence.
  local seq = lurek.ai.newSequence()
  seq:addChild(lurek.ai.newAction(function() return "running" end))
  seq:reset()
  lurek.log.info("sequence node state cleared", "ai")
end

--@api-stub: LBTNode:getCount
-- Returns the repeat count for repeater nodes or zero for other node kinds.
do
  -- Check how many iterations a repeater will perform.
  -- Scenario: verify burst-fire repeater is set to 3 shots.
  local rep = lurek.ai.newRepeater(3)
  lurek.log.info("repeater count: " .. rep:getCount(), "ai")
end

--@api-stub: LBTNode:type
-- Returns the Lua-visible type name for this behavior tree node handle.
do
  local action = lurek.ai.newAction(function() return "success" end)
  lurek.log.info("node type: " .. action:type(), "ai")
end

--@api-stub: LBTNode:typeOf
-- Returns whether this behavior tree node handle matches a supported type name.
do
  local sel = lurek.ai.newSelector()
  lurek.log.info("is BTNode: " .. tostring(sel:typeOf("BTNode")), "ai")
end

-- -----------------------------------------------------------------------------
-- LBandit methods (additional coverage)
-- -----------------------------------------------------------------------------

--@api-stub: LBandit:update
-- Updates one arm with a received reward.
do
  -- Feed reward signal back to the bandit after observing the outcome.
  -- Scenario: player died to enemy type 2 — update arm 2 with reward 1.0.
  local b = lurek.ai.newBandit(4, "ucb1", 0.1, 99)
  local arm = b:select()
  b:update(arm, 0.8)
  lurek.log.info("updated arm " .. arm .. " with reward 0.8", "ai")
end

--@api-stub: LBehaviorTree:type
-- Returns the Lua-visible type name for this behavior tree handle.
do
  local bt = lurek.ai.newBehaviorTree()
  lurek.log.info("bt type: " .. bt:type(), "ai")
end

--@api-stub: LBehaviorTree:typeOf
-- Returns whether this behavior tree handle matches a supported type name.
do
  local bt = lurek.ai.newBehaviorTree()
  lurek.log.info("is BehaviorTree: " .. tostring(bt:typeOf("BehaviorTree")), "ai")
end

-- -----------------------------------------------------------------------------
-- LCommandQueue methods (additional coverage)
-- -----------------------------------------------------------------------------

--@api-stub: LCommandQueue:clear
-- Removes every queued command. This method is available to Lua scripts.
do
  -- Wipe the queue when an NPC is interrupted or stunned.
  -- Scenario: boss gets staggered — cancel all queued attack phases.
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("slam", function() end, {})
  cq:enqueue("roar", function() end, {})
  cq:clear()
  lurek.log.info("queue cleared, empty: " .. tostring(cq:isEmpty()), "ai")
end

--@api-stub: LCommandQueue:type
-- Returns the Lua-visible type name for this command queue handle.
do
  local cq = lurek.ai.newCommandQueue()
  lurek.log.info("cq type: " .. cq:type(), "ai")
end

--@api-stub: LCommandQueue:typeOf
-- Returns whether this command queue handle matches a supported type name.
do
  local cq = lurek.ai.newCommandQueue()
  lurek.log.info("is CommandQueue: " .. tostring(cq:typeOf("CommandQueue")), "ai")
end

-- -----------------------------------------------------------------------------
-- LEmotionModel methods (additional coverage)
-- -----------------------------------------------------------------------------

--@api-stub: LEmotionModel:update
-- Advances emotion decay over elapsed time.
do
  -- Decay emotions each frame so fear/anger fade after the threat passes.
  -- Scenario: NPC calms down 2 seconds after the player leaves sight.
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.1, 1.0)
  em:trigger("fear", 0.8)
  em:update(1.0)
  lurek.log.info("fear after 1s decay: " .. em:get("fear"), "ai")
end

--@api-stub: LEmotionModel:reset
-- Resets all emotions toward their default state.
do
  -- Clear all emotion state when an NPC respawns or role changes.
  -- Scenario: guard dies and respawns — emotions start fresh.
  local em = lurek.ai.newEmotionModel()
  em:add("anger", 0.0, 0.05, 1.0)
  em:trigger("anger", 0.9)
  em:reset()
  lurek.log.info("anger after reset: " .. em:get("anger"), "ai")
end

-- -----------------------------------------------------------------------------
-- LGOAPPlanner methods (additional coverage)
-- -----------------------------------------------------------------------------

--@api-stub: LGOAPPlanner:addGoal
-- Adds a GOAP goal with an optional priority weight.
do
  -- Define what the NPC wants to achieve. Higher priority = preferred goal.
  -- Scenario: survival NPC prioritizes "stay_alive" over "gather_food".
  local planner = lurek.ai.newGOAPPlanner()
  planner:addAction("eat", 1.0, function() end)
  planner:addGoal("not_hungry", 2.0)
  planner:addGoal("is_rested", 1.0)
  lurek.log.info("goals: " .. planner:getGoalCount(), "ai")
end

--@api-stub: LGOAPPlanner:plan
-- Builds a plan from the supplied boolean world state and returns action names in execution order.
do
  -- Run the planner with current world state to get an ordered action sequence.
  -- Scenario: NPC checks what actions lead to "enemy_dead" from current state.
  local planner = lurek.ai.newGOAPPlanner()
  planner:addAction("get_weapon", 1.0, function() end)
  planner:addAction("attack", 2.0, function() end)
  planner:addGoal("enemy_dead", 1.0)
  local plan = planner:plan({ has_weapon = false, enemy_dead = false })
  lurek.log.info("plan steps: " .. (plan and #plan or 0), "ai")
end

--@api-stub: LGOAPPlanner:type
-- Returns the Lua-visible type name for this GOAP planner handle.
do
  local planner = lurek.ai.newGOAPPlanner()
  lurek.log.info("planner type: " .. planner:type(), "ai")
end

--@api-stub: LGOAPPlanner:typeOf
-- Returns whether this GOAP planner handle matches a supported type name.
do
  local planner = lurek.ai.newGOAPPlanner()
  lurek.log.info("is GOAPPlanner: " .. tostring(planner:typeOf("GOAPPlanner")), "ai")
end

-- -----------------------------------------------------------------------------
-- LGeneticAlgorithm methods (additional coverage)
-- -----------------------------------------------------------------------------

--@api-stub: LGeneticAlgorithm:evolve
-- Advances the genetic algorithm by one generation.
do
  -- Run one generation of selection, crossover, and mutation.
  -- Scenario: evolve enemy stat distributions to challenge the player.
  local ga = lurek.ai.newGeneticAlgorithm(20, 8, 42)
  for i = 0, ga:popSize() - 1 do ga:setFitness(i, math.random()) end
  ga:evolve()
  lurek.log.info("generation after evolve: " .. ga:generation(), "ai")
end

--@api-stub: LGeneticAlgorithm:generation
-- Returns the current generation index.
do
  -- Track how many generations have passed for convergence checks.
  -- Scenario: stop evolving after 100 generations.
  local ga = lurek.ai.newGeneticAlgorithm(10, 4, 7)
  lurek.log.info("initial generation: " .. ga:generation(), "ai")
end

--@api-stub: LGeneticAlgorithm:popSize
-- Returns the population size. This method is available to Lua scripts.
do
  -- Know the population size for iterating fitness assignments.
  local ga = lurek.ai.newGeneticAlgorithm(30, 8, 42)
  lurek.log.info("population: " .. ga:popSize(), "ai")
end

--@api-stub: LGeneticAlgorithm:setFitness
-- Sets the fitness value for a chromosome by zero-based index.
do
  -- Assign fitness scores before calling evolve() to guide selection.
  -- Scenario: score each chromosome by how well it performed in simulation.
  local ga = lurek.ai.newGeneticAlgorithm(10, 4, 42)
  ga:setFitness(0, 0.95)
  ga:setFitness(1, 0.3)
  lurek.log.info("fitness assigned to chromosomes 0 and 1", "ai")
end

--@api-stub: LInfluenceMap:addLayer
-- Adds an influence layer with the given name if it does not already exist.
do
  -- Create separate layers for different concerns (threat, resources, territory).
  -- Scenario: RTS map with threat and resource layers for AI decision-making.
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:addLayer("resources")
  lurek.log.info("has threat: " .. tostring(im:hasLayer("threat")), "ai")
end

--@api-stub: LInfluenceMap:type
-- Returns the Lua-visible type name for this influence map handle.
do
  local im = lurek.ai.newInfluenceMap(16, 16, 32)
  lurek.log.info("im type: " .. im:type(), "ai")
end

--@api-stub: LInfluenceMap:typeOf
-- Returns whether this influence map handle matches a supported type name.
do
  local im = lurek.ai.newInfluenceMap(16, 16, 32)
  lurek.log.info("is InfluenceMap: " .. tostring(im:typeOf("InfluenceMap")), "ai")
end

-- -----------------------------------------------------------------------------
-- LNeedSystem / LQLearner methods (additional coverage)
-- -----------------------------------------------------------------------------

--@api-stub: LNeedSystem:update
-- Advances need decay over elapsed time.
do
  -- Tick needs each frame so hunger/thirst/energy increase toward threshold.
  -- Scenario: survival NPC's hunger rises until it triggers the eat behavior.
  local ns = lurek.ai.newNeedSystem()
  ns:addNeed("hunger", 0.1, 0.7, 1.5)
  ns:update(2.0)
  lurek.log.info("hunger after 2s: " .. ns:valueOf("hunger"), "ai")
end

--@api-stub: LQLearner:getActionCount
-- Returns the number of actions represented by this learner.
do
  -- Check how many possible actions the Q-learner can choose from.
  local ql = lurek.ai.newQLearner(8, 4)
  lurek.log.info("actions: " .. ql:getActionCount(), "ai")
end

--@api-stub: LQLearner:type
-- Returns the Lua-visible type name for this Q-learner handle.
do
  local ql = lurek.ai.newQLearner(4, 2)
  lurek.log.info("ql type: " .. ql:type(), "ai")
end

--@api-stub: LQLearner:typeOf
-- Returns whether this Q-learner handle matches a supported type name.
do
  local ql = lurek.ai.newQLearner(4, 2)
  lurek.log.info("is QLearner: " .. tostring(ql:typeOf("QLearner")), "ai")
end

-- -----------------------------------------------------------------------------
-- LSquad methods (additional coverage)
-- -----------------------------------------------------------------------------

--@api-stub: LSquad:type
-- Returns the Lua-visible type name for this squad handle.
do
  local sq = lurek.ai.newSquad("bravo")
  lurek.log.info("squad type: " .. sq:type(), "ai")
end

--@api-stub: LSquad:typeOf
-- Returns whether this squad handle matches a supported type name.
do
  local sq = lurek.ai.newSquad("bravo")
  lurek.log.info("is Squad: " .. tostring(sq:typeOf("Squad")), "ai")
end

-- -----------------------------------------------------------------------------
-- LStateMachine methods (additional coverage)
-- -----------------------------------------------------------------------------

--@api-stub: LStateMachine:type
-- Returns the Lua-visible type name for this state machine handle.
do
  local fsm = lurek.ai.newStateMachine()
  lurek.log.info("fsm type: " .. fsm:type(), "ai")
end

--@api-stub: LStateMachine:typeOf
-- Returns whether this state machine handle matches a supported type name.
do
  local fsm = lurek.ai.newStateMachine()
  lurek.log.info("is StateMachine: " .. tostring(fsm:typeOf("StateMachine")), "ai")
end

-- -----------------------------------------------------------------------------
-- LSteeringManager methods (additional coverage)
-- -----------------------------------------------------------------------------

--@api-stub: LSteeringManager:addWander
-- Adds a wander behavior that produces jittered exploratory movement.
do
  -- Wander makes NPCs roam aimlessly. Good for idle creatures or ambient wildlife.
  -- Scenario: deer wanders the forest when no threat is nearby.
  local sm = lurek.ai.newSteeringManager()
  sm:addWander(20, 40, 5, 0.4)
  lurek.log.info("wander added, behaviors: " .. sm:getBehaviorCount(), "ai")
end

--@api-stub: LSteeringManager:type
-- Returns the Lua-visible type name for this steering manager handle.
do
  local sm = lurek.ai.newSteeringManager()
  lurek.log.info("sm type: " .. sm:type(), "ai")
end

--@api-stub: LSteeringManager:typeOf
-- Returns whether this steering manager handle matches a supported type name.
do
  local sm = lurek.ai.newSteeringManager()
  lurek.log.info("is SteeringManager: " .. tostring(sm:typeOf("SteeringManager")), "ai")
end

--@api-stub: LStimulusWorld:update
-- Advances stimulus decay and lifetime state.
do
  -- Tick the stimulus world so old stimuli fade and expire.
  -- Scenario: gunshot sound fades over 3 seconds so guards forget after a while.
  local sw = lurek.ai.newStimulusWorld()
  sw:addAuditory(100, 200, 1.0, 150, 0.5, "gunshot")
  sw:update(1.0)
  lurek.log.info("stimuli after 1s: " .. sw:count(), "ai")
end

--@api-stub: LTraitProfile:get
-- Returns the current value of a named trait including active modifiers.
do
  -- Read the effective trait value (base + modifiers) for decision-making.
  -- Scenario: check if NPC's effective courage is high enough to engage.
  local tp = lurek.ai.newTraitProfile()
  tp:set("courage", 0.5)
  tp:addModifier("courage", 0.3, 10.0, "battle_cry")
  lurek.log.info("effective courage: " .. tp:get("courage"), "ai")
end

--@api-stub: LTraitProfile:update
-- Advances modifier timers and removes expired modifiers.
do
  -- Tick trait profile so temporary modifiers expire naturally.
  -- Scenario: rage buff (5s duration) wears off after enough time passes.
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.4)
  tp:addModifier("aggression", 0.5, 2.0, "rage")
  tp:update(3.0)
  lurek.log.info("aggression after buff expires: " .. tp:get("aggression"), "ai")
end

--@api-stub: LUtilityAI:addAction
-- Adds an action scored by a Lua callback and optional momentum weight.
do
  -- Register possible actions with scoring functions for utility-based selection.
  -- Scenario: NPC can patrol, eat, or sleep — each scored by current needs.
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("patrol", function() return 0.3 end, 1.0)
  uai:addAction("eat", function() return 0.7 end, 1.0)
  uai:addAction("sleep", function() return 0.5 end, 1.0)
  lurek.log.info("utility actions: " .. uai:getActionCount(), "ai")
end

--@api-stub: LUtilityAI:evaluate
-- Evaluates all actions and returns the winning action name when one is available.
do
  -- Score all actions and pick the highest — the core utility AI loop.
  -- Scenario: NPC decides between flee and fight based on current HP.
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("fight", function() return 0.4 end)
  uai:addAction("flee", function() return 0.9 end)
  local choice = uai:evaluate()
  lurek.log.info("utility chose: " .. (choice or "none"), "ai")
end

--@api-stub: LUtilityAI:getActionCount
-- Returns the number of actions registered in this utility AI.
do
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("a", function() return 0.1 end)
  uai:addAction("b", function() return 0.2 end)
  lurek.log.info("action count: " .. uai:getActionCount(), "ai")
end

--@api-stub: LUtilityAI:type
-- Returns the Lua-visible type name for this utility AI handle.
do
  local uai = lurek.ai.newUtilityAI()
  lurek.log.info("uai type: " .. uai:type(), "ai")
end

--@api-stub: LUtilityAI:typeOf
-- Returns whether this utility AI handle matches a supported type name.
do
  local uai = lurek.ai.newUtilityAI()
  lurek.log.info("is UtilityAI: " .. tostring(uai:typeOf("UtilityAI")), "ai")
end

-- =============================================================================
-- STUBS: 35 uncovered lurek.ai API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LAIBlackboard methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAIBlackboard:has ---------------------------------------------
--@api-stub: LAIBlackboard:has
-- Returns whether the blackboard contains any entry for the given key.
do
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("score", 42)
  local found = bb:has("score")
  lurek.log.debug("has 'score': " .. tostring(found), "ai") -- true
  local missing = bb:has("no_such_key")
  lurek.log.debug("has 'no_such_key': " .. tostring(missing), "ai") -- false
end

-- ---- Stub: LAIBlackboard:remove ------------------------------------------
--@api-stub: LAIBlackboard:remove
-- Removes the given key from the blackboard if it exists.
do
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("hp", 100)
  bb:setNumber("mp", 50)
  bb:remove("hp")
  lurek.log.debug("after remove, has 'hp': " .. tostring(bb:has("hp")), "ai") -- false
  lurek.log.debug("mp still present: " .. tostring(bb:has("mp")), "ai") -- true
end

-- ---- Stub: LAIBlackboard:clear -------------------------------------------
--@api-stub: LAIBlackboard:clear
-- Removes every local entry from this blackboard.
do
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("gold", 500)
  bb:setString("name", "hero")
  -- Wipe all entries.
  bb:clear()
  lurek.log.debug("after clear, has 'gold': " .. tostring(bb:has("gold")), "ai") -- false
end

-- ---- Stub: LAIBlackboard:type --------------------------------------------
--@api-stub: LAIBlackboard:type
-- Returns the Lua-visible type name for this blackboard handle.
do
  local obj = lurek.ai.newBlackboard()
  lurek.log.debug("type: " .. obj:type(), "example") -- "LAIBlackboard"
end

-- ---- Stub: LAIBlackboard:typeOf ------------------------------------------
--@api-stub: LAIBlackboard:typeOf
-- Returns whether this blackboard handle matches a supported type name.
do
  local obj = lurek.ai.newBlackboard()
  lurek.log.debug("typeOf LAIBlackboard: " .. tostring(obj:typeOf("LAIBlackboard")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LAIDirector methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAIDirector:type ----------------------------------------------
--@api-stub: LAIDirector:type
-- Returns the Lua-visible type name for this AI director handle.
do
  local obj = lurek.ai.newBehaviorTree()
  lurek.log.debug("type: " .. obj:type(), "example") -- "LBehaviorTree"
end

-- ---- Stub: LAIDirector:typeOf --------------------------------------------
--@api-stub: LAIDirector:typeOf
-- Returns whether this AI director handle matches a supported type name.
do
  local obj = lurek.ai.newBehaviorTree()
  lurek.log.debug("typeOf LBehaviorTree: " .. tostring(obj:typeOf("LBehaviorTree")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LBandit methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LBandit:type --------------------------------------------------
--@api-stub: LBandit:type
-- Returns the Lua-visible type name for this bandit handle.
do
  local obj = lurek.ai.newBandit(4, 'ucb1', 0.1, 99)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LBandit"
end

-- ---- Stub: LBandit:typeOf ------------------------------------------------
--@api-stub: LBandit:typeOf
-- Returns whether this bandit handle matches a supported type name.
do
  local obj = lurek.ai.newBandit(4, 'ucb1', 0.1, 99)
  lurek.log.debug("typeOf LBandit: " .. tostring(obj:typeOf("LBandit")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LContextSteering methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LContextSteering:type -----------------------------------------
--@api-stub: LContextSteering:type
-- Returns the Lua-visible type name for this context steering handle.
do
  local obj = lurek.ai.newContextSteering(16)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LContextSteering"
end

-- ---- Stub: LContextSteering:typeOf ---------------------------------------
--@api-stub: LContextSteering:typeOf
-- Returns whether this context steering handle matches a supported type name.
do
  local obj = lurek.ai.newContextSteering(16)
  lurek.log.debug("typeOf LContextSteering: " .. tostring(obj:typeOf("LContextSteering")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LDialogueAI methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LDialogueAI:type ----------------------------------------------
--@api-stub: LDialogueAI:type
-- Returns the Lua-visible type name for this dialogue AI handle.
do
  local obj = lurek.ai.newDialogueAI()
  lurek.log.debug("type: " .. obj:type(), "example") -- "LDialogueAI"
end

-- ---- Stub: LDialogueAI:typeOf --------------------------------------------
--@api-stub: LDialogueAI:typeOf
-- Returns whether this dialogue AI handle matches a supported type name.
do
  local obj = lurek.ai.newDialogueAI()
  lurek.log.debug("typeOf LDialogueAI: " .. tostring(obj:typeOf("LDialogueAI")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LEmotionModel methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LEmotionModel:type --------------------------------------------
--@api-stub: LEmotionModel:type
-- Returns the Lua-visible type name for this emotion model handle.
do
  local obj = lurek.ai.newEmotionModel()
  lurek.log.debug("type: " .. obj:type(), "example") -- "LEmotionModel"
end

-- ---- Stub: LEmotionModel:typeOf ------------------------------------------
--@api-stub: LEmotionModel:typeOf
-- Returns whether this emotion model handle matches a supported type name.
do
  local obj = lurek.ai.newEmotionModel()
  lurek.log.debug("typeOf LEmotionModel: " .. tostring(obj:typeOf("LEmotionModel")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LGeneticAlgorithm methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LGeneticAlgorithm:type ----------------------------------------
--@api-stub: LGeneticAlgorithm:type
-- Returns the Lua-visible type name for this genetic algorithm handle.
do
  local obj = lurek.ai.newGeneticAlgorithm(50, 16, 42)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LGeneticAlgorithm"
end

-- ---- Stub: LGeneticAlgorithm:typeOf --------------------------------------
--@api-stub: LGeneticAlgorithm:typeOf
-- Returns whether this genetic algorithm handle matches a supported type name.
do
  local obj = lurek.ai.newGeneticAlgorithm(50, 16, 42)
  lurek.log.debug("typeOf LGeneticAlgorithm: " .. tostring(obj:typeOf("LGeneticAlgorithm")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LHTNDomain methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LHTNDomain:type -----------------------------------------------
--@api-stub: LHTNDomain:type
-- Returns the Lua-visible type name for this HTN domain handle.
do
  local obj = lurek.ai.newHTNDomain()
  lurek.log.debug("type: " .. obj:type(), "example") -- "LHTNDomain"
end

-- ---- Stub: LHTNDomain:typeOf ---------------------------------------------
--@api-stub: LHTNDomain:typeOf
-- Returns whether this HTN domain handle matches a supported type name.
do
  local obj = lurek.ai.newHTNDomain()
  lurek.log.debug("typeOf LHTNDomain: " .. tostring(obj:typeOf("LHTNDomain")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LMCTSEngine methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMCTSEngine:type ----------------------------------------------
--@api-stub: LMCTSEngine:type
-- Returns the Lua-visible type name for this MCTS engine handle.
do
  local obj = lurek.ai.newMCTSEngine(200, 1.41, 32, 12345)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LMCTSEngine"
end

-- ---- Stub: LMCTSEngine:typeOf --------------------------------------------
--@api-stub: LMCTSEngine:typeOf
-- Returns whether this MCTS engine handle matches a supported type name.
do
  local obj = lurek.ai.newMCTSEngine(200, 1.41, 32, 12345)
  lurek.log.debug("typeOf LMCTSEngine: " .. tostring(obj:typeOf("LMCTSEngine")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LNeedSystem methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LNeedSystem:type ----------------------------------------------
--@api-stub: LNeedSystem:type
-- Returns the Lua-visible type name for this need system handle.
do
  local obj = lurek.ai.newNeedSystem()
  lurek.log.debug("type: " .. obj:type(), "example") -- "LNeedSystem"
end

-- ---- Stub: LNeedSystem:typeOf --------------------------------------------
--@api-stub: LNeedSystem:typeOf
-- Returns whether this need system handle matches a supported type name.
do
  local obj = lurek.ai.newNeedSystem()
  lurek.log.debug("typeOf LNeedSystem: " .. tostring(obj:typeOf("LNeedSystem")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LNeuralNet methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LNeuralNet:type -----------------------------------------------
--@api-stub: LNeuralNet:type
-- Returns the Lua-visible type name for this neural network handle.
do
  local obj = lurek.ai.newNeuralNet()
  lurek.log.debug("type: " .. obj:type(), "example") -- "LNeuralNet"
end

-- ---- Stub: LNeuralNet:typeOf ---------------------------------------------
--@api-stub: LNeuralNet:typeOf
-- Returns whether this neural network handle matches a supported type name.
do
  local obj = lurek.ai.newNeuralNet()
  lurek.log.debug("typeOf LNeuralNet: " .. tostring(obj:typeOf("LNeuralNet")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LNeuroevolution methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LNeuroevolution:type ------------------------------------------
--@api-stub: LNeuroevolution:type
-- Returns the Lua-visible type name for this neuroevolution handle.
do
  local obj = lurek.ai.newNeuroevolution({{inputs=2,outputs=4},{inputs=4,outputs=1}}, 30, 1)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LNeuroevolution"
end

-- ---- Stub: LNeuroevolution:typeOf ----------------------------------------
--@api-stub: LNeuroevolution:typeOf
-- Returns whether this neuroevolution handle matches a supported type name.
do
  local obj = lurek.ai.newNeuroevolution({{inputs=2,outputs=4},{inputs=4,outputs=1}}, 30, 1)
  lurek.log.debug("typeOf LNeuroevolution: " .. tostring(obj:typeOf("LNeuroevolution")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LORCASolver methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LORCASolver:type ----------------------------------------------
--@api-stub: LORCASolver:type
-- Returns the Lua-visible type name for this ORCA solver handle.
do
  local obj = lurek.ai.newORCASolver(2.0)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LORCASolver"
end

-- ---- Stub: LORCASolver:typeOf --------------------------------------------
--@api-stub: LORCASolver:typeOf
-- Returns whether this ORCA solver handle matches a supported type name.
do
  local obj = lurek.ai.newORCASolver(2.0)
  lurek.log.debug("typeOf LORCASolver: " .. tostring(obj:typeOf("LORCASolver")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LStimulusWorld methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LStimulusWorld:type -------------------------------------------
--@api-stub: LStimulusWorld:type
-- Returns the Lua-visible type name for this stimulus world handle.
do
  local obj = lurek.ai.newStimulusWorld()
  lurek.log.debug("type: " .. obj:type(), "example") -- "LStimulusWorld"
end

-- ---- Stub: LStimulusWorld:typeOf -----------------------------------------
--@api-stub: LStimulusWorld:typeOf
-- Returns whether this stimulus world handle matches a supported type name.
do
  local obj = lurek.ai.newStimulusWorld()
  lurek.log.debug("typeOf LStimulusWorld: " .. tostring(obj:typeOf("LStimulusWorld")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LStrategyAI methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LStrategyAI:type ----------------------------------------------
--@api-stub: LStrategyAI:type
-- Returns the Lua-visible type name for this strategy AI handle.
do
  local obj = lurek.ai.newStrategyAI(2.0)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LStrategyAI"
end

-- ---- Stub: LStrategyAI:typeOf --------------------------------------------
--@api-stub: LStrategyAI:typeOf
-- Returns whether this strategy AI handle matches a supported type name.
do
  local obj = lurek.ai.newStrategyAI(2.0)
  lurek.log.debug("typeOf LStrategyAI: " .. tostring(obj:typeOf("LStrategyAI")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LTraitProfile methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTraitProfile:type --------------------------------------------
--@api-stub: LTraitProfile:type
-- Returns the Lua-visible type name for this trait profile handle.
do
  local obj = lurek.ai.newTraitProfile()
  lurek.log.debug("type: " .. obj:type(), "example") -- "LTraitProfile"
end

-- ---- Stub: LTraitProfile:typeOf ------------------------------------------
--@api-stub: LTraitProfile:typeOf
-- Returns whether this trait profile handle matches a supported type name.
do
  local obj = lurek.ai.newTraitProfile()
  lurek.log.debug("typeOf LTraitProfile: " .. tostring(obj:typeOf("LTraitProfile")), "example") -- true
end
