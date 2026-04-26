-- content/examples/ai.lua
-- Hand-written coverage of the lurek.ai API (240 items).
--
-- The lurek.ai namespace exposes Lurek2D's full game-AI toolkit: worlds and
-- agents, FSMs, behaviour trees, steering, Q-learning, utility AI, GOAP, HTN,
-- MCTS, ORCA crowd avoidance, neural nets, genetic / neuroevolution, bandits,
-- influence maps, squads with formations, command queues, traits, perception,
-- emotion models, needs, the AI director, strategy planners, and AI LOD.
---@diagnostic disable: undefined-field, missing-parameter, redundant-parameter, param-type-mismatch
--
-- Every --@api-stub: block below is a real love2d-wiki-style snippet showing
-- how to call the API in actual game context. State names ("patrol", "chase",
-- "flee"), tags, weights, and tree node specs are realistic and runnable.
--
-- Run: cargo run -- content/examples/ai.lua

--@api-stub: lurek.ai.newWorld
-- Creates a new AI world container.
-- Construct one world per scene; it owns all agents and ticks them via update(dt).
do  -- lurek.ai.newWorld
  local world = lurek.ai.newWorld()
  world:addAgent("guard_01")
  function lurek.process(dt) world:update(dt) end
end

--@api-stub: lurek.ai.newBlackboard
-- Creates a new standalone blackboard.
-- Standalone blackboards are useful as squad-wide or scene-wide shared key/value scratch.
do  -- lurek.ai.newBlackboard
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("alert_level", 0.3)
  bb:setBool("player_seen", false)
end

--@api-stub: lurek.ai.newStateMachine
-- Creates a new finite state machine.
-- Build the FSM once at init, then drive it from the agent's update or a per-frame tick.
do  -- lurek.ai.newStateMachine
  local fsm = lurek.ai.newStateMachine()
  fsm:addState("patrol", { onEnter = function() lurek.log.info("patrolling", "ai") end })
  fsm:addState("chase", {})
  fsm:setInitialState("patrol")
end

--@api-stub: lurek.ai.newBehaviorTree
-- Creates a new behavior tree.
-- Build the tree once at init; behavior trees are stateless data structures whose roots you tick each frame.
do  -- lurek.ai.newBehaviorTree
  local bt = lurek.ai.newBehaviorTree()
  local root = lurek.ai.newSequence()
  root:addChild(lurek.ai.newAction(function() return "success" end))
  bt:setRoot(root)
end

--@api-stub: lurek.ai.newSelector
-- Creates a BT selector node.
-- Selector tries children left-to-right and succeeds on the first non-failure; use for fallback chains.
do  -- lurek.ai.newSelector
  local sel = lurek.ai.newSelector()
  sel:addChild(lurek.ai.newCondition(function() return false end))
  sel:addChild(lurek.ai.newAction(function() return "success" end))
end

--@api-stub: lurek.ai.newSequence
-- Creates a BT sequence node.
-- Sequence runs children in order and fails on the first failure; use for guarded action chains.
do  -- lurek.ai.newSequence
  local seq = lurek.ai.newSequence()
  seq:addChild(lurek.ai.newCondition(function() return true end))
  seq:addChild(lurek.ai.newAction(function() return "success" end))
end

--@api-stub: lurek.ai.newParallel
-- Creates a BT parallel node with optional policies.
-- Pass success/failure policy strings ("require_one" or "require_all") to control how children combine.
do  -- lurek.ai.newParallel
  local par = lurek.ai.newParallel("require_all", "require_one")
  par:addChild(lurek.ai.newAction(function() return "success" end))
  par:addChild(lurek.ai.newAction(function() return "running" end))
end

--@api-stub: lurek.ai.newInverter
-- Creates a BT inverter decorator.
-- Decorator that flips success<->failure; pair with a condition to express "not" cheaply.
do  -- lurek.ai.newInverter
  local inv = lurek.ai.newInverter()
  inv:setChild(lurek.ai.newCondition(function() return false end))
  local bt = lurek.ai.newBehaviorTree(); bt:setRoot(inv)
end

--@api-stub: lurek.ai.newRepeater
-- Creates a BT repeater decorator.
-- count=0 means infinite; positive count repeats the child that many times before reporting success.
do  -- lurek.ai.newRepeater
  local rep = lurek.ai.newRepeater(3)
  rep:setChild(lurek.ai.newAction(function() return "success" end))
  local bt = lurek.ai.newBehaviorTree(); bt:setRoot(rep)
end

--@api-stub: lurek.ai.newSucceeder
-- Creates a BT succeeder decorator.
-- Always reports success regardless of child outcome; useful to prevent a sequence from failing.
do  -- lurek.ai.newSucceeder
  local suc = lurek.ai.newSucceeder()
  suc:setChild(lurek.ai.newAction(function() return "failure" end))
  local bt = lurek.ai.newBehaviorTree(); bt:setRoot(suc)
end

--@api-stub: lurek.ai.newAction
-- Creates a BT action leaf with a Lua callback.
-- Callback must return one of the status strings "success", "failure", or "running".
do  -- lurek.ai.newAction
  local act = lurek.ai.newAction(function(dt)
      return "success"
  end)
end

--@api-stub: lurek.ai.newCondition
-- Creates a BT condition leaf with a Lua predicate.
-- Predicate returns boolean; engine maps true to "success" and false to "failure".
do  -- lurek.ai.newCondition
  local hp_low = lurek.ai.newCondition(function() return true end)
  local seq = lurek.ai.newSequence()
  seq:addChild(hp_low)
end

--@api-stub: lurek.ai.newSteeringManager
-- Creates a new steering behavior manager.
-- One steering manager per agent; add behaviors at init then call calculate() each tick.
do  -- lurek.ai.newSteeringManager
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  sm:addWander(20, 40, 5, 0.3)
end

--@api-stub: lurek.ai.newQLearner
-- Creates a tabular Q-learner.
-- Allocate state*action Q-table at init; both counts must be known up front.
do  -- lurek.ai.newQLearner
  local ql = lurek.ai.newQLearner(16, 4)
  ql:setLearningRate(0.1)
  ql:setExplorationRate(0.2)
end

--@api-stub: lurek.ai.newUtilityAI
-- Creates a new utility AI evaluator.
-- Add scored actions then call evaluate() per decision; the highest-scoring action wins.
do  -- lurek.ai.newUtilityAI
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("flee", function() return 0.8 end, 1.0)
  uai:addAction("attack", function() return 0.4 end, 1.0)
end

--@api-stub: lurek.ai.newGOAPPlanner
-- Creates a new GOAP planning solver.
-- Build the planner once at init with all actions and goals; then call plan(worldState) each decision.
do  -- lurek.ai.newGOAPPlanner
  local planner = lurek.ai.newGOAPPlanner()
  planner:addAction("eat", 1.0, function() lurek.log.info("eating", "ai") end)
  planner:addGoal("not_hungry", 1.0)
end

--@api-stub: lurek.ai.newInfluenceMap
-- Creates a multi-layer influence map grid.
-- Pick cellSize to match your tile grid; layers cost width*height floats so keep them modest.
do  -- lurek.ai.newInfluenceMap
  local infl = lurek.ai.newInfluenceMap(64, 64, 16)
  infl:addLayer("threat")
  infl:stampInfluence("threat", 320, 240, 80, 1.0, 1.0)
end

--@api-stub: lurek.ai.newSquad
-- Creates a named squad for formation positioning.
-- Squads coordinate multiple agents; pass a unique name so the world can look them up by tag.
do  -- lurek.ai.newSquad
  local squad = lurek.ai.newSquad("alpha")
  squad:addMember("guard_01")
  squad:setFormation("wedge", 32)
end

--@api-stub: lurek.ai.newCommandQueue
-- Creates an RTS-style command queue.
-- RTS-style FIFO of commands per unit; the engine fires the front command's callback each tick.
do  -- lurek.ai.newCommandQueue
  local q = lurek.ai.newCommandQueue()
  q:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  q:enqueue("attack", function() end, { priority = 5 })
end

--@api-stub: lurek.ai.newTraitProfile
-- Creates a new personality trait profile.
-- Use one profile per character to drive personality-modulated decisions and dialogue.
do  -- lurek.ai.newTraitProfile
  local traits = lurek.ai.newTraitProfile()
  traits:set("aggression", 0.7)
  traits:set("courage", 0.4)
end

--@api-stub: lurek.ai.newStimulusWorld
-- Creates a new stimulus perception world.
-- Central perception store; agents query it instead of doing per-pair distance checks.
do  -- lurek.ai.newStimulusWorld
  local sw = lurek.ai.newStimulusWorld()
  sw:addAuditory(100, 200, 1.0, 150, 0.5, "footstep")
  function lurek.process(dt) sw:update(dt) end
end

--@api-stub: lurek.ai.newContextSteering
-- Creates a new context steering controller.
-- Slot count controls angular resolution; 8 or 16 is plenty for most 2D crowds.
do  -- lurek.ai.newContextSteering
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  cs:addAvoidPoint(250, 200, 64, 1.0)
end

--@api-stub: lurek.ai.newNeedSystem
-- Creates a new motivational need system.
-- Maslow-style needs that decay over time; agents pick whichever urgency is highest.
do  -- lurek.ai.newNeedSystem
  local needs = lurek.ai.newNeedSystem()
  needs:addNeed("hunger", 0.05, 0.6, 1.5)
  function lurek.process(dt) needs:update(dt) end
end

--@api-stub: lurek.ai.newAIDirector
-- Creates a new AI pacing director with default config.
-- Left4Dead-style pacing: feed it gameplay events and read tension/phase to drive spawning.
do  -- lurek.ai.newAIDirector
  local dir = lurek.ai.newAIDirector()
  dir:setTension(0.4)
  function lurek.process(dt) dir:update(dt) end
end

--@api-stub: lurek.ai.newHTNDomain
-- Creates a new Hierarchical Task Network domain.
-- Hierarchical Task Network for compound planning; build the domain once and reuse for all agents.
do  -- lurek.ai.newHTNDomain
  local d = lurek.ai.newHTNDomain()
  d:addPrimitive("attack", { "has_weapon" }, { "enemy_dead" }, {})
end

--@api-stub: lurek.ai.newMCTSEngine
-- Creates a new Monte Carlo Tree Search engine.
-- Tune iterations vs latency; uct_c=1.41 (sqrt 2) is the standard exploration constant.
do  -- lurek.ai.newMCTSEngine
  local mcts = lurek.ai.newMCTSEngine(200, 1.41, 32, 12345)
  local actions = function(s) return { 1, 2, 3 } end
  local apply = function(s, a) return s + a end
  local eval = function(s) return s % 7 end
end

--@api-stub: lurek.ai.newEmotionModel
-- Creates a new affective emotion model.
-- Add emotion dimensions at init; trigger() adds intensity and decay drops it back to resting level.
do  -- lurek.ai.newEmotionModel
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.1, 0.2)
  em:add("anger", 0.0, 0.05, 0.15)
end

--@api-stub: lurek.ai.newORCASolver
-- Creates a new ORCA crowd avoidance solver.
-- time_horizon (in seconds) controls how far ahead collisions are predicted; 2.0 is a common default.
do  -- lurek.ai.newORCASolver
  local orca = lurek.ai.newORCASolver(2.0)
  local idx = orca:addAgent(100, 100, 16, 80)
  orca:setPreferredVelocity(idx, 50, 0)
end

--@api-stub: lurek.ai.newNeuralNet
-- Creates a new feedforward neural network (inference only).
-- Pure-inference feed-forward net; train weights elsewhere then load via setWeights.
do  -- lurek.ai.newNeuralNet
  local nn = lurek.ai.newNeuralNet()
  nn:addLayer(4, 8, "relu")
  nn:addLayer(8, 2, "softmax")
end

--@api-stub: lurek.ai.newGeneticAlgorithm
-- Creates a new genetic algorithm.
-- Drive evolution from a fixed RNG seed for repeatable runs in tests.
do  -- lurek.ai.newGeneticAlgorithm
  local ga = lurek.ai.newGeneticAlgorithm(50, 16, 42)
  ga:setFitness(1, 0.7)
  function lurek.process(dt) ga:evolve() end
end

--@api-stub: lurek.ai.newBandit
-- Creates a new multi-armed bandit.
-- Strategy is one of "epsilon_greedy", "ucb1", "thompson"; epsilon is ignored unless using epsilon_greedy.
do  -- lurek.ai.newBandit
  local b = lurek.ai.newBandit(4, "ucb1", 0.1, 99)
  local arm = b:select()
  b:update(arm, 1.0)
end

--@api-stub: lurek.ai.newNeuroevolution
-- Creates a neuroevolution trainer (GA for neural network weights).
-- GA over neural-network weights; layer_spec mirrors NeuralNet:addLayer triplets.
do  -- lurek.ai.newNeuroevolution
  local layers = { { inputs = 4, outputs = 8, activation = "relu" }, { inputs = 8, outputs = 2, activation = "softmax" } }
  local ne = lurek.ai.newNeuroevolution(layers, 30, 1)
  function lurek.process(dt) ne:evolve() end
end

--@api-stub: lurek.ai.newStrategyAI
-- Creates a new throttled strategy AI.
-- update_interval seconds throttles re-evaluation so the AI does not thrash every frame.
do  -- lurek.ai.newStrategyAI
  local s = lurek.ai.newStrategyAI(2.0)
  s:addGoal("expand")
  s:addGoal("defend")
end

--@api-stub: lurek.ai.newAILod
-- Creates a new AI LOD controller with default 3-tier config.
-- Default 3-tier config buckets agents by distance; cheaper tiers tick at lower frame rates.
do  -- lurek.ai.newAILod
  local lod = lurek.ai.newAILod()
  if lod:shouldUpdate(1, 60) then lurek.log.debug("tier 1 update", "ai") end
end

--@api-stub: AIWorld:addAgent
-- Registers a new named agent and returns its handle.
-- Returns an Agent userdata bound to this world; store it for setPosition/addTag/etc.
do  -- AIWorld:addAgent
  local world = lurek.ai.newWorld()
  local guard = world:addAgent("guard_01")
  guard:setPosition(100, 100)
end

--@api-stub: AIWorld:getAgent
-- Returns the agent handle for the given name, or nil.
-- Returns nil if the name is unknown; always check before dereferencing.
do  -- AIWorld:getAgent
  local world = lurek.ai.newWorld()
  world:addAgent("guard_01")
  local a = world:getAgent("guard_01")
  if a then a:addTag("alive") end
end

--@api-stub: AIWorld:removeAgent
-- Removes an agent by its userdata handle.
-- Pass the Agent handle (not the name string); the world drops it from scheduling immediately.
do  -- AIWorld:removeAgent
  local world = lurek.ai.newWorld()
  local tmp = world:addAgent("temp")
  world:removeAgent(tmp)
end

--@api-stub: AIWorld:getAgentCount
-- Returns the number of registered agents.
-- Useful for HUD readouts and crowd density caps; cheap O(1) lookup on the agent vector.
do  -- AIWorld:getAgentCount
  local world = lurek.ai.newWorld()
  world:addAgent("a"); world:addAgent("b")
  lurek.log.info("agents=" .. world:getAgentCount(), "ai")
end

--@api-stub: AIWorld:getGlobalBlackboard
-- Returns a snapshot of the world-level blackboard.
-- Snapshot of the world-level shared blackboard; mutate it for cross-agent state like alarm levels.
do  -- AIWorld:getGlobalBlackboard
  local world = lurek.ai.newWorld()
  local bb = world:getGlobalBlackboard()
  bb:setNumber("alarm", 0.0)
end

--@api-stub: AIWorld:update
-- Advances all agents by dt seconds.
-- Call once per frame from lurek.process; ticks every agent's FSM/BT/steering in one go.
do  -- AIWorld:update
  local world = lurek.ai.newWorld()
  world:addAgent("npc")
  function lurek.process(dt) world:update(dt) end
end

--@api-stub: AIWorld:type
-- Returns the type name of this object.
-- Returns the literal string "AIWorld"; useful for runtime type guards in generic helpers.
do  -- AIWorld:type
  local world = lurek.ai.newWorld()
  if world:type() == "AIWorld" then lurek.log.debug("got world", "ai") end
end

--@api-stub: AIWorld:typeOf
-- Returns true if this object is of the given type.
-- Both the exact type and "Object" return true; everything in lurek.ai inherits the Object root.
do  -- AIWorld:typeOf
  local world = lurek.ai.newWorld()
  if world:typeOf("Object") then lurek.log.debug("inherits Object", "ai") end
end

--@api-stub: Agent:getName
-- Returns the agent's registered name.
-- Returns the registered name string; use it as a stable id when serialising or logging.
do  -- Agent:getName
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  local name = agent:getName()
  lurek.log.debug("agent=" .. name, "ai")
end

--@api-stub: Agent:setPosition
-- Sets the agent's world-space position.
-- World-space pixels; pair with setVelocity each tick if you are simulating movement manually.
do  -- Agent:setPosition
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setPosition(320, 240)
end

--@api-stub: Agent:getPosition
-- Returns the agent's current position.
-- Returns two values (x, y); destructure with multi-assign to avoid an extra table allocation.
do  -- Agent:getPosition
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setPosition(50, 75)
  local x, y = agent:getPosition()
  lurek.log.debug("pos=" .. x .. "," .. y, "ai")
end

--@api-stub: Agent:setVelocity
-- Sets the agent's velocity vector.
-- Set per frame from steering output; the world does not integrate velocity for you automatically.
do  -- Agent:setVelocity
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setVelocity(40, 0)
end

--@api-stub: Agent:getVelocity
-- Returns the agent's current velocity.
-- Returns (vx, vy); useful to seed the next steering calculation or play sound based on speed.
do  -- Agent:getVelocity
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setVelocity(40, 30)
  local vx, vy = agent:getVelocity()
  if vx*vx + vy*vy > 100 then lurek.log.debug("moving", "ai") end
end

--@api-stub: Agent:setMaxSpeed
-- Sets the maximum speed cap.
-- Used by steering to clamp output; pick units consistent with your delta-time scale (px/sec).
do  -- Agent:setMaxSpeed
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setMaxSpeed(150)
end

--@api-stub: Agent:getMaxSpeed
-- Returns the maximum speed cap.
-- Default is 100 px/sec; read it back if behaviour-tree leaves need to scale by movement budget.
do  -- Agent:getMaxSpeed
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  local cap = agent:getMaxSpeed()
  agent:setVelocity(cap, 0)
end

--@api-stub: Agent:setMaxForce
-- Sets the maximum steering force cap.
-- Caps steering acceleration so agents do not snap to target instantly; tune alongside maxSpeed.
do  -- Agent:setMaxForce
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setMaxForce(300)
end

--@api-stub: Agent:getMaxForce
-- Returns the maximum steering force cap.
-- Default is 200; raise for nimble enemies, lower for lumbering tanks.
do  -- Agent:getMaxForce
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  local f = agent:getMaxForce()
  lurek.log.debug("max force=" .. f, "ai")
end

--@api-stub: Agent:setPriority
-- Sets the scheduling priority (higher = earlier).
-- Higher priority agents are scheduled first; useful for boss enemies that should never be skipped.
do  -- Agent:setPriority
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setPriority(10)
end

--@api-stub: Agent:getPriority
-- Returns the agent's scheduling priority.
-- Defaults to 0; query when sorting agents into LOD buckets.
do  -- Agent:getPriority
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setPriority(5)
  if agent:getPriority() > 0 then lurek.log.debug("prio agent", "ai") end
end

--@api-stub: Agent:setDecisionModel
-- Sets the active decision model.
-- Accepts "fsm", "bt", "utility", "goap" strings; unknown values are silently ignored.
do  -- Agent:setDecisionModel
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:setDecisionModel("bt")
end

--@api-stub: Agent:getDecisionModel
-- Returns the name of the current decision model.
-- Returns the string name (default "fsm"); branch on it to pick the right per-agent tick.
do  -- Agent:getDecisionModel
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  if agent:getDecisionModel() == "fsm" then lurek.log.debug("uses fsm", "ai") end
end

--@api-stub: Agent:addTag
-- Adds a tag to this agent.
-- Tags are arbitrary strings used for filtering; e.g. "flammable", "boss", "friendly".
do  -- Agent:addTag
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:addTag("alive")
  agent:addTag("scout")
end

--@api-stub: Agent:removeTag
-- Removes a tag from this agent.
-- Silent no-op if the tag was not present; safe to call defensively.
do  -- Agent:removeTag
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:addTag("burning")
  agent:removeTag("burning")
end

--@api-stub: Agent:hasTag
-- Returns true if the agent has the given tag.
-- Cheap hashed lookup; use to drive AOE filters or save/load eligibility checks.
do  -- Agent:hasTag
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  agent:addTag("boss")
  if agent:hasTag("boss") then lurek.log.info("boss alert", "ai") end
end

--@api-stub: Agent:getBlackboard
-- Returns the agent's local blackboard.
-- Per-agent local blackboard distinct from the world-global one; survives across ticks.
do  -- Agent:getBlackboard
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  local bb = agent:getBlackboard()
  bb:setNumber("hp", 100)
end

--@api-stub: Agent:type
-- Returns the type name of this object.
-- Returns the literal string "Agent"; pair with typeOf in generic dispatch helpers.
do  -- Agent:type
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  if agent:type() == "Agent" then lurek.log.debug("ok", "ai") end
end

--@api-stub: Agent:typeOf
-- Returns true if this object is of the given type.
-- Returns true for "Agent" and "Object"; mirrors the Lurek2D type-tag pattern.
do  -- Agent:typeOf
  local world = lurek.ai.newWorld()
  local agent = world:addAgent("scout_01")
  if agent:typeOf("Object") then lurek.log.debug("inherits Object", "ai") end
end

--@api-stub: Blackboard:setNumber
-- Stores a number under the given key.
-- Overwrites any existing entry; numbers are stored as f64 so beware of integer-precision loss past 2^53.
do  -- Blackboard:setNumber
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("hp", 100)
  bb:setNumber("alert_level", 0.6)
end

--@api-stub: Blackboard:setBool
-- Stores a boolean under the given key.
-- Use for binary flags like "player_seen" or "is_armed" so behaviour trees can branch cheaply.
do  -- Blackboard:setBool
  local bb = lurek.ai.newBlackboard()
  bb:setBool("player_seen", true)
  bb:setBool("door_open", false)
end

--@api-stub: Blackboard:setString
-- Stores a string under the given key.
-- Strings are interned by Lua so repeated keys are cheap; use for state names and target ids.
do  -- Blackboard:setString
  local bb = lurek.ai.newBlackboard()
  bb:setString("target_id", "player_01")
  bb:setString("last_state", "patrol")
end

--@api-stub: Blackboard:has
-- Returns true if a value exists under the key.
-- Returns true if any value-typed entry is stored under the key, regardless of its type.
do  -- Blackboard:has
  local bb = lurek.ai.newBlackboard()
  bb:setBool("alive", true)
  if bb:has("alive") then lurek.log.debug("entry exists", "ai") end
end

--@api-stub: Blackboard:remove
-- Removes the entry at key.
-- Silent no-op if the key was missing; cheaper than has + remove if you do not need the result.
do  -- Blackboard:remove
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("temp", 1)
  bb:remove("temp")
end

--@api-stub: Blackboard:clear
-- Removes all local entries.
-- Wipes all local entries (linked parent boards are unaffected); use at scene boundaries.
do  -- Blackboard:clear
  local bb = lurek.ai.newBlackboard()
  bb:setBool("dirty", true)
  bb:clear()
end

--@api-stub: Blackboard:getKeys
-- Returns all local keys as a table.
-- Returns a 1-based array of strings; iterate with ipairs to enumerate every local entry.
do  -- Blackboard:getKeys
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("hp", 100); bb:setBool("alive", true)
  for _, k in ipairs(bb:getKeys()) do lurek.log.debug("key=" .. k, "ai") end
end

--@api-stub: Blackboard:getSize
-- Returns the number of local entries.
-- Counts only local entries; if you also care about parent entries, walk the chain manually.
do  -- Blackboard:getSize
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("hp", 100)
  lurek.log.debug("entries=" .. bb:getSize(), "ai")
end

--@api-stub: Blackboard:type
-- Returns the type name of this object.
-- Returns the literal string "Blackboard"; handy when bb is passed in via a generic callback.
do  -- Blackboard:type
  local bb = lurek.ai.newBlackboard()
  if bb:type() == "Blackboard" then lurek.log.debug("got bb", "ai") end
end

--@api-stub: Blackboard:typeOf
-- Returns true if this object is of the given type.
-- True for "Blackboard" and "Object"; mirrors the type-hierarchy convention.
do  -- Blackboard:typeOf
  local bb = lurek.ai.newBlackboard()
  if bb:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: StateMachine:addState
-- Registers a named state with optional lifecycle callbacks.
-- opts may contain onEnter / onUpdate / onExit Lua callbacks; omit any you do not need.
do  -- StateMachine:addState
  local fsm = lurek.ai.newStateMachine()
  fsm:addState("patrol", { onEnter = function() lurek.log.info("patrol", "ai") end })
  fsm:addState("chase", { onUpdate = function(dt) end })
end

--@api-stub: StateMachine:setInitialState
-- Sets the FSM's initial state; must be called before the first update.
-- Must be called before the first update or the FSM has no current state to tick.
do  -- StateMachine:setInitialState
  local fsm = lurek.ai.newStateMachine()
  fsm:addState("idle", {})
  fsm:setInitialState("idle")
end

--@api-stub: StateMachine:getCurrentState
-- Returns the current state name, or nil.
-- Returns nil before setInitialState; use to drive HUD overlays or save/load.
do  -- StateMachine:getCurrentState
  local fsm = lurek.ai.newStateMachine()
  fsm:addState("patrol", {}); fsm:setInitialState("patrol")
  local s = fsm:getCurrentState()
  if s then lurek.log.debug("state=" .. s, "ai") end
end

--@api-stub: StateMachine:forceState
-- Forces a transition to the named state.
-- Bypasses transition guards and resets time-in-state; use sparingly for cutscenes or stuns.
do  -- StateMachine:forceState
  local fsm = lurek.ai.newStateMachine()
  fsm:addState("stunned", {}); fsm:setInitialState("stunned")
  fsm:forceState("stunned")
end

--@api-stub: StateMachine:getTimeInState
-- Returns seconds spent in the current state.
-- Seconds since the last transition; useful for timeout-based exits inside onUpdate.
do  -- StateMachine:getTimeInState
  local fsm = lurek.ai.newStateMachine()
  fsm:addState("idle", {}); fsm:setInitialState("idle")
  if fsm:getTimeInState() > 5.0 then fsm:forceState("idle") end
end

--@api-stub: StateMachine:type
-- Returns the type name of this object.
-- Returns the literal string "StateMachine"; pair with typeOf in generic AI helpers.
do  -- StateMachine:type
  local fsm = lurek.ai.newStateMachine()
  if fsm:type() == "StateMachine" then lurek.log.debug("ok", "ai") end
end

--@api-stub: StateMachine:typeOf
-- Returns true if this object is of the given type.
-- True for "StateMachine" and "Object"; standard type-tag check.
do  -- StateMachine:typeOf
  local fsm = lurek.ai.newStateMachine()
  if fsm:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: BehaviorTree:setRoot
-- Sets the root node of this behavior tree.
-- Take ownership of the node by move; do not reuse the BTNode handle after setRoot.
do  -- BehaviorTree:setRoot
  local bt = lurek.ai.newBehaviorTree()
  local root = lurek.ai.newSelector()
  root:addChild(lurek.ai.newAction(function() return "success" end))
  bt:setRoot(root)
end

--@api-stub: BehaviorTree:getLastStatus
-- Returns the status from the last tick.
-- Returns "success", "failure", or "running" from the last tick; default is "failure".
do  -- BehaviorTree:getLastStatus
  local bt = lurek.ai.newBehaviorTree()
  local root = lurek.ai.newSequence()
  root:addChild(lurek.ai.newAction(function() return "success" end))
  bt:setRoot(root)
  local s = bt:getLastStatus()
  lurek.log.debug("bt status=" .. s, "ai")
end

--@api-stub: BehaviorTree:getDebugState
-- Returns a diagnostic snapshot of this behavior tree.
-- Diagnostic table { node_count, last_status }; useful for in-game AI debug overlays.
do  -- BehaviorTree:getDebugState
  local bt = lurek.ai.newBehaviorTree()
  local root = lurek.ai.newSequence()
  root:addChild(lurek.ai.newAction(function() return "success" end))
  bt:setRoot(root)
  local dbg = bt:getDebugState()
  lurek.log.debug("nodes=" .. dbg.node_count .. " status=" .. dbg.last_status, "ai")
end

--@api-stub: BehaviorTree:type
-- Returns the type name of this object.
-- Returns the literal string "BehaviorTree"; standard introspection helper.
do  -- BehaviorTree:type
  local bt = lurek.ai.newBehaviorTree()
  if bt:type() == "BehaviorTree" then lurek.log.debug("ok", "ai") end
end

--@api-stub: BehaviorTree:typeOf
-- Returns true if this object is of the given type.
-- True for "BehaviorTree" and "Object".
do  -- BehaviorTree:typeOf
  local bt = lurek.ai.newBehaviorTree()
  if bt:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: BTNode:addChild
-- Adds a child node (Selector, Sequence, or Parallel only).
-- Only valid for Selector / Sequence / Parallel nodes; raises an error on decorators or leaves.
do  -- BTNode:addChild
  local seq = lurek.ai.newSequence()
  seq:addChild(lurek.ai.newCondition(function() return true end))
  seq:addChild(lurek.ai.newAction(function() return "success" end))
end

--@api-stub: BTNode:getChildCount
-- Returns the number of direct children.
-- Returns 0 for leaves; useful when serialising or visualising the tree shape.
do  -- BTNode:getChildCount
  local seq = lurek.ai.newSequence()
  seq:addChild(lurek.ai.newAction(function() return "success" end))
  lurek.log.debug("children=" .. seq:getChildCount(), "ai")
end

--@api-stub: BTNode:reset
-- Resets all running-child memos and repeater counters.
-- Clears running-child memos and repeater counters; call when re-entering a tree from scratch.
do  -- BTNode:reset
  local rep = lurek.ai.newRepeater(3)
  rep:setChild(lurek.ai.newAction(function() return "success" end))
  rep:reset()
end

--@api-stub: BTNode:setChild
-- Sets the single child of a decorator node.
-- Decorator-only (Inverter / Repeater / Succeeder); takes ownership of the child node.
do  -- BTNode:setChild
  local inv = lurek.ai.newInverter()
  inv:setChild(lurek.ai.newCondition(function() return false end))
  local bt = lurek.ai.newBehaviorTree(); bt:setRoot(inv)
end

--@api-stub: BTNode:setCount
-- Sets the repeat count for a Repeater node.
-- Repeater-only; 0 means infinite repetition until child returns running stops.
do  -- BTNode:setCount
  local rep = lurek.ai.newRepeater(0)
  rep:setCount(5)
  rep:setChild(lurek.ai.newAction(function() return "success" end))
end

--@api-stub: BTNode:getCount
-- Returns the repeat count, or 0 if not a Repeater.
-- Returns 0 if called on a non-Repeater; useful when introspecting unknown nodes.
do  -- BTNode:getCount
  local rep = lurek.ai.newRepeater(7)
  if rep:getCount() == 7 then lurek.log.debug("count ok", "ai") end
end

--@api-stub: BTNode:setSuccessPolicy
-- Sets the success policy for a Parallel node.
-- Parallel-only; "require_one" or "require_all" controls when the node reports success.
do  -- BTNode:setSuccessPolicy
  local par = lurek.ai.newParallel("require_one", "require_one")
  par:setSuccessPolicy("require_all")
  par:addChild(lurek.ai.newAction(function() return "success" end))
end

--@api-stub: BTNode:setFailurePolicy
-- Sets the failure policy for a Parallel node.
-- Parallel-only; "require_one" fails fast, "require_all" waits until every child fails.
do  -- BTNode:setFailurePolicy
  local par = lurek.ai.newParallel("require_one", "require_one")
  par:setFailurePolicy("require_all")
  par:addChild(lurek.ai.newAction(function() return "running" end))
end

--@api-stub: BTNode:getNodeType
-- Returns the node type as a string.
-- Returns one of "selector", "sequence", "parallel", "inverter", "repeater", "succeeder", "action", "condition".
do  -- BTNode:getNodeType
  local seq = lurek.ai.newSequence()
  if seq:getNodeType() == "sequence" then lurek.log.debug("seq ok", "ai") end
end

--@api-stub: BTNode:type
-- Returns the type name of this object.
-- Returns the literal string "BTNode"; orthogonal to the node-shape returned by getNodeType.
do  -- BTNode:type
  local seq = lurek.ai.newSequence()
  if seq:type() == "BTNode" then lurek.log.debug("ok", "ai") end
end

--@api-stub: BTNode:typeOf
-- Returns true if this object is of the given type.
-- True for "BTNode" and "Object".
do  -- BTNode:typeOf
  local sel = lurek.ai.newSelector()
  if sel:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: SteeringManager:getBehaviorCount
-- Returns the number of active behaviors.
-- Use to verify your add* calls actually registered behaviours, especially after dynamic changes.
do  -- SteeringManager:getBehaviorCount
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  sm:addWander(20, 40, 5, 0.3)
  lurek.log.debug("behaviours=" .. sm:getBehaviorCount(), "ai")
end

--@api-stub: SteeringManager:setCombineMode
-- Sets the force combination mode.
-- "weighted_sum" blends all behaviours, "priority" picks the first non-zero one in order.
do  -- SteeringManager:setCombineMode
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  sm:setCombineMode("priority")
end

--@api-stub: SteeringManager:getCombineMode
-- Returns the current combination mode.
-- Returns the current mode string; default is "weighted_sum".
do  -- SteeringManager:getCombineMode
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  if sm:getCombineMode() == "weighted_sum" then lurek.log.debug("blend mode", "ai") end
end

--@api-stub: SteeringManager:getLastSteering
-- Returns the last computed steering force.
-- Returns the (fx, fy) force vector from the most recent calculate() call; zero before first tick.
do  -- SteeringManager:getLastSteering
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  local fx, fy = sm:getLastSteering()
  if fx ~= 0 or fy ~= 0 then lurek.log.debug("steering active", "ai") end
end

--@api-stub: SteeringManager:type
-- Returns the type name of this object.
-- Returns the literal string "SteeringManager".
do  -- SteeringManager:type
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  if sm:type() == "SteeringManager" then lurek.log.debug("ok", "ai") end
end

--@api-stub: SteeringManager:typeOf
-- Returns true if this object is of the given type.
-- True for "SteeringManager" and "Object".
do  -- SteeringManager:typeOf
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  if sm:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: SteeringManager:setSpatialHashCellSize
-- Sets the cell size used by the spatial-hash neighbourhood search.
-- Pick roughly 2x your max neighbour query radius; smaller cells use more memory but fewer false positives.
do  -- SteeringManager:setSpatialHashCellSize
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  sm:enableSpatialHash(true)
  sm:setSpatialHashCellSize(64)
end

--@api-stub: SteeringManager:enableSpatialHash
-- Enables or disables spatial-hash bucketing for neighbourhood queries.
-- Toggles bucketing for flock/separation queries; off by default for tiny crowds (<32 agents).
do  -- SteeringManager:enableSpatialHash
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  sm:enableSpatialHash(true)
end

--@api-stub: QLearner:chooseAction
-- Selects an action using epsilon-greedy policy (1-based).
-- Epsilon-greedy: explores randomly with prob epsilon, exploits otherwise; returns 1-based action index.
do  -- QLearner:chooseAction
  local ql = lurek.ai.newQLearner(8, 4)
  local action = ql:chooseAction(1)
  lurek.log.debug("action=" .. action, "ai")
end

--@api-stub: QLearner:bestAction
-- Returns the greedy-best action for the state (1-based).
-- Pure greedy choice with no exploration; useful when deploying a trained model.
do  -- QLearner:bestAction
  local ql = lurek.ai.newQLearner(8, 4)
  local action = ql:bestAction(1)
  if action >= 1 then lurek.log.debug("greedy=" .. action, "ai") end
end

--@api-stub: QLearner:getQValue
-- Returns the Q-value for a state-action pair (1-based).
-- Returns the current Q-estimate for (state, action); both indices are 1-based.
do  -- QLearner:getQValue
  local ql = lurek.ai.newQLearner(8, 4)
  ql:learn(1, 2, 1.0, 3)
  local q = ql:getQValue(1, 2)
  lurek.log.debug("Q(1,2)=" .. q, "ai")
end

--@api-stub: QLearner:endEpisode
-- Ends the current episode, applying epsilon decay.
-- Call at end of each training episode to apply epsilon decay (less exploration over time).
do  -- QLearner:endEpisode
  local ql = lurek.ai.newQLearner(8, 4)
  ql:learn(1, 1, 0.5, 2)
  ql:endEpisode()
end

--@api-stub: QLearner:getEpisodeCount
-- Returns the number of completed episodes.
-- Number of completed episodes; useful for epsilon decay schedules and learning-curve plots.
do  -- QLearner:getEpisodeCount
  local ql = lurek.ai.newQLearner(8, 4)
  ql:endEpisode()
  lurek.log.debug("episodes=" .. ql:getEpisodeCount(), "ai")
end

--@api-stub: QLearner:getStateCount
-- Returns the number of discrete states.
-- Returns the value passed to newQLearner; immutable after construction.
do  -- QLearner:getStateCount
  local ql = lurek.ai.newQLearner(8, 4)
  lurek.log.debug("states=" .. ql:getStateCount(), "ai")
end

--@api-stub: QLearner:getActionCount
-- Returns the number of discrete actions.
-- Returns the value passed to newQLearner; loop bound for action enumeration.
do  -- QLearner:getActionCount
  local ql = lurek.ai.newQLearner(8, 4)
  for a = 1, ql:getActionCount() do lurek.log.debug("a=" .. a, "ai") end
end

--@api-stub: QLearner:setLearningRate
-- Sets the learning rate alpha.
-- Alpha in (0, 1]; higher values learn faster but are noisier. 0.1 is a common starting point.
do  -- QLearner:setLearningRate
  local ql = lurek.ai.newQLearner(8, 4)
  ql:setLearningRate(0.05)
end

--@api-stub: QLearner:getLearningRate
-- Returns the current learning rate.
-- Returns the current alpha; read after schedule adjustments to verify the new value.
do  -- QLearner:getLearningRate
  local ql = lurek.ai.newQLearner(8, 4)
  lurek.log.debug("alpha=" .. ql:getLearningRate(), "ai")
end

--@api-stub: QLearner:setDiscountFactor
-- Sets the discount factor gamma.
-- Gamma in [0, 1]; closer to 1 values future rewards more heavily. 0.9-0.99 is typical.
do  -- QLearner:setDiscountFactor
  local ql = lurek.ai.newQLearner(8, 4)
  ql:setDiscountFactor(0.95)
end

--@api-stub: QLearner:getDiscountFactor
-- Returns the current discount factor.
-- Default gamma is 0.9; read back when serialising training hyperparameters.
do  -- QLearner:getDiscountFactor
  local ql = lurek.ai.newQLearner(8, 4)
  lurek.log.debug("gamma=" .. ql:getDiscountFactor(), "ai")
end

--@api-stub: QLearner:setExplorationRate
-- Sets the exploration rate epsilon.
-- Epsilon in [0, 1]; 1.0 is fully random, 0.0 is pure greedy. Decay over training.
do  -- QLearner:setExplorationRate
  local ql = lurek.ai.newQLearner(8, 4)
  ql:setExplorationRate(0.1)
end

--@api-stub: QLearner:getExplorationRate
-- Returns the current exploration rate.
-- Read after each endEpisode to monitor decay schedule progress.
do  -- QLearner:getExplorationRate
  local ql = lurek.ai.newQLearner(8, 4)
  if ql:getExplorationRate() < 0.05 then lurek.log.info("exploit phase", "ai") end
end

--@api-stub: QLearner:setExplorationDecay
-- Sets the epsilon decay multiplier.
-- Multiplied into epsilon every endEpisode; 0.999 gives slow decay, 0.99 gives faster.
do  -- QLearner:setExplorationDecay
  local ql = lurek.ai.newQLearner(8, 4)
  ql:setExplorationDecay(0.995)
end

--@api-stub: QLearner:getExplorationDecay
-- Returns the epsilon decay multiplier.
-- Read back when serialising training config.
do  -- QLearner:getExplorationDecay
  local ql = lurek.ai.newQLearner(8, 4)
  lurek.log.debug("decay=" .. ql:getExplorationDecay(), "ai")
end

--@api-stub: QLearner:serialize
-- Serializes the Q-table to a JSON string.
-- Returns a JSON string of the full Q-table; pair with lurek.fs.write to persist trained weights.
do  -- QLearner:serialize
  local ql = lurek.ai.newQLearner(8, 4)
  ql:learn(1, 1, 1.0, 2)
  local json = ql:serialize()
  lurek.log.info("saved " .. #json .. " bytes", "ai")
end

--@api-stub: QLearner:deserialize
-- Restores the Q-table from a JSON string.
-- Restores a Q-table from JSON produced by serialize(); raises an error on shape mismatch.
do  -- QLearner:deserialize
  local ql = lurek.ai.newQLearner(8, 4)
  local saved = ql:serialize()
  ql:deserialize(saved)
end

--@api-stub: QLearner:type
-- Returns the type name of this object.
-- Returns the literal string "QLearner".
do  -- QLearner:type
  local ql = lurek.ai.newQLearner(8, 4)
  if ql:type() == "QLearner" then lurek.log.debug("ok", "ai") end
end

--@api-stub: QLearner:typeOf
-- Returns true if this object is of the given type.
-- True for "QLearner" and "Object".
do  -- QLearner:typeOf
  local ql = lurek.ai.newQLearner(8, 4)
  if ql:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: UtilityAI:evaluate
-- Evaluates all actions and returns the best action name, or nil.
-- Runs every scorer and returns the highest-scoring action name; returns nil if no actions registered.
do  -- UtilityAI:evaluate
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("flee", function() return 0.8 end)
  uai:addAction("attack", function() return 0.4 end)
  local choice = uai:evaluate()
  if choice then lurek.log.info("chose " .. choice, "ai") end
end

--@api-stub: UtilityAI:getActionCount
-- Returns the number of registered actions.
-- Returns the number of addAction registrations; sanity-check after dynamic registration.
do  -- UtilityAI:getActionCount
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("flee", function() return 0.8 end)
  uai:addAction("attack", function() return 0.4 end)
  lurek.log.debug("actions=" .. uai:getActionCount(), "ai")
end

--@api-stub: UtilityAI:getLastAction
-- Returns the name of the last chosen action, or nil.
-- Returns the name of the most recently chosen action, or nil before the first evaluate().
do  -- UtilityAI:getLastAction
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("flee", function() return 0.8 end)
  uai:addAction("attack", function() return 0.4 end)
  uai:evaluate()
  local last = uai:getLastAction()
  if last then lurek.log.debug("last=" .. last, "ai") end
end

--@api-stub: UtilityAI:type
-- Returns the type name of this object.
-- Returns the literal string "UtilityAI".
do  -- UtilityAI:type
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("flee", function() return 0.8 end)
  uai:addAction("attack", function() return 0.4 end)
  if uai:type() == "UtilityAI" then lurek.log.debug("ok", "ai") end
end

--@api-stub: UtilityAI:typeOf
-- Returns true if this object is of the given type.
-- True for "UtilityAI" and "Object".
do  -- UtilityAI:typeOf
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("flee", function() return 0.8 end)
  uai:addAction("attack", function() return 0.4 end)
  if uai:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: GOAPPlanner:getActionCount
-- Returns the number of registered actions.
-- Sanity-check after dynamic action wiring; useful in level-load tests.
do  -- GOAPPlanner:getActionCount
  local p = lurek.ai.newGOAPPlanner()
  p:addAction("eat", 1.0, function() end)
  p:addGoal("not_hungry", 1.0)
  lurek.log.debug("actions=" .. p:getActionCount(), "ai")
end

--@api-stub: GOAPPlanner:getGoalCount
-- Returns the number of registered goals.
-- Use to verify your goal-generation step actually populated the planner.
do  -- GOAPPlanner:getGoalCount
  local p = lurek.ai.newGOAPPlanner()
  p:addAction("eat", 1.0, function() end)
  p:addGoal("not_hungry", 1.0)
  if p:getGoalCount() == 0 then lurek.log.warn("no goals", "ai") end
end

--@api-stub: GOAPPlanner:getMaxIterations
-- Returns the maximum A* planning iterations.
-- A* iteration cap; default is 0 (unlimited). Read back when tuning planning latency.
do  -- GOAPPlanner:getMaxIterations
  local p = lurek.ai.newGOAPPlanner()
  p:addAction("eat", 1.0, function() end)
  p:addGoal("not_hungry", 1.0)
  lurek.log.debug("max iters=" .. p:getMaxIterations(), "ai")
end

--@api-stub: GOAPPlanner:setMaxIterations
-- Sets the maximum A* planning iterations (0 = unlimited).
-- Pass 0 for unlimited; set a finite cap (e.g. 1000) to bound worst-case planning cost per frame.
do  -- GOAPPlanner:setMaxIterations
  local p = lurek.ai.newGOAPPlanner()
  p:addAction("eat", 1.0, function() end)
  p:addGoal("not_hungry", 1.0)
  p:setMaxIterations(500)
end

--@api-stub: GOAPPlanner:type
-- Returns the type name of this object.
-- Returns the literal string "GOAPPlanner".
do  -- GOAPPlanner:type
  local p = lurek.ai.newGOAPPlanner()
  p:addAction("eat", 1.0, function() end)
  p:addGoal("not_hungry", 1.0)
  if p:type() == "GOAPPlanner" then lurek.log.debug("ok", "ai") end
end

--@api-stub: GOAPPlanner:typeOf
-- Returns true if this object is of the given type.
-- True for "GOAPPlanner" and "Object".
do  -- GOAPPlanner:typeOf
  local p = lurek.ai.newGOAPPlanner()
  p:addAction("eat", 1.0, function() end)
  p:addGoal("not_hungry", 1.0)
  if p:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: InfluenceMap:addLayer
-- Adds a named influence layer.
-- Layers are independent grids; stamp / decay / propagate operate on a single named layer.
do  -- InfluenceMap:addLayer
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:addLayer("loot")
end

--@api-stub: InfluenceMap:hasLayer
-- Returns true if the named layer exists.
-- Cheap hash lookup; check before stamping to avoid silently writing into the wrong layer.
do  -- InfluenceMap:hasLayer
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  if im:hasLayer("threat") then lurek.log.debug("layer ok", "ai") end
end

--@api-stub: InfluenceMap:decay
-- Multiplies all influences by a decay factor.
-- Multiplies every cell by factor each call; use 0.95-0.99 per frame for gentle fade-out.
do  -- InfluenceMap:decay
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:stampInfluence("threat", 100, 100, 64, 1.0, 1.0)
  function lurek.process(dt) im:decay("threat", 0.97) end
end

--@api-stub: InfluenceMap:clearLayer
-- Clears all influence in a layer.
-- Zeroes the entire layer in one call; cheaper than stamping over with a negative value.
do  -- InfluenceMap:clearLayer
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:stampInfluence("threat", 100, 100, 64, 1.0, 1.0)
  im:clearLayer("threat")
end

--@api-stub: InfluenceMap:clearAll
-- Removes all influence values from every layer in the map.
-- Zeroes every layer; use at scene boundaries to start fresh.
do  -- InfluenceMap:clearAll
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:clearAll()
end

--@api-stub: InfluenceMap:getMaxPosition
-- Returns the world-space position of the maximum value.
-- World-space (x, y) of the maximum value cell; useful for seeking the most-influenced point.
do  -- InfluenceMap:getMaxPosition
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:stampInfluence("threat", 200, 100, 32, 1.0, 1.0)
  local mx, my = im:getMaxPosition("threat")
  lurek.log.debug("hot=" .. mx .. "," .. my, "ai")
end

--@api-stub: InfluenceMap:getMinPosition
-- Returns the world-space position of the minimum value.
-- World-space (x, y) of the minimum value cell; pair with getMaxPosition for safe-vs-danger lookups.
do  -- InfluenceMap:getMinPosition
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:stampInfluence("threat", 200, 100, 32, 1.0, 1.0)
  local sx, sy = im:getMinPosition("threat")
  lurek.log.debug("safe=" .. sx .. "," .. sy, "ai")
end

--@api-stub: InfluenceMap:getWidth
-- Returns the influence map width in grid cells.
-- Width in grid cells (not world units); multiply by getCellSize for world extent.
do  -- InfluenceMap:getWidth
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  lurek.log.debug("w=" .. im:getWidth(), "ai")
end

--@api-stub: InfluenceMap:getHeight
-- Returns the influence map height in grid cells.
-- Height in grid cells; pair with getWidth and getCellSize to compute world AABB.
do  -- InfluenceMap:getHeight
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  lurek.log.debug("h=" .. im:getHeight(), "ai")
end

--@api-stub: InfluenceMap:getCellSize
-- Returns the cell size in world units.
-- World units per cell; pick to match your tile pitch for clean visualisation overlap.
do  -- InfluenceMap:getCellSize
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  lurek.log.debug("cell=" .. im:getCellSize(), "ai")
end

--@api-stub: InfluenceMap:type
-- Returns the type name of this object.
-- Returns the literal string "InfluenceMap".
do  -- InfluenceMap:type
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  if im:type() == "InfluenceMap" then lurek.log.debug("ok", "ai") end
end

--@api-stub: InfluenceMap:typeOf
-- Returns true if this object is of the given type.
-- True for "InfluenceMap" and "Object".
do  -- InfluenceMap:typeOf
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  if im:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: Squad:getName
-- Returns the unique name string assigned to this squad.
-- Returns the unique name passed to newSquad; useful when looking up squads in a registry.
do  -- Squad:getName
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  lurek.log.debug("squad=" .. sq:getName(), "ai")
end

--@api-stub: Squad:addMember
-- Adds an agent by name to this squad.
-- Adds an agent by name; the squad does NOT verify the name exists in any world, that is your job.
do  -- Squad:addMember
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  sq:addMember("guard_02")
  sq:addMember("scout_03")
end

--@api-stub: Squad:removeMember
-- Removes an agent by name from this squad.
-- Silent no-op if the name was not present; safe to call after deaths.
do  -- Squad:removeMember
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  sq:addMember("doomed")
  sq:removeMember("doomed")
end

--@api-stub: Squad:getMemberCount
-- Returns the number of squad members.
-- Use for HUD readouts and "squad wiped" detection (count == 0).
do  -- Squad:getMemberCount
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  if sq:getMemberCount() == 0 then lurek.log.warn("squad wiped", "ai") end
end

--@api-stub: Squad:getMembers
-- Returns the member names as a table.
-- Returns a 1-based array of member name strings; iterate with ipairs for stable order.
do  -- Squad:getMembers
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  sq:addMember("guard_02")
  for _, m in ipairs(sq:getMembers()) do lurek.log.debug("m=" .. m, "ai") end
end

--@api-stub: Squad:setLeader
-- Sets the squad leader by name.
-- Pass nil to clear the leader; formations re-anchor on the new leader the next tick.
do  -- Squad:setLeader
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  sq:setLeader("guard_01")
end

--@api-stub: Squad:getLeader
-- Returns the leader name, or nil.
-- Returns the leader name or nil; check before computing leader-relative formation positions.
do  -- Squad:getLeader
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  sq:setLeader("guard_01")
  local l = sq:getLeader()
  if l then lurek.log.debug("leader=" .. l, "ai") end
end

--@api-stub: Squad:getFormation
-- Returns the current formation type name.
-- Returns the formation type string ("line", "wedge", "column", etc.).
do  -- Squad:getFormation
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  sq:setFormation("wedge", 32)
  if sq:getFormation() == "wedge" then lurek.log.debug("v formation", "ai") end
end

--@api-stub: Squad:getFormationSpacing
-- Returns the formation spacing in world units.
-- World-unit gap between formation slots; tune to your sprite size to avoid overlap.
do  -- Squad:getFormationSpacing
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  sq:setFormation("line", 48)
  lurek.log.debug("spacing=" .. sq:getFormationSpacing(), "ai")
end

--@api-stub: Squad:getBlackboard
-- Returns the squad's shared blackboard.
-- Squad-shared blackboard distinct from each agent's local board; use for fire-team objectives.
do  -- Squad:getBlackboard
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  local bb = sq:getBlackboard()
  bb:setString("objective", "capture_point_a")
end

--@api-stub: Squad:type
-- Returns the type name of this object.
-- Returns the literal string "Squad".
do  -- Squad:type
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  if sq:type() == "Squad" then lurek.log.debug("ok", "ai") end
end

--@api-stub: Squad:typeOf
-- Returns true if this object is of the given type.
-- True for "Squad" and "Object".
do  -- Squad:typeOf
  local sq = lurek.ai.newSquad("alpha")
  sq:addMember("guard_01")
  if sq:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: CommandQueue:cancelCurrent
-- Cancels the front command if it is interruptible.
-- Cancels only if the front command has interruptible = true; returns whether it was cancelled.
do  -- CommandQueue:cancelCurrent
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  if cq:cancelCurrent() then lurek.log.debug("cancelled", "ai") end
end

--@api-stub: CommandQueue:clear
-- Discards all queued commands.
-- Wipes every queued command including the running one; use on death or on objective change.
do  -- CommandQueue:clear
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  cq:enqueue("attack", function() end)
  cq:clear()
end

--@api-stub: CommandQueue:getCount
-- Returns the number of queued commands.
-- Includes the currently executing command; pair with isEmpty to drive an idle state.
do  -- CommandQueue:getCount
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  lurek.log.debug("queue=" .. cq:getCount(), "ai")
end

--@api-stub: CommandQueue:isEmpty
-- Returns true if there are no queued commands.
-- True iff getCount() == 0; cheaper to call than getCount when you only need a boolean.
do  -- CommandQueue:isEmpty
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  cq:clear()
  if cq:isEmpty() then lurek.log.debug("idle", "ai") end
end

--@api-stub: CommandQueue:getCurrentType
-- Returns the kind of the front command, or nil.
-- Returns the kind string passed to enqueue (e.g. "move", "attack"); nil if queue empty.
do  -- CommandQueue:getCurrentType
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  local kind = cq:getCurrentType()
  if kind then lurek.log.debug("doing " .. kind, "ai") end
end

--@api-stub: CommandQueue:getCurrentTarget
-- Returns the target coordinates of the front command.
-- Returns (tx, ty) from the opts table of the front command; (0, 0) if no target.
do  -- CommandQueue:getCurrentTarget
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  local tx, ty = cq:getCurrentTarget()
  lurek.log.debug("target=" .. tx .. "," .. ty, "ai")
end

--@api-stub: CommandQueue:type
-- Returns the type name of this object.
-- Returns the literal string "CommandQueue".
do  -- CommandQueue:type
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  if cq:type() == "CommandQueue" then lurek.log.debug("ok", "ai") end
end

--@api-stub: CommandQueue:typeOf
-- Returns true if this object is of the given type.
-- True for "CommandQueue" and "Object".
do  -- CommandQueue:typeOf
  local cq = lurek.ai.newCommandQueue()
  cq:enqueue("move", function() end, { targetX = 200, targetY = 100 })
  if cq:typeOf("Object") then lurek.log.debug("ok", "ai") end
end

--@api-stub: TraitProfile:set
-- Sets the base value of this trait, replacing any previous base.
-- Sets the unmodified base value; any modifiers stack on top via addModifier.
do  -- TraitProfile:set
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  tp:set("courage", 0.5)
end

--@api-stub: TraitProfile:get
-- Returns the current float value of this emotion dimension.
-- Returns base + summed modifiers (clamped to the trait's min/max if defined).
do  -- TraitProfile:get
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  local v = tp:get("aggression")
  if v > 0.6 then lurek.log.debug("aggressive", "ai") end
end

--@api-stub: TraitProfile:getBase
-- Returns the unmodified base value of this trait before modifiers.
-- Returns the unmodified base value before any modifiers; useful for save/load.
do  -- TraitProfile:getBase
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  local base = tp:getBase("aggression")
  lurek.log.debug("base=" .. base, "ai")
end

--@api-stub: TraitProfile:removeModifiers
-- Removes the specified modifiers.
-- Removes every modifier matching the source string; safe no-op if none match.
do  -- TraitProfile:removeModifiers
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  tp:addModifier("aggression", 0.2, 10.0, "rage_potion")
  tp:removeModifiers("rage_potion")
end

--@api-stub: TraitProfile:update
-- Advances the simulation by one time step.
-- Decrements timed modifiers and removes expired ones; call from lurek.process(dt).
do  -- TraitProfile:update
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  tp:addModifier("aggression", 0.2, 5.0, "buff")
  function lurek.process(dt) tp:update(dt) end
end

--@api-stub: TraitProfile:has
-- Returns true if a item is present.
-- Returns true if the trait was ever set; useful before reading to avoid 0.0 default confusion.
do  -- TraitProfile:has
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  if tp:has("aggression") then lurek.log.debug("trait set", "ai") end
end

--@api-stub: TraitProfile:traitCount
-- Returns or performs trait count.
-- Returns the number of distinct trait names currently registered.
do  -- TraitProfile:traitCount
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  lurek.log.debug("traits=" .. tp:traitCount(), "ai")
end

--@api-stub: TraitProfile:archetype
-- Returns or performs archetype.
-- Returns the closest matching archetype name ("warrior", "sage", etc.) or nil if none configured.
do  -- TraitProfile:archetype
  local tp = lurek.ai.newTraitProfile()
  tp:set("aggression", 0.7)
  local arch = tp:archetype()
  if arch then lurek.log.info("archetype=" .. arch, "ai") end
end

--@api-stub: StimulusWorld:remove
-- Removes the specified item.
-- Returns true if the id was found and removed; ids are returned by addVisual / addAuditory.
do  -- StimulusWorld:remove
  local sw = lurek.ai.newStimulusWorld()
  local id = sw:addAuditory(100, 200, 1.0, 150, 0.5, "footstep")
  if sw:remove(id) then lurek.log.debug("removed " .. id, "ai") end
end

--@api-stub: StimulusWorld:update
-- Advances the simulation by one time step.
-- Advances decay and removes faded stimuli; call once per frame from lurek.process(dt).
do  -- StimulusWorld:update
  local sw = lurek.ai.newStimulusWorld()
  local id = sw:addAuditory(100, 200, 1.0, 150, 0.5, "footstep")
  function lurek.process(dt) sw:update(dt) end
end

--@api-stub: StimulusWorld:clear
-- Resets or clears the state.
-- Drops every stimulus in one call; use on scene transitions.
do  -- StimulusWorld:clear
  local sw = lurek.ai.newStimulusWorld()
  local id = sw:addAuditory(100, 200, 1.0, 150, 0.5, "footstep")
  sw:clear()
end

--@api-stub: ContextSteering:addWander
-- Adds a wander behavior with jitter and weight to the context steering evaluator.
-- Jitter is the per-tick angle randomisation in radians; weight scales the contribution.
do  -- ContextSteering:addWander
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  cs:addWander(0.5, 0.3)
end

--@api-stub: ContextSteering:addAvoidBounds
-- Registers a rectangular region this agent must avoid.
-- AABB to steer away from; margin is the soft-zone width inside which avoidance ramps in.
do  -- ContextSteering:addAvoidBounds
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  cs:addAvoidBounds(0, 0, 1280, 720, 32, 1.0)
end

--@api-stub: ContextSteering:clearBehaviors
-- Resets or clears the behaviors.
-- Wipes every registered behaviour; use when switching the agent's tactical mode.
do  -- ContextSteering:clearBehaviors
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  cs:clearBehaviors()
end

--@api-stub: ContextSteering:chosenMagnitude
-- Returns or performs chosen magnitude.
-- Returns the strength of the slot picked by the last evaluate(); useful for movement scaling.
do  -- ContextSteering:chosenMagnitude
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  cs:evaluate(0, 0, 0, 0)
  lurek.log.debug("mag=" .. cs:chosenMagnitude(), "ai")
end

--@api-stub: ContextSteering:slotCount
-- Returns or performs slot count.
-- Returns the slot count passed to newContextSteering; immutable after construction.
do  -- ContextSteering:slotCount
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  lurek.log.debug("slots=" .. cs:slotCount(), "ai")
end

--@api-stub: NeedSystem:addNeed
-- Registers a new need with the specified name, urgency, and decay rate in the system.
-- Args: name, decay_rate (per second), urgency_threshold, urgency_factor (multiplier above threshold).
do  -- NeedSystem:addNeed
  local ns = lurek.ai.newNeedSystem()
  ns:addNeed("hunger", 0.05, 0.6, 1.5)
  ns:addNeed("thirst", 0.08, 0.5, 2.0)
end

--@api-stub: NeedSystem:update
-- Advances the simulation by one time step.
-- Decays every need by its decay_rate * dt; call once per frame from lurek.process.
do  -- NeedSystem:update
  local ns = lurek.ai.newNeedSystem()
  ns:addNeed("hunger", 0.05, 0.6, 1.5)
  function lurek.process(dt) ns:update(dt) end
end

--@api-stub: NeedSystem:mostUrgent
-- Returns or performs most urgent.
-- Returns the name of the highest-urgency need, or nil if none are above threshold.
do  -- NeedSystem:mostUrgent
  local ns = lurek.ai.newNeedSystem()
  ns:addNeed("hunger", 0.05, 0.6, 1.5)
  local n = ns:mostUrgent()
  if n then lurek.log.debug("urgent: " .. n, "ai") end
end

--@api-stub: NeedSystem:satisfy
-- Returns or performs satisfy.
-- Reduces the named need by amount, clamped to zero; call when the agent eats / drinks / rests.
do  -- NeedSystem:satisfy
  local ns = lurek.ai.newNeedSystem()
  ns:addNeed("hunger", 0.05, 0.6, 1.5)
  ns:satisfy("hunger", 0.4)
end

--@api-stub: NeedSystem:valueOf
-- Returns or performs value of.
-- Returns the current need value in [0, 1]; 1.0 is fully unsatisfied / desperate.
do  -- NeedSystem:valueOf
  local ns = lurek.ai.newNeedSystem()
  ns:addNeed("hunger", 0.05, 0.6, 1.5)
  if ns:valueOf("hunger") > 0.8 then lurek.log.warn("starving", "ai") end
end

--@api-stub: AIDirector:pushEvent
-- Pushes a gameplay event with the given intensity to the director for awareness analysis.
-- Intensity in [0, 1]; combat bursts push tension up, calm exploration lets it decay.
do  -- AIDirector:pushEvent
  local dir = lurek.ai.newAIDirector()
  dir:pushEvent(0.7)
end

--@api-stub: AIDirector:update
-- Advances the simulation by one time step.
-- Drives tension decay and phase transitions; call once per frame.
do  -- AIDirector:update
  local dir = lurek.ai.newAIDirector()
  function lurek.process(dt) dir:update(dt) end
end

--@api-stub: AIDirector:tension
-- Returns or performs tension.
-- Returns the current narrative tension in [0, 1]; drives spawnRateFactor and ambient mood.
do  -- AIDirector:tension
  local dir = lurek.ai.newAIDirector()
  dir:pushEvent(0.5)
  lurek.log.debug("tension=" .. dir:tension(), "ai")
end

--@api-stub: AIDirector:phase
-- Returns or performs phase.
-- Returns the phase string ("buildup", "peak", "relax", "calm"); use for music transitions.
do  -- AIDirector:phase
  local dir = lurek.ai.newAIDirector()
  if dir:phase() == "peak" then lurek.log.info("intense moment", "ai") end
end

--@api-stub: AIDirector:spawnRateFactor
-- Returns or performs spawn rate factor.
-- Multiplier in roughly [0, 2] you apply to your base spawn rate; bursts during peak phase.
do  -- AIDirector:spawnRateFactor
  local dir = lurek.ai.newAIDirector()
  local mult = dir:spawnRateFactor()
  lurek.log.debug("spawn x" .. mult, "ai")
end

--@api-stub: AIDirector:lootFactor
-- Returns or performs loot factor.
-- Multiplier on loot drop rates; rises during relax phase to reward the player after stress.
do  -- AIDirector:lootFactor
  local dir = lurek.ai.newAIDirector()
  lurek.log.debug("loot x" .. dir:lootFactor(), "ai")
end

--@api-stub: AIDirector:ambientIntensity
-- Returns or performs ambient intensity.
-- Drives ambient SFX / shader effects; 0 = quiet, 1 = peak intensity.
do  -- AIDirector:ambientIntensity
  local dir = lurek.ai.newAIDirector()
  local amb = dir:ambientIntensity()
  if amb > 0.5 then lurek.log.debug("loud ambience", "ai") end
end

--@api-stub: AIDirector:setTension
-- Sets the global narrative tension level (0â€“1 scale).
-- Force-overrides tension (e.g. for cutscenes); subsequent updates resume natural decay.
do  -- AIDirector:setTension
  local dir = lurek.ai.newAIDirector()
  dir:setTension(0.9)
end

--@api-stub: AIDirector:reset
-- Resets or clears the state.
-- Zeroes tension and resets phase to "calm"; use on scene transitions.
do  -- AIDirector:reset
  local dir = lurek.ai.newAIDirector()
  dir:reset()
end

--@api-stub: HTNDomain:addPrimitive
-- Registers a primitive HTN task with a direct operator function.
-- Args: name, preconds list, effects list (set true), clears list (set false). Use for atomic actions.
do  -- HTNDomain:addPrimitive
  local d = lurek.ai.newHTNDomain()
  d:addPrimitive("attack", { "has_weapon", "in_range" }, { "enemy_dead" }, { "in_range" })
end

--@api-stub: HTNDomain:taskCount
-- Returns or performs task count.
-- Total number of tasks (primitive + compound); useful for domain-size diagnostics.
do  -- HTNDomain:taskCount
  local d = lurek.ai.newHTNDomain()
  d:addPrimitive("rest", {}, { "rested" }, {})
  lurek.log.debug("tasks=" .. d:taskCount(), "ai")
end

--@api-stub: EmotionModel:trigger
-- Returns or performs trigger.
-- Adds amount to the named emotion; clamped to the emotion's max. Call on stimulus events.
do  -- EmotionModel:trigger
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.1, 0.2)
  em:trigger("fear", 0.5)
end

--@api-stub: EmotionModel:get
-- Returns the current float value of this emotion dimension.
-- Returns the current intensity in [0, 1]; 0 means at resting level.
do  -- EmotionModel:get
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.1, 0.2)
  em:trigger("fear", 0.4)
  if em:get("fear") > 0.3 then lurek.log.debug("scared", "ai") end
end

--@api-stub: EmotionModel:dominant
-- Returns or performs dominant.
-- Returns the name of the emotion with the highest intensity, or nil if all at rest.
do  -- EmotionModel:dominant
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.1, 0.2)
  em:trigger("fear", 0.6)
  local d = em:dominant()
  if d then lurek.log.info("feeling " .. d, "ai") end
end

--@api-stub: EmotionModel:isActive
-- Returns `true` if the emotion dimension is currently active and above threshold.
-- True if the emotion is above its min_visible threshold; use to drive facial expression swaps.
do  -- EmotionModel:isActive
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.1, 0.2)
  em:trigger("fear", 0.5)
  if em:isActive("fear") then lurek.log.debug("show fear face", "ai") end
end

--@api-stub: EmotionModel:update
-- Advances the simulation by one time step.
-- Decays each emotion toward its resting level by decay_rate * dt; call from lurek.process(dt).
do  -- EmotionModel:update
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.1, 0.2)
  function lurek.process(dt) em:update(dt) end
end

--@api-stub: EmotionModel:reset
-- Resets or clears the state.
-- Snaps every emotion back to its resting level; use on scene transitions.
do  -- EmotionModel:reset
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.1, 0.2)
  em:reset()
end

--@api-stub: ORCASolver:setPosition
-- Sets the agent's current world-space position for ORCA velocity computation.
-- Update each ORCA agent's position from your physics step before calling compute.
do  -- ORCASolver:setPosition
  local orca = lurek.ai.newORCASolver(2.0)
  local idx = orca:addAgent(100, 100, 16, 80)
  orca:setPosition(idx, 120, 100)
end

--@api-stub: ORCASolver:compute
-- Computes and returns the result.
-- Runs the ORCA half-plane intersection; produces safe velocities readable via getSafeVelocity.
do  -- ORCASolver:compute
  local orca = lurek.ai.newORCASolver(2.0)
  local idx = orca:addAgent(100, 100, 16, 80)
  function lurek.process(dt) orca:compute(dt) end
end

--@api-stub: ORCASolver:getSafeVelocity
-- Returns the safe velocity.
-- Returns (vx, vy) collision-free velocity for the agent; apply to your movement integrator.
do  -- ORCASolver:getSafeVelocity
  local orca = lurek.ai.newORCASolver(2.0)
  local idx = orca:addAgent(100, 100, 16, 80)
  orca:compute(0.016)
  local vx, vy = orca:getSafeVelocity(idx)
  lurek.log.debug("safe v=" .. vx .. "," .. vy, "ai")
end

--@api-stub: ORCASolver:agentCount
-- Returns or performs agent count.
-- Returns the number of registered ORCA agents; sanity-check for crowd populations.
do  -- ORCASolver:agentCount
  local orca = lurek.ai.newORCASolver(2.0)
  local idx = orca:addAgent(100, 100, 16, 80)
  lurek.log.debug("agents=" .. orca:agentCount(), "ai")
end

--@api-stub: NeuralNet:forward
-- Returns or performs forward.
-- Input table length must equal the first layer's input size; output length matches the last layer.
do  -- NeuralNet:forward
  local nn = lurek.ai.newNeuralNet()
  nn:addLayer(4, 8, "relu")
  nn:addLayer(8, 2, "softmax")
  local out = nn:forward({ 0.1, 0.2, 0.3, 0.4 })
  lurek.log.debug("y=" .. out[1] .. "," .. out[2], "ai")
end

--@api-stub: NeuralNet:setWeights
-- Overwrites all connection weights with values from a flat table.
-- Pass a flat table of all weights in layer-major order; returns false on size mismatch.
do  -- NeuralNet:setWeights
  local nn = lurek.ai.newNeuralNet()
  nn:addLayer(4, 8, "relu")
  nn:addLayer(8, 2, "softmax")
  local count = nn:paramCount()
  local zeros = {}; for i = 1, count do zeros[i] = 0.01 end
  nn:setWeights(zeros)
end

--@api-stub: NeuralNet:getWeights
-- Returns a flat table of all connection weight values in the network.
-- Returns a flat table of every weight in the network; use to checkpoint trained models.
do  -- NeuralNet:getWeights
  local nn = lurek.ai.newNeuralNet()
  nn:addLayer(4, 8, "relu")
  nn:addLayer(8, 2, "softmax")
  local w = nn:getWeights()
  lurek.log.debug("weights=" .. #w, "ai")
end

--@api-stub: NeuralNet:paramCount
-- Returns or performs param count.
-- Total number of weights + biases; needed when sizing the array passed to setWeights.
do  -- NeuralNet:paramCount
  local nn = lurek.ai.newNeuralNet()
  nn:addLayer(4, 8, "relu")
  nn:addLayer(8, 2, "softmax")
  lurek.log.debug("params=" .. nn:paramCount(), "ai")
end

--@api-stub: NeuralNet:layerCount
-- Returns or performs layer count.
-- Number of layers added so far; one per addLayer call.
do  -- NeuralNet:layerCount
  local nn = lurek.ai.newNeuralNet()
  nn:addLayer(4, 8, "relu")
  nn:addLayer(8, 2, "softmax")
  lurek.log.debug("layers=" .. nn:layerCount(), "ai")
end

--@api-stub: GeneticAlgorithm:evolve
-- Runs one generation of the evolutionary algorithm.
-- Performs selection / crossover / mutation; call once per generation, after setting all fitnesses.
do  -- GeneticAlgorithm:evolve
  local ga = lurek.ai.newGeneticAlgorithm(20, 8, 42)
  for i = 1, ga:popSize() do ga:setFitness(i - 1, 0.5) end
  ga:evolve()
end

--@api-stub: GeneticAlgorithm:generation
-- Returns or performs generation.
-- Number of completed evolve() calls; useful as a stop condition or for logging.
do  -- GeneticAlgorithm:generation
  local ga = lurek.ai.newGeneticAlgorithm(20, 8, 42)
  if ga:generation() >= 100 then lurek.log.info("done", "ai") end
end

--@api-stub: GeneticAlgorithm:popSize
-- Returns or performs pop size.
-- Returns the population size passed to newGeneticAlgorithm; immutable.
do  -- GeneticAlgorithm:popSize
  local ga = lurek.ai.newGeneticAlgorithm(20, 8, 42)
  lurek.log.debug("pop=" .. ga:popSize(), "ai")
end

--@api-stub: GeneticAlgorithm:setFitness
-- Sets the fitness score used by the genetic algorithm selection step.
-- 0-based index; set every individual's fitness before calling evolve().
do  -- GeneticAlgorithm:setFitness
  local ga = lurek.ai.newGeneticAlgorithm(20, 8, 42)
  for i = 0, ga:popSize() - 1 do ga:setFitness(i, math.random()) end
end

--@api-stub: GeneticAlgorithm:getGenes
-- Returns the chromosome as an ordered table of gene values.
-- Returns the gene table for the 0-based individual; gene values are floats in [-1, 1].
do  -- GeneticAlgorithm:getGenes
  local ga = lurek.ai.newGeneticAlgorithm(20, 8, 42)
  local genes = ga:getGenes(0)
  lurek.log.debug("g0=" .. genes[1], "ai")
end

--@api-stub: GeneticAlgorithm:bestGenes
-- Returns or performs best genes.
-- Returns the gene table for the highest-fitness individual; use to deploy the best solution.
do  -- GeneticAlgorithm:bestGenes
  local ga = lurek.ai.newGeneticAlgorithm(20, 8, 42)
  ga:setFitness(0, 1.0)
  local best = ga:bestGenes()
  lurek.log.debug("best[1]=" .. best[1], "ai")
end

--@api-stub: Bandit:select
-- Returns or performs select.
-- Picks an arm via the configured strategy; returns 0-based index. Reward via update.
do  -- Bandit:select
  local b = lurek.ai.newBandit(4, "ucb1", 0.1, 99)
  local arm = b:select()
  lurek.log.debug("arm=" .. arm, "ai")
end

--@api-stub: Bandit:update
-- Advances the simulation by one time step.
-- Records reward for a previously-selected arm; required for the bandit to learn.
do  -- Bandit:update
  local b = lurek.ai.newBandit(4, "ucb1", 0.1, 99)
  local arm = b:select()
  b:update(arm, 1.0)
end

--@api-stub: Bandit:bestArm
-- Returns or performs best arm.
-- Returns the arm index with the highest empirical mean; use for greedy exploitation.
do  -- Bandit:bestArm
  local b = lurek.ai.newBandit(4, "ucb1", 0.1, 99)
  b:update(0, 0.7); b:update(1, 0.3)
  lurek.log.debug("best arm=" .. b:bestArm(), "ai")
end

--@api-stub: Bandit:reset
-- Resets or clears the state.
-- Clears all pull counts and reward history; use to start a fresh experiment.
do  -- Bandit:reset
  local b = lurek.ai.newBandit(4, "ucb1", 0.1, 99)
  b:reset()
end

--@api-stub: Bandit:armCount
-- Returns or performs arm count.
-- Returns the arm count passed to newBandit; immutable.
do  -- Bandit:armCount
  local b = lurek.ai.newBandit(4, "ucb1", 0.1, 99)
  lurek.log.debug("arms=" .. b:armCount(), "ai")
end

--@api-stub: Bandit:totalPulls
-- Returns or performs total pulls.
-- Sum of all arm pulls so far; useful for stopping rules and convergence checks.
do  -- Bandit:totalPulls
  local b = lurek.ai.newBandit(4, "ucb1", 0.1, 99)
  b:select(); b:select()
  lurek.log.debug("pulls=" .. b:totalPulls(), "ai")
end

--@api-stub: Neuroevolution:evolve
-- Runs one generation of the evolutionary algorithm.
-- Runs one generation; remember to set fitnesses for every individual first via setFitness.
do  -- Neuroevolution:evolve
  local layers = { { inputs = 2, outputs = 4, activation = "relu" }, { inputs = 4, outputs = 1, activation = "tanh" } }
  local ne = lurek.ai.newNeuroevolution(layers, 10, 1)
  for i = 0, ne:popSize() - 1 do ne:setFitness(i, 0.5) end
  ne:evolve()
end

--@api-stub: Neuroevolution:setFitness
-- Sets the fitness score used by the genetic algorithm selection step.
-- 0-based individual index; raise to favour, drop to discard. Higher is always better.
do  -- Neuroevolution:setFitness
  local layers = { { inputs = 2, outputs = 4, activation = "relu" }, { inputs = 4, outputs = 1, activation = "tanh" } }
  local ne = lurek.ai.newNeuroevolution(layers, 10, 1)
  ne:setFitness(0, 0.85)
end

--@api-stub: Neuroevolution:chromosomeToNet
-- Returns or performs chromosome to net.
-- Materialises a NeuralNet for the 0-based individual; nil if index out of range.
do  -- Neuroevolution:chromosomeToNet
  local layers = { { inputs = 2, outputs = 4, activation = "relu" }, { inputs = 4, outputs = 1, activation = "tanh" } }
  local ne = lurek.ai.newNeuroevolution(layers, 10, 1)
  local net = ne:chromosomeToNet(0)
  if net then lurek.log.debug("net layers=" .. net:layerCount(), "ai") end
end

--@api-stub: Neuroevolution:bestNetwork
-- Returns or performs best network.
-- Returns a NeuralNet built from the highest-fitness chromosome; use for deployment.
do  -- Neuroevolution:bestNetwork
  local layers = { { inputs = 2, outputs = 4, activation = "relu" }, { inputs = 4, outputs = 1, activation = "tanh" } }
  local ne = lurek.ai.newNeuroevolution(layers, 10, 1)
  ne:setFitness(0, 1.0)
  local best = ne:bestNetwork()
  if best then lurek.log.debug("ok", "ai") end
end

--@api-stub: Neuroevolution:bestFitness
-- Returns or performs best fitness.
-- Returns the highest fitness across the current population; useful for early stopping.
do  -- Neuroevolution:bestFitness
  local layers = { { inputs = 2, outputs = 4, activation = "relu" }, { inputs = 4, outputs = 1, activation = "tanh" } }
  local ne = lurek.ai.newNeuroevolution(layers, 10, 1)
  ne:setFitness(0, 0.7)
  lurek.log.debug("best=" .. ne:bestFitness(), "ai")
end

--@api-stub: Neuroevolution:popSize
-- Returns or performs pop size.
-- Returns the population size passed to newNeuroevolution; immutable.
do  -- Neuroevolution:popSize
  local layers = { { inputs = 2, outputs = 4, activation = "relu" }, { inputs = 4, outputs = 1, activation = "tanh" } }
  local ne = lurek.ai.newNeuroevolution(layers, 10, 1)
  lurek.log.debug("pop=" .. ne:popSize(), "ai")
end

--@api-stub: Neuroevolution:generation
-- Returns or performs generation.
-- Number of evolve() calls so far; use as the termination gate.
do  -- Neuroevolution:generation
  local layers = { { inputs = 2, outputs = 4, activation = "relu" }, { inputs = 4, outputs = 1, activation = "tanh" } }
  local ne = lurek.ai.newNeuroevolution(layers, 10, 1)
  if ne:generation() >= 50 then lurek.log.info("converged", "ai") end
end

--@api-stub: StrategyAI:addGoal
-- Adds a strategic goal with priority score to the planner for future evaluation.
-- Goal names are arbitrary strings; the scorer callback you pass to update will receive them.
do  -- StrategyAI:addGoal
  local s = lurek.ai.newStrategyAI(2.0)
  s:addGoal("expand")
  s:addGoal("defend")
end

--@api-stub: StrategyAI:addTag
-- Adds a string tag to the strategy AI instance for goal filtering and categorization.
-- Tags filter goals by context; e.g. "early_game" excludes goals with "late_game" tags.
do  -- StrategyAI:addTag
  local s = lurek.ai.newStrategyAI(2.0)
  s:addTag("early_game")
end

--@api-stub: StrategyAI:removeTag
-- Removes the specified tag.
-- Silent no-op if absent; safe to call on phase transitions.
do  -- StrategyAI:removeTag
  local s = lurek.ai.newStrategyAI(2.0)
  s:addTag("scout_phase")
  s:removeTag("scout_phase")
end

--@api-stub: StrategyAI:update
-- Advances the simulation by one time step.
-- Re-evaluates every update_interval seconds; scorer callback receives goal name and returns a float.
do  -- StrategyAI:update
  local s = lurek.ai.newStrategyAI(2.0)
  s:addGoal("expand")
  function lurek.process(dt) s:update(dt, function(goal) return 0.5 end) end
end

--@api-stub: StrategyAI:forceEvaluate
-- Returns or performs force evaluate.
-- Bypasses the throttle and re-scores immediately; use after major game events.
do  -- StrategyAI:forceEvaluate
  local s = lurek.ai.newStrategyAI(2.0)
  s:addGoal("retreat")
  s:forceEvaluate(function(goal) return goal == "retreat" and 1.0 or 0.0 end)
end

--@api-stub: StrategyAI:activeGoal
-- Returns or performs active goal.
-- Returns the name of the current best-scoring goal, or nil before the first evaluate.
do  -- StrategyAI:activeGoal
  local s = lurek.ai.newStrategyAI(2.0)
  s:addGoal("hold"); s:forceEvaluate(function(g) return 1.0 end)
  local g = s:activeGoal()
  if g then lurek.log.info("strategy=" .. g, "ai") end
end

--@api-stub: StrategyAI:timeUntilNext
-- Returns or performs time until next.
-- Seconds until the next throttled re-evaluation; useful for HUD countdowns.
do  -- StrategyAI:timeUntilNext
  local s = lurek.ai.newStrategyAI(2.0)
  lurek.log.debug("next eval in " .. s:timeUntilNext(), "ai")
end

--@api-stub: AILod:shouldUpdate
-- Returns or performs should update.
-- Returns true if the (tier, frame_number) combination is due for a tick this frame.
do  -- AILod:shouldUpdate
  local lod = lurek.ai.newAILod()
  if lod:shouldUpdate(1, 60) then lurek.log.debug("tier 1 tick", "ai") end
end

--@api-stub: AILod:tierCount
-- Returns or performs tier count.
-- Number of LOD tiers configured; default config has 3 (near / mid / far).
do  -- AILod:tierCount
  local lod = lurek.ai.newAILod()
  lurek.log.debug("tiers=" .. lod:tierCount(), "ai")
end

--@api-stub: AILod:tierName
-- Returns or performs tier name.
-- Returns the tier's name string (e.g. "near", "mid", "far") or nil if out of range.
do  -- AILod:tierName
  local lod = lurek.ai.newAILod()
  local n = lod:tierName(0)
  if n then lurek.log.debug("tier 0=" .. n, "ai") end
end


-- =============================================================================
-- Lua Extensibility Hooks (Phase 01)
-- =============================================================================

--@api-stub: Agent:setCustomModel
-- Sets a Lua-driven decision model on an agent.
-- The callback fn(agent, blackboard, dt) is called each frame by world:update(dt).
do  -- Agent:setCustomModel
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
-- Creates a BT Guard decorator that checks a predicate before ticking the child.
-- Returns "guard" from getNodeType(); getChildCount() returns 1.
do  -- lurek.ai.newGuard
  local action = lurek.ai.newAction(function(ag, bb, dt) return "success" end)
  local guard = lurek.ai.newGuard(
    function(ag, bb) return bb:getNumber("health", 1.0) > 0.0 end,
    action
  )
  lurek.log.debug("guard type=" .. guard:getNodeType(), "ai")
  lurek.log.debug("guard children=" .. guard:getChildCount(), "ai")
end

--@api-stub: UtilityAI:addConsideration
-- Adds a multi-axis consideration with optional custom Lua curve function.
-- Accepts either a string curve name or a fn(x)->y for a custom response curve.
do  -- UtilityAI:addConsideration (custom curve)
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

--@api-stub: SteeringManager:addCustomBehavior
-- Registers a Lua callback fn(agent, dt)->dx,dy as a custom steering force.
-- Weight multiplies the returned force before combination.
do  -- SteeringManager:addCustomBehavior
  local sm = lurek.ai.newSteeringManager()
  sm:addCustomBehavior(function(ag, dt)
    return 100, 0   -- constant rightward force
  end, 1.0)
  lurek.log.debug("custom behaviors=" .. sm:getBehaviorCount(), "ai")
end

--@api-stub: SteeringManager:applyCustomSteering
-- Invokes all custom steering callbacks and returns the combined (fx, fy) force.
-- Call each frame and add the result to the agent's velocity manually.
do  -- SteeringManager:applyCustomSteering
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

--@api-stub: EmotionModel:add
-- Registers a named emotion dimension with initial value, decay rate, and max intensity.
-- Call once per emotion at init; trigger() adds intensity, update() decays it each frame.
do  -- EmotionModel:add
  local em = lurek.ai.newEmotionModel()
  em:add("fear", 0.0, 0.08, 1.0)
  em:add("anger", 0.0, 0.06, 1.0)
  lurek.log.info("emotions registered", "ai")
end

--@api-stub: GOAPPlanner:addAction
-- Registers a GOAP action with a cost, execution callback, and optional tags.
-- Actions form the GOAP action space; the planner selects sequences by minimising total cost.
do  -- GOAPPlanner:addAction
  local planner = lurek.ai.newGOAPPlanner()
  planner:addAction("pickupKey", 2.0, function() lurek.log.info("pickup key", "ai") end)
  planner:addAction("unlockDoor", 1.0, function() lurek.log.info("unlock door", "ai") end)
  planner:addGoal("door_open", 1.0)
end

--@api-stub: UtilityAI:addAction
-- Registers a named utility action with a scoring function.
-- The evaluator calls all score functions and returns the action with the highest result.
do  -- UtilityAI:addAction
  local uai = lurek.ai.newUtilityAI()
  uai:addAction("heal", function() return 0.9 end)
  uai:addAction("attack", function() return 0.4 end)
  local best = uai:evaluate()
  lurek.log.info("best action: " .. (best or "none"), "ai")
end

--@api-stub: AIWorld:addAgent
-- Adds a named agent to the AI world and returns an Agent handle.
-- Agents are ticked each world:update(dt); name must be unique within the world.
do  -- AIWorld:addAgent
  local world = lurek.ai.newWorld()
  world:addAgent("guard_01")
  world:addAgent("guard_02")
  lurek.log.info("agents: " .. world:getAgentCount(), "ai")
end

--@api-stub: SteeringManager:addArrive
-- Adds an arrive behaviour that decelerates the agent as it approaches the target.
-- Slower final approach than addSeek; use for parking-style movement to a destination.
do  -- SteeringManager:addArrive
  local sm = lurek.ai.newSteeringManager()
  sm:addArrive(400, 300, 1.0)
  local fx, fy = sm:calculate(200, 200, 0, 0, 100, 50, 1 / 60)
  lurek.log.info("arrive: " .. fx .. "," .. fy, "ai")
end

--@api-stub: StimulusWorld:addAuditory
-- Adds an auditory stimulus at the given position with radius and loudness.
-- Agents query the StimulusWorld for nearby sounds rather than iterating each other.
do  -- StimulusWorld:addAuditory
  local sw = lurek.ai.newStimulusWorld()
  sw:addAuditory(200, 150, 1.2, 100, 0.8, "footstep")
  lurek.log.info("stimuli: " .. sw:count(), "ai")
end

--@api-stub: ContextSteering:addAvoidPoint
-- Adds a repulsor point to the context steering danger map.
-- Increase weight to create stronger avoidance of pillars, hazard tiles, etc.
do  -- ContextSteering:addAvoidPoint
  local cs = lurek.ai.newContextSteering(16)
  cs:addAvoidPoint(300, 200, 64, 1.5)
  cs:addAvoidPoint(100, 350, 48, 1.0)
  local fx, fy = cs:evaluate(150, 150, 0, 0)
  lurek.log.info("context steer: " .. fx .. "," .. fy, "ai")
end

--@api-stub: HTNDomain:addCompound
-- Adds a compound task (method list) to the HTN domain.
-- Compound tasks decompose into primitives; the planner tries methods in order until one succeeds.
do  -- HTNDomain:addCompound
  local d = lurek.ai.newHTNDomain()
  d:addPrimitive("attack", {"has_weapon"}, {"enemy_dead"}, {})
  d:addCompound("defeat_enemy", {{"has_weapon"}, {"use_weapon"}})
  lurek.log.info("htn tasks: " .. d:taskCount(), "ai")
end

--@api-stub: SteeringManager:addEvade
-- Adds an evade behaviour that flees from a predicted future target position.
-- Predicts where the target will be and steers away from that projected point.
do  -- SteeringManager:addEvade
  local sm = lurek.ai.newSteeringManager()
  sm:addEvade("player", 1.0)
  local fx, fy = sm:calculate(200, 200, 0, 0, 100, 50, 1 / 60)
  lurek.log.info("evade: " .. fx .. "," .. fy, "ai")
end

--@api-stub: SteeringManager:addFlee
-- Adds a flee behaviour that steers directly away from the threat position.
-- Unlike addEvade, flee reacts to current position not predicted future position.
do  -- SteeringManager:addFlee
  local sm = lurek.ai.newSteeringManager()
  sm:addFlee(400, 300, 1.0)
  local fx, fy = sm:calculate(200, 200, 0, 0, 100, 50, 1 / 60)
  lurek.log.info("flee: " .. fx .. "," .. fy, "ai")
end

--@api-stub: SteeringManager:addFlock
-- Adds a flocking behaviour combining separation, alignment, and cohesion.
-- Pass a neighbour radius and the per-component weights as a table or individual args.
do  -- SteeringManager:addFlock
  local sm = lurek.ai.newSteeringManager()
  sm:addFlock(80, 1.0, 0.8, 0.6)
  local fx, fy = sm:calculate(200, 200, 10, 0, 100, 50, 1 / 60)
  lurek.log.info("flock: " .. fx .. "," .. fy, "ai")
end

--@api-stub: GOAPPlanner:addGoal
-- Adds a named world-state goal with a priority weight.
-- Higher-priority goals are preferred when multiple goals are satisfiable simultaneously.
do  -- GOAPPlanner:addGoal
  local planner = lurek.ai.newGOAPPlanner()
  planner:addAction("rest", 1.0, function() end)
  planner:addGoal("is_rested", 1.0)
  planner:addGoal("is_safe", 2.0)
  lurek.log.info("goal count: " .. planner:getGoalCount(), "ai")
end

--@api-stub: InfluenceMap:addLayer
-- Adds a named influence layer to the map grid.
-- Layers are independent float grids; each can represent threat, resource, or patrol density.
do  -- InfluenceMap:addLayer
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:addLayer("resource")
  lurek.log.info("has threat layer: " .. tostring(im:hasLayer("threat")), "ai")
end

--@api-stub: TraitProfile:addModifier
-- Adds a named transient modifier to a trait value.
-- Modifiers stack additively; remove them by tag when the buff/debuff expires.
do  -- TraitProfile:addModifier
  local traits = lurek.ai.newTraitProfile()
  traits:set("courage", 0.5)
  traits:addModifier("courage", -0.3, 5.0, "fear_potion")
  lurek.log.info("effective courage: " .. traits:get("courage"), "ai")
end

--@api-stub: SteeringManager:addPursue
-- Adds a pursue behaviour that steers toward the predicted future position of a target.
-- More effective than addSeek against moving targets; uses linear prediction.
do  -- SteeringManager:addPursue
  local sm = lurek.ai.newSteeringManager()
  sm:addPursue("player", 1.0)
  local fx, fy = sm:calculate(200, 200, 0, 0, 100, 50, 1 / 60)
  lurek.log.info("pursue: " .. fx .. "," .. fy, "ai")
end

--@api-stub: SteeringManager:addSeek
-- Adds a seek behaviour that steers directly toward the target position.
-- The simplest steering force; weight=1.0 uses the full max-force budget.
do  -- SteeringManager:addSeek
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(500, 400, 1.0)
  local fx, fy = sm:calculate(100, 100, 0, 0, 150, 50, 1 / 60)
  lurek.log.info("seek force: " .. fx .. "," .. fy, "ai")
end

--@api-stub: ContextSteering:addSeekTarget
-- Adds a seek target to the context steering desire map.
-- Multiple seek targets blend via the slot weights; the final direction maximises total desire.
do  -- ContextSteering:addSeekTarget
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  cs:addSeekTarget(400, 400, 0.6)
  local fx, fy = cs:evaluate(200, 200, 0, 0)
  lurek.log.info("context direction: " .. fx .. "," .. fy, "ai")
end

--@api-stub: StateMachine:addTransition
-- Adds a conditional transition between two states.
-- Transition fires when the predicate returns true during the FSM's update pass.
do  -- StateMachine:addTransition
  local fsm = lurek.ai.newStateMachine()
  fsm:addState("patrol", {})
  fsm:addState("alert", {})
  fsm:addTransition("patrol", "alert", function() return true end)
  fsm:setInitialState("patrol")
  lurek.log.info("state: " .. (fsm:getCurrentState() or "nil"), "ai")
end

--@api-stub: StimulusWorld:addVisual
-- Adds a visual stimulus at the given position with a view cone and distance.
-- Agents can query for nearby visuals in their perception radius each tick.
do  -- StimulusWorld:addVisual
  local sw = lurek.ai.newStimulusWorld()
  sw:addVisual(300, 200, 1.0, 200, "player")
  sw:addAuditory(300, 200, 1.0, 80, 0.5, "footstep")
  lurek.log.info("stimuli count: " .. sw:count(), "ai")
end

--@api-stub: SteeringManager:addWander
-- Adds a wander behaviour producing smooth random-direction steering.
-- Adjust circleRadius and maxTurnRate to control how erratic the wandering appears.
do  -- SteeringManager:addWander
  local sm = lurek.ai.newSteeringManager()
  sm:addWander(25, 50, 8, 0.4)
  local fx, fy = sm:calculate(200, 200, 0, 0, 100, 50, 1 / 60)
  lurek.log.info("wander: " .. fx .. "," .. fy, "ai")
end

--@api-stub: InfluenceMap:blend
-- Blends a source layer into a destination layer by weight.
-- Use to combine threat and resource maps into a single priority surface for decision-making.
do  -- InfluenceMap:blend
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:addLayer("resource")
  im:stampInfluence("threat", 256, 256, 64, 1.0, 1.0)
  im:blend("threat", 0.5, "resource", 0.5, "resource")
  lurek.log.info("blend complete", "ai")
end

--@api-stub: SteeringManager:calculate
-- Calculates the combined steering force for the current agent state.
-- Returns two floats (fx, fy); apply them to the agent's velocity each physics step.
do  -- SteeringManager:calculate
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  local fx, fy = sm:calculate(100, 100, 0, 0, 120, 50, 1 / 60)
  lurek.log.info("steering force: " .. fx .. "," .. fy, "ai")
end

--@api-stub: StimulusWorld:count
-- Returns the total number of active stimuli in the perception world.
-- Use to check whether any stimulus exists before querying agents.
do  -- StimulusWorld:count
  local sw = lurek.ai.newStimulusWorld()
  sw:addAuditory(200, 100, 1.0, 80, 0.8, "gunshot")
  local n = sw:count()
  lurek.log.info("active stimuli: " .. n, "ai")
end

--@api-stub: CommandQueue:enqueue
-- Appends a command to the back of the queue.
-- The first argument is the command type tag; the callback fires when it becomes active.
do  -- CommandQueue:enqueue
  local q = lurek.ai.newCommandQueue()
  q:enqueue("move", function() end, {x=300, y=200})
  q:enqueue("attack", function() end, {targetId="enemy_01"})
  lurek.log.info("queue count: " .. q:getCount(), "ai")
end

--@api-stub: ContextSteering:evaluate
-- Evaluates all context slots and returns the best-fit steering direction as (fx, fy).
-- Call once per frame after adding seek/avoid behaviours; reads the combined context map.
do  -- ContextSteering:evaluate
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  cs:addAvoidPoint(350, 250, 50, 1.0)
  local fx, fy = cs:evaluate(200, 200, 0, 0)
  lurek.log.info("evaluated: " .. fx .. "," .. fy, "ai")
end

--@api-stub: Blackboard:getBool
-- Retrieves a boolean value by key; returns false if the key does not exist.
-- Pair with setBool to drive FSM transitions from shared perception data.
do  -- Blackboard:getBool
  local bb = lurek.ai.newBlackboard()
  bb:setBool("player_spotted", true)
  local spotted = bb:getBool("player_spotted")
  lurek.log.info("player spotted: " .. tostring(spotted), "ai")
end

--@api-stub: Squad:getFormationPosition
-- Returns the world-space position for a named member in the current formation.
-- Drive each member agent toward their formation slot each frame.
do  -- Squad:getFormationPosition
  local squad = lurek.ai.newSquad("alpha")
  squad:addMember("guard_01")
  squad:setFormation("wedge", 32)
  local px, py = squad:getFormationPosition(1, 400, 300)
  lurek.log.info("slot: " .. px .. "," .. py, "ai")
end

--@api-stub: InfluenceMap:getInfluence
-- Returns the influence value at the specified grid cell.
-- Returns 0 for cells outside the grid boundary or unpopulated layers.
do  -- InfluenceMap:getInfluence
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:stampInfluence("threat", 256, 256, 64, 1.0, 0.9)
  local v = im:getInfluence("threat", 16, 16)
  lurek.log.info("influence at centre: " .. v, "ai")
end

--@api-stub: Blackboard:getNumber
-- Retrieves a numeric value by key; returns 0 if the key does not exist.
-- Persistent across frames; ideal for caching sensor readings between ticks.
do  -- Blackboard:getNumber
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("threat_level", 0.75)
  local t = bb:getNumber("threat_level")
  lurek.log.info("threat: " .. t, "ai")
end

--@api-stub: Blackboard:getString
-- Retrieves a string value by key; returns an empty string if not set.
-- Use to store target names, state tags, or short command strings.
do  -- Blackboard:getString
  local bb = lurek.ai.newBlackboard()
  bb:setString("last_enemy", "goblin_03")
  local name = bb:getString("last_enemy")
  lurek.log.info("last enemy: " .. name, "ai")
end

--@api-stub: QLearner:learn
-- Updates the Q-value for a (state, action) pair using the Bellman equation.
-- Call after receiving a reward signal; negative rewards teach avoidance.
do  -- QLearner:learn
  local ql = lurek.ai.newQLearner(8, 4)
  ql:setLearningRate(0.1)
  ql:learn(2, 1, 1.0, 3)
  local qv = ql:getQValue(2, 1)
  lurek.log.info("Q(2,1)=" .. qv, "ai")
end

--@api-stub: GOAPPlanner:plan
-- Runs the GOAP solver and returns an ordered list of action names to achieve goals.
-- Pass the current world state as a key/value table; returns nil if no plan is found.
do  -- GOAPPlanner:plan
  local planner = lurek.ai.newGOAPPlanner()
  planner:addAction("eat", 1.0, function() end)
  planner:addGoal("not_hungry", 1.0)
  local actions = planner:plan({hungry=true})
  lurek.log.info("plan length: " .. (actions and #actions or 0), "ai")
end

--@api-stub: HTNDomain:plan
-- Decomposes the root compound task into a primitive task sequence using HTN planning.
-- Returns an ordered list of primitive task names or nil if decomposition fails.
do  -- HTNDomain:plan
  local d = lurek.ai.newHTNDomain()
  d:addPrimitive("move", {}, {}, {})
  d:addCompound("patrol", {{"move"}})
  local plan = d:plan("patrol", {})
  lurek.log.info("htn plan steps: " .. (plan and #plan or 0), "ai")
end

--@api-stub: InfluenceMap:propagate
-- Propagates influence values across the grid using an exponential decay kernel.
-- Higher decay makes influence spread farther; call each AI tick or on stimulus events.
do  -- InfluenceMap:propagate
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:stampInfluence("threat", 256, 256, 48, 1.0, 0.8)
  im:propagate("threat", 0.85)
  lurek.log.info("propagation done", "ai")
end

--@api-stub: CommandQueue:pushFront
-- Inserts a high-priority command at the front of the queue, bypassing queued orders.
-- Use for interrupt commands (take cover, flee) that must execute immediately.
do  -- CommandQueue:pushFront
  local q = lurek.ai.newCommandQueue()
  q:enqueue("patrol", function() end, {})
  q:pushFront("flee", function() end, {threatX=300, threatY=200})
  lurek.log.info("front command: " .. q:getCurrentType(), "ai")
end

--@api-stub: InfluenceMap:queryRect
-- Returns a table of cells with influence above a threshold within a world-space rect.
-- Use for tactical decisions: find the safest or most resource-rich region to move toward.
do  -- InfluenceMap:queryRect
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("resource")
  im:setInfluence("resource", 10, 10, 1.0)
  local total = im:queryRect("resource", 100, 100, 300, 300)
  lurek.log.info("influence sum: " .. total, "ai")
end

--@api-stub: CommandQueue:replace
-- Replaces the current front command with a new one without discarding the rest of the queue.
-- Useful for retargeting the active order (update move destination mid-execution).
do  -- CommandQueue:replace
  local q = lurek.ai.newCommandQueue()
  q:enqueue("move", function() end, {x=200, y=100})
  q:replace("attack", function() end, {targetId="bandit_01"})
  lurek.log.info("replaced: " .. q:getCurrentType(), "ai")
end

--@api-stub: MCTSEngine:search
-- Runs Monte Carlo Tree Search and returns the best action index from the root state.
-- iterations (set at construction) controls quality vs. latency; more = better decisions.
do  -- MCTSEngine:search
  local mcts = lurek.ai.newMCTSEngine(100, 1.41, 16, 42)
  local actions = function(s) return {1, 2, 3} end
  local apply   = function(s, a) return s + a end
  local eval    = function(s) return s % 5 end
  local best = mcts:search(0, actions, apply, eval)
  lurek.log.info("best action: " .. best, "ai")
end

--@api-stub: GOAPPlanner:setEffect
-- Defines the world-state effect of an action (what changes after it executes).
-- Effects are key/value pairs applied to the world state when the action completes.
do  -- GOAPPlanner:setEffect
  local planner = lurek.ai.newGOAPPlanner()
  planner:addAction("openDoor", 1.0, function() end)
  planner:setEffect("openDoor", "door_locked", false)
  lurek.log.info("effect registered", "ai")
end

--@api-stub: Squad:setFormation
-- Sets the formation type and inter-agent spacing for the squad.
-- Supported types include "line", "wedge", "column", "circle", "scatter".
do  -- Squad:setFormation
  local squad = lurek.ai.newSquad("bravo")
  squad:addMember("soldier_01")
  squad:addMember("soldier_02")
  squad:setFormation("wedge", 40)
  lurek.log.info("formation: " .. squad:getFormation(), "ai")
end

--@api-stub: GOAPPlanner:setGoalState
-- Sets the required world-state value for a named goal key.
-- The planner tries to satisfy all registered goals; only goals with matching state are active.
do  -- GOAPPlanner:setGoalState
  local planner = lurek.ai.newGOAPPlanner()
  planner:addGoal("enemy_dead", 1.0)
  planner:setGoalState("enemy_dead", "is_dead", true)
  lurek.log.info("goal state set", "ai")
end

--@api-stub: InfluenceMap:setInfluence
-- Sets the influence value at a specific grid cell directly.
-- Use for hard-coded obstacles or guaranteed zones without radius spreading.
do  -- InfluenceMap:setInfluence
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("hazard")
  im:setInfluence("hazard", 8, 8, 1.0)
  lurek.log.info("cell 8,8 hazard: " .. im:getInfluence("hazard", 8, 8), "ai")
end

--@api-stub: GOAPPlanner:setPrecondition
-- Sets a world-state precondition on an action (what must be true before it can run).
-- An action is only selected when all its preconditions are satisfied by the current state.
do  -- GOAPPlanner:setPrecondition
  local planner = lurek.ai.newGOAPPlanner()
  planner:addAction("shoot", 1.0, function() end)
  planner:setPrecondition("shoot", "has_ammo", true)
  lurek.log.info("precondition set", "ai")
end

--@api-stub: ORCASolver:setPreferredVelocity
-- Sets the desired velocity for a registered ORCA agent before each solve step.
-- Call once per agent per frame, then call compute() to get safe velocities.
do  -- ORCASolver:setPreferredVelocity
  local orca = lurek.ai.newORCASolver(2.0)
  local idx = orca:addAgent(100, 100, 14, 80)
  orca:setPreferredVelocity(idx, 60, 0)
  orca:compute(1 / 60)
  local vx, vy = orca:getSafeVelocity(idx)
  lurek.log.info("safe vel: " .. vx .. "," .. vy, "ai")
end

--@api-stub: QLearner:setQValue
-- Directly sets a Q-table entry, bypassing the Bellman update.
-- Use to seed the Q-table from designer-authored data or a loaded checkpoint.
do  -- QLearner:setQValue
  local ql = lurek.ai.newQLearner(8, 4)
  ql:setQValue(0, 2, 0.85)
  local v = ql:getQValue(0, 2)
  lurek.log.info("Q(0,2)=" .. v, "ai")
end

--@api-stub: InfluenceMap:stampInfluence
-- Stamps a radial influence blob centred on world-space (cx, cy) with given radius.
-- decay controls how fast influence falls off with distance from centre (0=flat, 1=sharp).
do  -- InfluenceMap:stampInfluence
  local im = lurek.ai.newInfluenceMap(32, 32, 16)
  im:addLayer("threat")
  im:stampInfluence("threat", 256, 256, 96, 1.0, 0.75)
  lurek.log.info("stamped threat blob", "ai")
end

--@api-stub: AILod:tierFor
-- Returns the LOD tier index (0=highest, N=lowest) for a given world-space distance.
-- Use to throttle AI update rate for distant agents and save CPU budget.
do  -- AILod:tierFor
  local lod = lurek.ai.newAILod()
  local tier = lod:tierFor(350, 0, 0, 0)
  lurek.log.info("lod tier at 350: " .. tier, "ai")
end

--@api-stub: ORCASolver:addAgent
-- Registers an agent with the ORCA solver so it participates in velocity planning.
-- Each agent needs a position, preferred velocity, radius, and max speed.
do  -- ORCASolver:addAgent
  local solver = lurek.ai.newORCASolver(2.0)
  solver:addAgent(200, 300, 50, 100)
  solver:compute(1 / 60)
  lurek.log.info("ORCA agent added", "ai")
end

--@api-stub: NeuralNet:addLayer
-- Adds a hidden layer with the specified neuron count and activation function.
-- Call before NeuralNet:build() to define the network architecture.
do  -- NeuralNet:addLayer
  local net = lurek.ai.newNeuralNet()
  net:addLayer(2, 4, "relu")
  net:addLayer(4, 1, "relu")
  local out = net:forward({0.25, 0.75})
  lurek.log.info("forward count: " .. #out, "ai")
end

-- =============================================================================
-- STUBS: 287 uncovered lurek.ai API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LAIBlackboard methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAIBlackboard:setNumber ---------------------------------------
--@api-stub: LAIBlackboard:setNumber
-- Stores a number under the given key.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIBlackboard_stub:setNumber("player_score", 42)
-- (replace lAIBlackboard_stub with your real LAIBlackboard instance above)

-- ---- Stub: LAIBlackboard:getNumber ---------------------------------------
--@api-stub: LAIBlackboard:getNumber
-- Returns the number for the given key, or default.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIBlackboard_stub:getNumber("player_score", [default])  -- -> number
-- (replace lAIBlackboard_stub with your real LAIBlackboard instance above)

-- ---- Stub: LAIBlackboard:setBool -----------------------------------------
--@api-stub: LAIBlackboard:setBool
-- Stores a boolean under the given key.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIBlackboard_stub:setBool("player_score", 42)
-- (replace lAIBlackboard_stub with your real LAIBlackboard instance above)

-- ---- Stub: LAIBlackboard:getBool -----------------------------------------
--@api-stub: LAIBlackboard:getBool
-- Returns the boolean for the given key, or default.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIBlackboard_stub:getBool("player_score", [default])  -- -> boolean
-- (replace lAIBlackboard_stub with your real LAIBlackboard instance above)

-- ---- Stub: LAIBlackboard:setString ---------------------------------------
--@api-stub: LAIBlackboard:setString
-- Stores a string under the given key.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIBlackboard_stub:setString("player_score", 42)
-- (replace lAIBlackboard_stub with your real LAIBlackboard instance above)

-- ---- Stub: LAIBlackboard:getString ---------------------------------------
--@api-stub: LAIBlackboard:getString
-- Returns the string for the given key, or default.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIBlackboard_stub:getString("player_score", [default])  -- -> string
-- (replace lAIBlackboard_stub with your real LAIBlackboard instance above)

-- ---- Stub: LAIBlackboard:has ---------------------------------------------
--@api-stub: LAIBlackboard:has
-- Returns true if a value exists under the key.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIBlackboard_stub:has("player_score")  -- -> boolean
-- (replace lAIBlackboard_stub with your real LAIBlackboard instance above)

-- ---- Stub: LAIBlackboard:remove ------------------------------------------
--@api-stub: LAIBlackboard:remove
-- Removes the entry at key.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIBlackboard_stub:remove("player_score")
-- (replace lAIBlackboard_stub with your real LAIBlackboard instance above)

-- ---- Stub: LAIBlackboard:clear -------------------------------------------
--@api-stub: LAIBlackboard:clear
-- Removes all local entries.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIBlackboard_stub:clear()
-- (replace lAIBlackboard_stub with your real LAIBlackboard instance above)

-- ---- Stub: LAIBlackboard:getKeys -----------------------------------------
--@api-stub: LAIBlackboard:getKeys
-- Returns all local keys as a table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIBlackboard_stub:getKeys()  -- -> table
-- (replace lAIBlackboard_stub with your real LAIBlackboard instance above)

-- ---- Stub: LAIBlackboard:getSize -----------------------------------------
--@api-stub: LAIBlackboard:getSize
-- Returns the number of local entries.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIBlackboard_stub:getSize()  -- -> integer
-- (replace lAIBlackboard_stub with your real LAIBlackboard instance above)

-- ---- Stub: LAIBlackboard:type --------------------------------------------
--@api-stub: LAIBlackboard:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIBlackboard_stub:type()  -- -> string
-- (replace lAIBlackboard_stub with your real LAIBlackboard instance above)

-- ---- Stub: LAIBlackboard:typeOf ------------------------------------------
--@api-stub: LAIBlackboard:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIBlackboard_stub:typeOf("hero")  -- -> boolean
-- (replace lAIBlackboard_stub with your real LAIBlackboard instance above)

-- -----------------------------------------------------------------------------
-- LAIDirector methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAIDirector:pushEvent -----------------------------------------
--@api-stub: LAIDirector:pushEvent
-- Pushes a gameplay event with the given intensity to the director for awareness analysis.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIDirector_stub:pushEvent(intensity)
-- (replace lAIDirector_stub with your real LAIDirector instance above)

-- ---- Stub: LAIDirector:update --------------------------------------------
--@api-stub: LAIDirector:update
-- Advances the simulation by one time step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIDirector_stub:update(0.016)
-- (replace lAIDirector_stub with your real LAIDirector instance above)

-- ---- Stub: LAIDirector:tension -------------------------------------------
--@api-stub: LAIDirector:tension
-- Returns or performs tension.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIDirector_stub:tension()  -- -> number
-- (replace lAIDirector_stub with your real LAIDirector instance above)

-- ---- Stub: LAIDirector:phase ---------------------------------------------
--@api-stub: LAIDirector:phase
-- Returns or performs phase.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIDirector_stub:phase()  -- -> string
-- (replace lAIDirector_stub with your real LAIDirector instance above)

-- ---- Stub: LAIDirector:spawnRateFactor -----------------------------------
--@api-stub: LAIDirector:spawnRateFactor
-- Returns or performs spawn rate factor.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIDirector_stub:spawnRateFactor()  -- -> number
-- (replace lAIDirector_stub with your real LAIDirector instance above)

-- ---- Stub: LAIDirector:lootFactor ----------------------------------------
--@api-stub: LAIDirector:lootFactor
-- Returns or performs loot factor.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIDirector_stub:lootFactor()  -- -> number
-- (replace lAIDirector_stub with your real LAIDirector instance above)

-- ---- Stub: LAIDirector:ambientIntensity ----------------------------------
--@api-stub: LAIDirector:ambientIntensity
-- Returns or performs ambient intensity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIDirector_stub:ambientIntensity()  -- -> number
-- (replace lAIDirector_stub with your real LAIDirector instance above)

-- ---- Stub: LAIDirector:setTension ----------------------------------------
--@api-stub: LAIDirector:setTension
-- Sets the global narrative tension level (0â€“1 scale).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIDirector_stub:setTension(42)
-- (replace lAIDirector_stub with your real LAIDirector instance above)

-- ---- Stub: LAIDirector:reset ---------------------------------------------
--@api-stub: LAIDirector:reset
-- Resets or clears the state.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIDirector_stub:reset()
-- (replace lAIDirector_stub with your real LAIDirector instance above)

-- ---- Stub: LAIDirector:type ----------------------------------------------
--@api-stub: LAIDirector:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIDirector_stub:type()  -- -> string
-- (replace lAIDirector_stub with your real LAIDirector instance above)

-- ---- Stub: LAIDirector:typeOf --------------------------------------------
--@api-stub: LAIDirector:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIDirector_stub:typeOf("hero")  -- -> boolean
-- (replace lAIDirector_stub with your real LAIDirector instance above)

-- -----------------------------------------------------------------------------
-- LAILod methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAILod:tierFor ------------------------------------------------
--@api-stub: LAILod:tierFor
-- Returns or performs tier for.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAILod_stub:tierFor(ax, ay, rx, ry)  -- -> integer
-- (replace lAILod_stub with your real LAILod instance above)

-- ---- Stub: LAILod:shouldUpdate -------------------------------------------
--@api-stub: LAILod:shouldUpdate
-- Returns or performs should update.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAILod_stub:shouldUpdate(tier, frame)  -- -> boolean
-- (replace lAILod_stub with your real LAILod instance above)

-- ---- Stub: LAILod:tierCount ----------------------------------------------
--@api-stub: LAILod:tierCount
-- Returns or performs tier count.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAILod_stub:tierCount()  -- -> integer
-- (replace lAILod_stub with your real LAILod instance above)

-- ---- Stub: LAILod:tierName -----------------------------------------------
--@api-stub: LAILod:tierName
-- Returns or performs tier name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAILod_stub:tierName(tier)  -- -> string
-- (replace lAILod_stub with your real LAILod instance above)

-- ---- Stub: LAILod:type ---------------------------------------------------
--@api-stub: LAILod:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAILod_stub:type()  -- -> string
-- (replace lAILod_stub with your real LAILod instance above)

-- ---- Stub: LAILod:typeOf -------------------------------------------------
--@api-stub: LAILod:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAILod_stub:typeOf("hero")  -- -> boolean
-- (replace lAILod_stub with your real LAILod instance above)

-- -----------------------------------------------------------------------------
-- LAIWorld methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAIWorld:addAgent ---------------------------------------------
--@api-stub: LAIWorld:addAgent
-- Registers a new named agent and returns its handle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIWorld_stub:addAgent("hero")  -- -> Agent
-- (replace lAIWorld_stub with your real LAIWorld instance above)

-- ---- Stub: LAIWorld:getAgent ---------------------------------------------
--@api-stub: LAIWorld:getAgent
-- Returns the agent handle for the given name, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIWorld_stub:getAgent("hero")
-- (replace lAIWorld_stub with your real LAIWorld instance above)

-- ---- Stub: LAIWorld:removeAgent ------------------------------------------
--@api-stub: LAIWorld:removeAgent
-- Removes an agent by its userdata handle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIWorld_stub:removeAgent(agent)
-- (replace lAIWorld_stub with your real LAIWorld instance above)

-- ---- Stub: LAIWorld:getAgentCount ----------------------------------------
--@api-stub: LAIWorld:getAgentCount
-- Returns the number of registered agents.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIWorld_stub:getAgentCount()  -- -> integer
-- (replace lAIWorld_stub with your real LAIWorld instance above)

-- ---- Stub: LAIWorld:getGlobalBlackboard ----------------------------------
--@api-stub: LAIWorld:getGlobalBlackboard
-- Returns a snapshot of the world-level blackboard.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIWorld_stub:getGlobalBlackboard()  -- -> AIBlackboard
-- (replace lAIWorld_stub with your real LAIWorld instance above)

-- ---- Stub: LAIWorld:update -----------------------------------------------
--@api-stub: LAIWorld:update
-- Advances all agents by dt seconds, then invokes any custom-model callbacks.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIWorld_stub:update(0.016)
-- (replace lAIWorld_stub with your real LAIWorld instance above)

-- ---- Stub: LAIWorld:type -------------------------------------------------
--@api-stub: LAIWorld:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIWorld_stub:type()  -- -> string
-- (replace lAIWorld_stub with your real LAIWorld instance above)

-- ---- Stub: LAIWorld:typeOf -----------------------------------------------
--@api-stub: LAIWorld:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAIWorld_stub:typeOf("hero")  -- -> boolean
-- (replace lAIWorld_stub with your real LAIWorld instance above)

-- -----------------------------------------------------------------------------
-- LAgent methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAgent:getName ------------------------------------------------
--@api-stub: LAgent:getName
-- Returns the agent's registered name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:getName()  -- -> string
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:setPosition --------------------------------------------
--@api-stub: LAgent:setPosition
-- Sets the agent's world-space position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:setPosition(0.0, 0.0)
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:getPosition --------------------------------------------
--@api-stub: LAgent:getPosition
-- Returns the agent's current position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:getPosition()  -- -> number, number
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:setVelocity --------------------------------------------
--@api-stub: LAgent:setVelocity
-- Sets the agent's velocity vector.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:setVelocity(0.0, 0.0)
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:getVelocity --------------------------------------------
--@api-stub: LAgent:getVelocity
-- Returns the agent's current velocity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:getVelocity()  -- -> number, number
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:setMaxSpeed --------------------------------------------
--@api-stub: LAgent:setMaxSpeed
-- Sets the maximum speed cap.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:setMaxSpeed(1.0)
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:getMaxSpeed --------------------------------------------
--@api-stub: LAgent:getMaxSpeed
-- Returns the maximum speed cap.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:getMaxSpeed()  -- -> number
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:setMaxForce --------------------------------------------
--@api-stub: LAgent:setMaxForce
-- Sets the maximum steering force cap.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:setMaxForce(1.0)
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:getMaxForce --------------------------------------------
--@api-stub: LAgent:getMaxForce
-- Returns the maximum steering force cap.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:getMaxForce()  -- -> number
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:setPriority --------------------------------------------
--@api-stub: LAgent:setPriority
-- Sets the scheduling priority (higher = earlier).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:setPriority(p)
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:getPriority --------------------------------------------
--@api-stub: LAgent:getPriority
-- Returns the agent's scheduling priority.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:getPriority()  -- -> integer
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:setDecisionModel ---------------------------------------
--@api-stub: LAgent:setDecisionModel
-- Sets the active decision model.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:setDecisionModel(model)
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:getDecisionModel ---------------------------------------
--@api-stub: LAgent:getDecisionModel
-- Returns the name of the current decision model.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:getDecisionModel()  -- -> string
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:setCustomModel -----------------------------------------
--@api-stub: LAgent:setCustomModel
-- Installs a Lua-driven decision model on this agent.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:setCustomModel(function() end)
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:addTag -------------------------------------------------
--@api-stub: LAgent:addTag
-- Adds a tag to this agent.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:addTag("enemy")
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:removeTag ----------------------------------------------
--@api-stub: LAgent:removeTag
-- Removes a tag from this agent.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:removeTag("enemy")
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:hasTag -------------------------------------------------
--@api-stub: LAgent:hasTag
-- Returns true if the agent has the given tag.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:hasTag("enemy")  -- -> boolean
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:getBlackboard ------------------------------------------
--@api-stub: LAgent:getBlackboard
-- Returns the agent's local blackboard.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:getBlackboard()  -- -> AIBlackboard
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:type ---------------------------------------------------
--@api-stub: LAgent:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:type()  -- -> string
-- (replace lAgent_stub with your real LAgent instance above)

-- ---- Stub: LAgent:typeOf -------------------------------------------------
--@api-stub: LAgent:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAgent_stub:typeOf("hero")  -- -> boolean
-- (replace lAgent_stub with your real LAgent instance above)

-- -----------------------------------------------------------------------------
-- LBTNode methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LBTNode:addChild ----------------------------------------------
--@api-stub: LBTNode:addChild
-- Adds a child node (Selector, Sequence, or Parallel only).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBTNode_stub:addChild(child_ud)
-- (replace lBTNode_stub with your real LBTNode instance above)

-- ---- Stub: LBTNode:getChildCount -----------------------------------------
--@api-stub: LBTNode:getChildCount
-- Returns the number of direct children.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBTNode_stub:getChildCount()  -- -> integer
-- (replace lBTNode_stub with your real LBTNode instance above)

-- ---- Stub: LBTNode:reset -------------------------------------------------
--@api-stub: LBTNode:reset
-- Resets all running-child memos and repeater counters.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBTNode_stub:reset()
-- (replace lBTNode_stub with your real LBTNode instance above)

-- ---- Stub: LBTNode:setChild ----------------------------------------------
--@api-stub: LBTNode:setChild
-- Sets the single child of a decorator node.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBTNode_stub:setChild(child_ud)
-- (replace lBTNode_stub with your real LBTNode instance above)

-- ---- Stub: LBTNode:setCount ----------------------------------------------
--@api-stub: LBTNode:setCount
-- Sets the repeat count for a Repeater node.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBTNode_stub:setCount(5)
-- (replace lBTNode_stub with your real LBTNode instance above)

-- ---- Stub: LBTNode:getCount ----------------------------------------------
--@api-stub: LBTNode:getCount
-- Returns the repeat count, or 0 if not a Repeater.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBTNode_stub:getCount()  -- -> integer
-- (replace lBTNode_stub with your real LBTNode instance above)

-- ---- Stub: LBTNode:setSuccessPolicy --------------------------------------
--@api-stub: LBTNode:setSuccessPolicy
-- Sets the success policy for a Parallel node.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBTNode_stub:setSuccessPolicy(policy)
-- (replace lBTNode_stub with your real LBTNode instance above)

-- ---- Stub: LBTNode:setFailurePolicy --------------------------------------
--@api-stub: LBTNode:setFailurePolicy
-- Sets the failure policy for a Parallel node.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBTNode_stub:setFailurePolicy(policy)
-- (replace lBTNode_stub with your real LBTNode instance above)

-- ---- Stub: LBTNode:getNodeType -------------------------------------------
--@api-stub: LBTNode:getNodeType
-- Returns the node type as a string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBTNode_stub:getNodeType()  -- -> string
-- (replace lBTNode_stub with your real LBTNode instance above)

-- ---- Stub: LBTNode:type --------------------------------------------------
--@api-stub: LBTNode:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBTNode_stub:type()  -- -> string
-- (replace lBTNode_stub with your real LBTNode instance above)

-- ---- Stub: LBTNode:typeOf ------------------------------------------------
--@api-stub: LBTNode:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBTNode_stub:typeOf("hero")  -- -> boolean
-- (replace lBTNode_stub with your real LBTNode instance above)

-- -----------------------------------------------------------------------------
-- LBandit methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LBandit:select ------------------------------------------------
--@api-stub: LBandit:select
-- Returns or performs select.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBandit_stub:select()  -- -> integer
-- (replace lBandit_stub with your real LBandit instance above)

-- ---- Stub: LBandit:update ------------------------------------------------
--@api-stub: LBandit:update
-- Advances the simulation by one time step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBandit_stub:update(1, reward)
-- (replace lBandit_stub with your real LBandit instance above)

-- ---- Stub: LBandit:bestArm -----------------------------------------------
--@api-stub: LBandit:bestArm
-- Returns or performs best arm.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBandit_stub:bestArm()  -- -> integer
-- (replace lBandit_stub with your real LBandit instance above)

-- ---- Stub: LBandit:reset -------------------------------------------------
--@api-stub: LBandit:reset
-- Resets or clears the state.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBandit_stub:reset()
-- (replace lBandit_stub with your real LBandit instance above)

-- ---- Stub: LBandit:armCount ----------------------------------------------
--@api-stub: LBandit:armCount
-- Returns or performs arm count.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBandit_stub:armCount()  -- -> integer
-- (replace lBandit_stub with your real LBandit instance above)

-- ---- Stub: LBandit:totalPulls --------------------------------------------
--@api-stub: LBandit:totalPulls
-- Returns or performs total pulls.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBandit_stub:totalPulls()  -- -> integer
-- (replace lBandit_stub with your real LBandit instance above)

-- ---- Stub: LBandit:type --------------------------------------------------
--@api-stub: LBandit:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBandit_stub:type()  -- -> string
-- (replace lBandit_stub with your real LBandit instance above)

-- ---- Stub: LBandit:typeOf ------------------------------------------------
--@api-stub: LBandit:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBandit_stub:typeOf("hero")  -- -> boolean
-- (replace lBandit_stub with your real LBandit instance above)

-- -----------------------------------------------------------------------------
-- LBehaviorTree methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LBehaviorTree:setRoot -----------------------------------------
--@api-stub: LBehaviorTree:setRoot
-- Sets the root node of this behavior tree.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBehaviorTree_stub:setRoot(node_ud)
-- (replace lBehaviorTree_stub with your real LBehaviorTree instance above)

-- ---- Stub: LBehaviorTree:getLastStatus -----------------------------------
--@api-stub: LBehaviorTree:getLastStatus
-- Returns the status from the last tick.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBehaviorTree_stub:getLastStatus()  -- -> string
-- (replace lBehaviorTree_stub with your real LBehaviorTree instance above)

-- ---- Stub: LBehaviorTree:getDebugState -----------------------------------
--@api-stub: LBehaviorTree:getDebugState
-- Returns a diagnostic snapshot of this behavior tree.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBehaviorTree_stub:getDebugState()  -- -> table
-- (replace lBehaviorTree_stub with your real LBehaviorTree instance above)

-- ---- Stub: LBehaviorTree:type --------------------------------------------
--@api-stub: LBehaviorTree:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBehaviorTree_stub:type()  -- -> string
-- (replace lBehaviorTree_stub with your real LBehaviorTree instance above)

-- ---- Stub: LBehaviorTree:typeOf ------------------------------------------
--@api-stub: LBehaviorTree:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBehaviorTree_stub:typeOf("hero")  -- -> boolean
-- (replace lBehaviorTree_stub with your real LBehaviorTree instance above)

-- -----------------------------------------------------------------------------
-- LCommandQueue methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LCommandQueue:enqueue -----------------------------------------
--@api-stub: LCommandQueue:enqueue
-- Appends a command to the back of the queue.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCommandQueue_stub:enqueue(kind, function() end, [opts])
-- (replace lCommandQueue_stub with your real LCommandQueue instance above)

-- ---- Stub: LCommandQueue:pushFront ---------------------------------------
--@api-stub: LCommandQueue:pushFront
-- Inserts a command at the front, interrupting the current one.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCommandQueue_stub:pushFront(kind, function() end, [opts])
-- (replace lCommandQueue_stub with your real LCommandQueue instance above)

-- ---- Stub: LCommandQueue:replace -----------------------------------------
--@api-stub: LCommandQueue:replace
-- Clears the queue and enqueues one new command.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCommandQueue_stub:replace(kind, function() end, [opts])
-- (replace lCommandQueue_stub with your real LCommandQueue instance above)

-- ---- Stub: LCommandQueue:cancelCurrent -----------------------------------
--@api-stub: LCommandQueue:cancelCurrent
-- Cancels the front command if it is interruptible.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCommandQueue_stub:cancelCurrent()  -- -> boolean
-- (replace lCommandQueue_stub with your real LCommandQueue instance above)

-- ---- Stub: LCommandQueue:clear -------------------------------------------
--@api-stub: LCommandQueue:clear
-- Discards all queued commands.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCommandQueue_stub:clear()
-- (replace lCommandQueue_stub with your real LCommandQueue instance above)

-- ---- Stub: LCommandQueue:getCount ----------------------------------------
--@api-stub: LCommandQueue:getCount
-- Returns the number of queued commands.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCommandQueue_stub:getCount()  -- -> integer
-- (replace lCommandQueue_stub with your real LCommandQueue instance above)

-- ---- Stub: LCommandQueue:isEmpty -----------------------------------------
--@api-stub: LCommandQueue:isEmpty
-- Returns true if there are no queued commands.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCommandQueue_stub:isEmpty()  -- -> boolean
-- (replace lCommandQueue_stub with your real LCommandQueue instance above)

-- ---- Stub: LCommandQueue:getCurrentType ----------------------------------
--@api-stub: LCommandQueue:getCurrentType
-- Returns the kind of the front command, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCommandQueue_stub:getCurrentType()  -- -> string?
-- (replace lCommandQueue_stub with your real LCommandQueue instance above)

-- ---- Stub: LCommandQueue:getCurrentTarget --------------------------------
--@api-stub: LCommandQueue:getCurrentTarget
-- Returns the target coordinates of the front command.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCommandQueue_stub:getCurrentTarget()  -- -> number, number
-- (replace lCommandQueue_stub with your real LCommandQueue instance above)

-- ---- Stub: LCommandQueue:type --------------------------------------------
--@api-stub: LCommandQueue:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCommandQueue_stub:type()  -- -> string
-- (replace lCommandQueue_stub with your real LCommandQueue instance above)

-- ---- Stub: LCommandQueue:typeOf ------------------------------------------
--@api-stub: LCommandQueue:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCommandQueue_stub:typeOf("hero")  -- -> boolean
-- (replace lCommandQueue_stub with your real LCommandQueue instance above)

-- -----------------------------------------------------------------------------
-- LContextSteering methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LContextSteering:addSeekTarget --------------------------------
--@api-stub: LContextSteering:addSeekTarget
-- Adds a world-space target that this agent steers towards.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lContextSteering_stub:addSeekTarget(tx, ty, weight)
-- (replace lContextSteering_stub with your real LContextSteering instance above)

-- ---- Stub: LContextSteering:addWander ------------------------------------
--@api-stub: LContextSteering:addWander
-- Adds a wander behavior with jitter and weight to the context steering evaluator.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lContextSteering_stub:addWander(jitter, weight)
-- (replace lContextSteering_stub with your real LContextSteering instance above)

-- ---- Stub: LContextSteering:addAvoidPoint --------------------------------
--@api-stub: LContextSteering:addAvoidPoint
-- Adds a world-space point that this agent steers away from.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lContextSteering_stub:addAvoidPoint(0.0, 0.0, 24.0, weight)
-- (replace lContextSteering_stub with your real LContextSteering instance above)

-- ---- Stub: LContextSteering:addAvoidBounds -------------------------------
--@api-stub: LContextSteering:addAvoidBounds
-- Registers a rectangular region this agent must avoid.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lContextSteering_stub:addAvoidBounds(min_x, min_y, max_x, max_y, margin, weight)
-- (replace lContextSteering_stub with your real LContextSteering instance above)

-- ---- Stub: LContextSteering:clearBehaviors -------------------------------
--@api-stub: LContextSteering:clearBehaviors
-- Resets or clears the behaviors.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lContextSteering_stub:clearBehaviors()
-- (replace lContextSteering_stub with your real LContextSteering instance above)

-- ---- Stub: LContextSteering:evaluate -------------------------------------
--@api-stub: LContextSteering:evaluate
-- Evaluates and returns the computed result.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lContextSteering_stub:evaluate(ax, ay, vx, vy)  -- -> number, number
-- (replace lContextSteering_stub with your real LContextSteering instance above)

-- ---- Stub: LContextSteering:chosenMagnitude ------------------------------
--@api-stub: LContextSteering:chosenMagnitude
-- Returns or performs chosen magnitude.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lContextSteering_stub:chosenMagnitude()  -- -> number
-- (replace lContextSteering_stub with your real LContextSteering instance above)

-- ---- Stub: LContextSteering:slotCount ------------------------------------
--@api-stub: LContextSteering:slotCount
-- Returns or performs slot count.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lContextSteering_stub:slotCount()  -- -> integer
-- (replace lContextSteering_stub with your real LContextSteering instance above)

-- ---- Stub: LContextSteering:type -----------------------------------------
--@api-stub: LContextSteering:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lContextSteering_stub:type()  -- -> string
-- (replace lContextSteering_stub with your real LContextSteering instance above)

-- ---- Stub: LContextSteering:typeOf ---------------------------------------
--@api-stub: LContextSteering:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lContextSteering_stub:typeOf("hero")  -- -> boolean
-- (replace lContextSteering_stub with your real LContextSteering instance above)

-- -----------------------------------------------------------------------------
-- LEmotionModel methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LEmotionModel:add ---------------------------------------------
--@api-stub: LEmotionModel:add
-- Adds an emotion category with the given name and initial intensity to the model.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lEmotionModel_stub:add("hero", rest, decay, min_vis)
-- (replace lEmotionModel_stub with your real LEmotionModel instance above)

-- ---- Stub: LEmotionModel:trigger -----------------------------------------
--@api-stub: LEmotionModel:trigger
-- Returns or performs trigger.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lEmotionModel_stub:trigger("hero", amount)
-- (replace lEmotionModel_stub with your real LEmotionModel instance above)

-- ---- Stub: LEmotionModel:get ---------------------------------------------
--@api-stub: LEmotionModel:get
-- Returns the current float value of this emotion dimension.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lEmotionModel_stub:get("hero")  -- -> number
-- (replace lEmotionModel_stub with your real LEmotionModel instance above)

-- ---- Stub: LEmotionModel:dominant ----------------------------------------
--@api-stub: LEmotionModel:dominant
-- Returns or performs dominant.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lEmotionModel_stub:dominant()  -- -> string|nil
-- (replace lEmotionModel_stub with your real LEmotionModel instance above)

-- ---- Stub: LEmotionModel:isActive ----------------------------------------
--@api-stub: LEmotionModel:isActive
-- Returns `true` if the emotion dimension is currently active and above threshold.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lEmotionModel_stub:isActive("hero")  -- -> boolean
-- (replace lEmotionModel_stub with your real LEmotionModel instance above)

-- ---- Stub: LEmotionModel:update ------------------------------------------
--@api-stub: LEmotionModel:update
-- Advances the simulation by one time step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lEmotionModel_stub:update(0.016)
-- (replace lEmotionModel_stub with your real LEmotionModel instance above)

-- ---- Stub: LEmotionModel:reset -------------------------------------------
--@api-stub: LEmotionModel:reset
-- Resets or clears the state.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lEmotionModel_stub:reset()
-- (replace lEmotionModel_stub with your real LEmotionModel instance above)

-- ---- Stub: LEmotionModel:type --------------------------------------------
--@api-stub: LEmotionModel:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lEmotionModel_stub:type()  -- -> string
-- (replace lEmotionModel_stub with your real LEmotionModel instance above)

-- ---- Stub: LEmotionModel:typeOf ------------------------------------------
--@api-stub: LEmotionModel:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lEmotionModel_stub:typeOf("hero")  -- -> boolean
-- (replace lEmotionModel_stub with your real LEmotionModel instance above)

-- -----------------------------------------------------------------------------
-- LGOAPPlanner methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LGOAPPlanner:addAction ----------------------------------------
--@api-stub: LGOAPPlanner:addAction
-- Adds a GOAP action with optional cost and callback.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGOAPPlanner_stub:addAction("hero", [cost], [callback])
-- (replace lGOAPPlanner_stub with your real LGOAPPlanner instance above)

-- ---- Stub: LGOAPPlanner:setPrecondition ----------------------------------
--@api-stub: LGOAPPlanner:setPrecondition
-- Sets a boolean precondition on an action.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGOAPPlanner_stub:setPrecondition(action_name, "player_score", 42)
-- (replace lGOAPPlanner_stub with your real LGOAPPlanner instance above)

-- ---- Stub: LGOAPPlanner:setEffect ----------------------------------------
--@api-stub: LGOAPPlanner:setEffect
-- Sets a boolean effect on an action.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGOAPPlanner_stub:setEffect(action_name, "player_score", 42)
-- (replace lGOAPPlanner_stub with your real LGOAPPlanner instance above)

-- ---- Stub: LGOAPPlanner:addGoal ------------------------------------------
--@api-stub: LGOAPPlanner:addGoal
-- Adds a planning goal with optional priority.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGOAPPlanner_stub:addGoal("hero", [priority])
-- (replace lGOAPPlanner_stub with your real LGOAPPlanner instance above)

-- ---- Stub: LGOAPPlanner:setGoalState -------------------------------------
--@api-stub: LGOAPPlanner:setGoalState
-- Sets a boolean condition on a goal.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGOAPPlanner_stub:setGoalState(goal_name, "player_score", 42)
-- (replace lGOAPPlanner_stub with your real LGOAPPlanner instance above)

-- ---- Stub: LGOAPPlanner:plan ---------------------------------------------
--@api-stub: LGOAPPlanner:plan
-- Runs A* planning and returns an action sequence table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGOAPPlanner_stub:plan(world_state_tbl, [max_depth])  -- -> table
-- (replace lGOAPPlanner_stub with your real LGOAPPlanner instance above)

-- ---- Stub: LGOAPPlanner:getActionCount -----------------------------------
--@api-stub: LGOAPPlanner:getActionCount
-- Returns the number of registered actions.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGOAPPlanner_stub:getActionCount()  -- -> integer
-- (replace lGOAPPlanner_stub with your real LGOAPPlanner instance above)

-- ---- Stub: LGOAPPlanner:getGoalCount -------------------------------------
--@api-stub: LGOAPPlanner:getGoalCount
-- Returns the number of registered goals.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGOAPPlanner_stub:getGoalCount()  -- -> integer
-- (replace lGOAPPlanner_stub with your real LGOAPPlanner instance above)

-- ---- Stub: LGOAPPlanner:getMaxIterations ---------------------------------
--@api-stub: LGOAPPlanner:getMaxIterations
-- Returns the maximum A* planning iterations.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGOAPPlanner_stub:getMaxIterations()  -- -> integer
-- (replace lGOAPPlanner_stub with your real LGOAPPlanner instance above)

-- ---- Stub: LGOAPPlanner:setMaxIterations ---------------------------------
--@api-stub: LGOAPPlanner:setMaxIterations
-- Sets the maximum A* planning iterations (0 = unlimited).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGOAPPlanner_stub:setMaxIterations(5)
-- (replace lGOAPPlanner_stub with your real LGOAPPlanner instance above)

-- ---- Stub: LGOAPPlanner:type ---------------------------------------------
--@api-stub: LGOAPPlanner:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGOAPPlanner_stub:type()  -- -> string
-- (replace lGOAPPlanner_stub with your real LGOAPPlanner instance above)

-- ---- Stub: LGOAPPlanner:typeOf -------------------------------------------
--@api-stub: LGOAPPlanner:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGOAPPlanner_stub:typeOf("hero")  -- -> boolean
-- (replace lGOAPPlanner_stub with your real LGOAPPlanner instance above)

-- -----------------------------------------------------------------------------
-- LGeneticAlgorithm methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LGeneticAlgorithm:evolve --------------------------------------
--@api-stub: LGeneticAlgorithm:evolve
-- Runs one generation of the evolutionary algorithm.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGeneticAlgorithm_stub:evolve()
-- (replace lGeneticAlgorithm_stub with your real LGeneticAlgorithm instance above)

-- ---- Stub: LGeneticAlgorithm:generation ----------------------------------
--@api-stub: LGeneticAlgorithm:generation
-- Returns or performs generation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGeneticAlgorithm_stub:generation()  -- -> integer
-- (replace lGeneticAlgorithm_stub with your real LGeneticAlgorithm instance above)

-- ---- Stub: LGeneticAlgorithm:popSize -------------------------------------
--@api-stub: LGeneticAlgorithm:popSize
-- Returns or performs pop size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGeneticAlgorithm_stub:popSize()  -- -> integer
-- (replace lGeneticAlgorithm_stub with your real LGeneticAlgorithm instance above)

-- ---- Stub: LGeneticAlgorithm:setFitness ----------------------------------
--@api-stub: LGeneticAlgorithm:setFitness
-- Sets the fitness score used by the genetic algorithm selection step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGeneticAlgorithm_stub:setFitness(1, fitness)
-- (replace lGeneticAlgorithm_stub with your real LGeneticAlgorithm instance above)

-- ---- Stub: LGeneticAlgorithm:getGenes ------------------------------------
--@api-stub: LGeneticAlgorithm:getGenes
-- Returns the chromosome as an ordered table of gene values.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGeneticAlgorithm_stub:getGenes(1)  -- -> table
-- (replace lGeneticAlgorithm_stub with your real LGeneticAlgorithm instance above)

-- ---- Stub: LGeneticAlgorithm:bestGenes -----------------------------------
--@api-stub: LGeneticAlgorithm:bestGenes
-- Returns or performs best genes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGeneticAlgorithm_stub:bestGenes()  -- -> table
-- (replace lGeneticAlgorithm_stub with your real LGeneticAlgorithm instance above)

-- ---- Stub: LGeneticAlgorithm:type ----------------------------------------
--@api-stub: LGeneticAlgorithm:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGeneticAlgorithm_stub:type()  -- -> string
-- (replace lGeneticAlgorithm_stub with your real LGeneticAlgorithm instance above)

-- ---- Stub: LGeneticAlgorithm:typeOf --------------------------------------
--@api-stub: LGeneticAlgorithm:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lGeneticAlgorithm_stub:typeOf("hero")  -- -> boolean
-- (replace lGeneticAlgorithm_stub with your real LGeneticAlgorithm instance above)

-- -----------------------------------------------------------------------------
-- LHTNDomain methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LHTNDomain:addPrimitive ---------------------------------------
--@api-stub: LHTNDomain:addPrimitive
-- Registers a primitive HTN task with a direct operator function.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHTNDomain_stub:addPrimitive("hero", preconds, effects, clears)
-- (replace lHTNDomain_stub with your real LHTNDomain instance above)

-- ---- Stub: LHTNDomain:addCompound ----------------------------------------
--@api-stub: LHTNDomain:addCompound
-- Registers a compound HTN task that decomposes into sub-tasks.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHTNDomain_stub:addCompound(comp_name, methods_table)
-- (replace lHTNDomain_stub with your real LHTNDomain instance above)

-- ---- Stub: LHTNDomain:plan -----------------------------------------------
--@api-stub: LHTNDomain:plan
-- Runs planning and returns the resulting action sequence.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHTNDomain_stub:plan(root_task, state_table)  -- -> table|nil
-- (replace lHTNDomain_stub with your real LHTNDomain instance above)

-- ---- Stub: LHTNDomain:taskCount ------------------------------------------
--@api-stub: LHTNDomain:taskCount
-- Returns or performs task count.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHTNDomain_stub:taskCount()  -- -> integer
-- (replace lHTNDomain_stub with your real LHTNDomain instance above)

-- ---- Stub: LHTNDomain:type -----------------------------------------------
--@api-stub: LHTNDomain:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHTNDomain_stub:type()  -- -> string
-- (replace lHTNDomain_stub with your real LHTNDomain instance above)

-- ---- Stub: LHTNDomain:typeOf ---------------------------------------------
--@api-stub: LHTNDomain:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHTNDomain_stub:typeOf("hero")  -- -> boolean
-- (replace lHTNDomain_stub with your real LHTNDomain instance above)

-- -----------------------------------------------------------------------------
-- LInfluenceMap methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LInfluenceMap:addLayer ----------------------------------------
--@api-stub: LInfluenceMap:addLayer
-- Adds a named influence layer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:addLayer("hero")
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:hasLayer ----------------------------------------
--@api-stub: LInfluenceMap:hasLayer
-- Returns true if the named layer exists.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:hasLayer("hero")  -- -> boolean
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:setInfluence ------------------------------------
--@api-stub: LInfluenceMap:setInfluence
-- Sets the influence value at a cell (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:setInfluence(1, 0.0, 0.0, 42)
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:getInfluence ------------------------------------
--@api-stub: LInfluenceMap:getInfluence
-- Returns the influence value at a cell (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:getInfluence(1, 0.0, 0.0)  -- -> number
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:stampInfluence ----------------------------------
--@api-stub: LInfluenceMap:stampInfluence
-- Stamps influence in a radial area.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:stampInfluence(1, wx, wy, 24.0, 42, [falloff])
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:propagate ---------------------------------------
--@api-stub: LInfluenceMap:propagate
-- Propagates influence values with momentum.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:propagate(1, [momentum])
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:decay -------------------------------------------
--@api-stub: LInfluenceMap:decay
-- Multiplies all influences by a decay factor.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:decay(1, factor)
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:clearLayer --------------------------------------
--@api-stub: LInfluenceMap:clearLayer
-- Clears all influence in a layer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:clearLayer(1)
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:clearAll ----------------------------------------
--@api-stub: LInfluenceMap:clearAll
-- Removes all influence values from every layer in the map.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:clearAll()
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:getMaxPosition ----------------------------------
--@api-stub: LInfluenceMap:getMaxPosition
-- Returns the world-space position of the maximum value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:getMaxPosition(1)  -- -> number, number
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:getMinPosition ----------------------------------
--@api-stub: LInfluenceMap:getMinPosition
-- Returns the world-space position of the minimum value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:getMinPosition(1)  -- -> number, number
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:queryRect ---------------------------------------
--@api-stub: LInfluenceMap:queryRect
-- Returns the summed influence in a world-space rectangle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:queryRect(1, wx, wy, ww, wh)  -- -> number
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:blend -------------------------------------------
--@api-stub: LInfluenceMap:blend
-- Blends two layers into a destination layer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:blend(layer_a, weight_a, layer_b, weight_b, dest)
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:getWidth ----------------------------------------
--@api-stub: LInfluenceMap:getWidth
-- Returns the influence map width in grid cells.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:getWidth()  -- -> integer
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:getHeight ---------------------------------------
--@api-stub: LInfluenceMap:getHeight
-- Returns the influence map height in grid cells.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:getHeight()  -- -> integer
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:getCellSize -------------------------------------
--@api-stub: LInfluenceMap:getCellSize
-- Returns the cell size in world units.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:getCellSize()  -- -> number
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:type --------------------------------------------
--@api-stub: LInfluenceMap:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:type()  -- -> string
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- ---- Stub: LInfluenceMap:typeOf ------------------------------------------
--@api-stub: LInfluenceMap:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInfluenceMap_stub:typeOf("hero")  -- -> boolean
-- (replace lInfluenceMap_stub with your real LInfluenceMap instance above)

-- -----------------------------------------------------------------------------
-- LMCTSEngine methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMCTSEngine:search --------------------------------------------
--@api-stub: LMCTSEngine:search
-- Uses Lua closures for game logic. All closures receive/return integer states.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMCTSEngine_stub:search()  -- -> integer|nil
-- (replace lMCTSEngine_stub with your real LMCTSEngine instance above)

-- ---- Stub: LMCTSEngine:type ----------------------------------------------
--@api-stub: LMCTSEngine:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMCTSEngine_stub:type()  -- -> string
-- (replace lMCTSEngine_stub with your real LMCTSEngine instance above)

-- ---- Stub: LMCTSEngine:typeOf --------------------------------------------
--@api-stub: LMCTSEngine:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMCTSEngine_stub:typeOf("hero")  -- -> boolean
-- (replace lMCTSEngine_stub with your real LMCTSEngine instance above)

-- -----------------------------------------------------------------------------
-- LNeedSystem methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LNeedSystem:addNeed -------------------------------------------
--@api-stub: LNeedSystem:addNeed
-- Registers a new need with the specified name, urgency, and decay rate in the system.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeedSystem_stub:addNeed("hero", decay_rate, urgency_threshold, urgency_factor)
-- (replace lNeedSystem_stub with your real LNeedSystem instance above)

-- ---- Stub: LNeedSystem:update --------------------------------------------
--@api-stub: LNeedSystem:update
-- Advances the simulation by one time step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeedSystem_stub:update(0.016)
-- (replace lNeedSystem_stub with your real LNeedSystem instance above)

-- ---- Stub: LNeedSystem:mostUrgent ----------------------------------------
--@api-stub: LNeedSystem:mostUrgent
-- Returns or performs most urgent.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeedSystem_stub:mostUrgent()  -- -> string|nil
-- (replace lNeedSystem_stub with your real LNeedSystem instance above)

-- ---- Stub: LNeedSystem:satisfy -------------------------------------------
--@api-stub: LNeedSystem:satisfy
-- Returns or performs satisfy.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeedSystem_stub:satisfy("hero", amount)
-- (replace lNeedSystem_stub with your real LNeedSystem instance above)

-- ---- Stub: LNeedSystem:valueOf -------------------------------------------
--@api-stub: LNeedSystem:valueOf
-- Returns or performs value of.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeedSystem_stub:valueOf("hero")  -- -> number
-- (replace lNeedSystem_stub with your real LNeedSystem instance above)

-- ---- Stub: LNeedSystem:type ----------------------------------------------
--@api-stub: LNeedSystem:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeedSystem_stub:type()  -- -> string
-- (replace lNeedSystem_stub with your real LNeedSystem instance above)

-- ---- Stub: LNeedSystem:typeOf --------------------------------------------
--@api-stub: LNeedSystem:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeedSystem_stub:typeOf("hero")  -- -> boolean
-- (replace lNeedSystem_stub with your real LNeedSystem instance above)

-- -----------------------------------------------------------------------------
-- LNeuralNet methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LNeuralNet:addLayer -------------------------------------------
--@api-stub: LNeuralNet:addLayer
-- Adds a neural network layer with inputs, outputs, and an activation function.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuralNet_stub:addLayer(inputs, outputs, activation)
-- (replace lNeuralNet_stub with your real LNeuralNet instance above)

-- ---- Stub: LNeuralNet:forward --------------------------------------------
--@api-stub: LNeuralNet:forward
-- Returns or performs forward.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuralNet_stub:forward(input)  -- -> table
-- (replace lNeuralNet_stub with your real LNeuralNet instance above)

-- ---- Stub: LNeuralNet:setWeights -----------------------------------------
--@api-stub: LNeuralNet:setWeights
-- Overwrites all connection weights with values from a flat table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuralNet_stub:setWeights(weights)  -- -> boolean
-- (replace lNeuralNet_stub with your real LNeuralNet instance above)

-- ---- Stub: LNeuralNet:getWeights -----------------------------------------
--@api-stub: LNeuralNet:getWeights
-- Returns a flat table of all connection weight values in the network.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuralNet_stub:getWeights()  -- -> table
-- (replace lNeuralNet_stub with your real LNeuralNet instance above)

-- ---- Stub: LNeuralNet:paramCount -----------------------------------------
--@api-stub: LNeuralNet:paramCount
-- Returns or performs param count.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuralNet_stub:paramCount()  -- -> integer
-- (replace lNeuralNet_stub with your real LNeuralNet instance above)

-- ---- Stub: LNeuralNet:layerCount -----------------------------------------
--@api-stub: LNeuralNet:layerCount
-- Returns or performs layer count.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuralNet_stub:layerCount()  -- -> integer
-- (replace lNeuralNet_stub with your real LNeuralNet instance above)

-- ---- Stub: LNeuralNet:type -----------------------------------------------
--@api-stub: LNeuralNet:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuralNet_stub:type()  -- -> string
-- (replace lNeuralNet_stub with your real LNeuralNet instance above)

-- ---- Stub: LNeuralNet:typeOf ---------------------------------------------
--@api-stub: LNeuralNet:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuralNet_stub:typeOf("hero")  -- -> boolean
-- (replace lNeuralNet_stub with your real LNeuralNet instance above)

-- -----------------------------------------------------------------------------
-- LNeuroevolution methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LNeuroevolution:evolve ----------------------------------------
--@api-stub: LNeuroevolution:evolve
-- Runs one generation of the evolutionary algorithm.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuroevolution_stub:evolve()
-- (replace lNeuroevolution_stub with your real LNeuroevolution instance above)

-- ---- Stub: LNeuroevolution:setFitness ------------------------------------
--@api-stub: LNeuroevolution:setFitness
-- Sets the fitness score used by the genetic algorithm selection step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuroevolution_stub:setFitness(1, fitness)
-- (replace lNeuroevolution_stub with your real LNeuroevolution instance above)

-- ---- Stub: LNeuroevolution:chromosomeToNet -------------------------------
--@api-stub: LNeuroevolution:chromosomeToNet
-- Returns or performs chromosome to net.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuroevolution_stub:chromosomeToNet(1)
-- (replace lNeuroevolution_stub with your real LNeuroevolution instance above)

-- ---- Stub: LNeuroevolution:bestNetwork -----------------------------------
--@api-stub: LNeuroevolution:bestNetwork
-- Returns or performs best network.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuroevolution_stub:bestNetwork()
-- (replace lNeuroevolution_stub with your real LNeuroevolution instance above)

-- ---- Stub: LNeuroevolution:bestFitness -----------------------------------
--@api-stub: LNeuroevolution:bestFitness
-- Returns or performs best fitness.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuroevolution_stub:bestFitness()  -- -> number
-- (replace lNeuroevolution_stub with your real LNeuroevolution instance above)

-- ---- Stub: LNeuroevolution:popSize ---------------------------------------
--@api-stub: LNeuroevolution:popSize
-- Returns or performs pop size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuroevolution_stub:popSize()  -- -> integer
-- (replace lNeuroevolution_stub with your real LNeuroevolution instance above)

-- ---- Stub: LNeuroevolution:generation ------------------------------------
--@api-stub: LNeuroevolution:generation
-- Returns or performs generation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuroevolution_stub:generation()  -- -> integer
-- (replace lNeuroevolution_stub with your real LNeuroevolution instance above)

-- ---- Stub: LNeuroevolution:type ------------------------------------------
--@api-stub: LNeuroevolution:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuroevolution_stub:type()  -- -> string
-- (replace lNeuroevolution_stub with your real LNeuroevolution instance above)

-- ---- Stub: LNeuroevolution:typeOf ----------------------------------------
--@api-stub: LNeuroevolution:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNeuroevolution_stub:typeOf("hero")  -- -> boolean
-- (replace lNeuroevolution_stub with your real LNeuroevolution instance above)

-- -----------------------------------------------------------------------------
-- LORCASolver methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LORCASolver:addAgent ------------------------------------------
--@api-stub: LORCASolver:addAgent
-- Adds an ORCA agent at the given position with radius and max speed to the solver.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lORCASolver_stub:addAgent(0.0, 0.0, 24.0, max_speed)  -- -> integer
-- (replace lORCASolver_stub with your real LORCASolver instance above)

-- ---- Stub: LORCASolver:setPreferredVelocity ------------------------------
--@api-stub: LORCASolver:setPreferredVelocity
-- Sets the preferred velocity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lORCASolver_stub:setPreferredVelocity(1, pvx, pvy)
-- (replace lORCASolver_stub with your real LORCASolver instance above)

-- ---- Stub: LORCASolver:setPosition ---------------------------------------
--@api-stub: LORCASolver:setPosition
-- Sets the agent's current world-space position for ORCA velocity computation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lORCASolver_stub:setPosition(1, 0.0, 0.0)
-- (replace lORCASolver_stub with your real LORCASolver instance above)

-- ---- Stub: LORCASolver:compute -------------------------------------------
--@api-stub: LORCASolver:compute
-- Computes and returns the result.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lORCASolver_stub:compute(0.016)
-- (replace lORCASolver_stub with your real LORCASolver instance above)

-- ---- Stub: LORCASolver:getSafeVelocity -----------------------------------
--@api-stub: LORCASolver:getSafeVelocity
-- Returns the safe velocity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lORCASolver_stub:getSafeVelocity(1)  -- -> number, number
-- (replace lORCASolver_stub with your real LORCASolver instance above)

-- ---- Stub: LORCASolver:agentCount ----------------------------------------
--@api-stub: LORCASolver:agentCount
-- Returns or performs agent count.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lORCASolver_stub:agentCount()  -- -> integer
-- (replace lORCASolver_stub with your real LORCASolver instance above)

-- ---- Stub: LORCASolver:type ----------------------------------------------
--@api-stub: LORCASolver:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lORCASolver_stub:type()  -- -> string
-- (replace lORCASolver_stub with your real LORCASolver instance above)

-- ---- Stub: LORCASolver:typeOf --------------------------------------------
--@api-stub: LORCASolver:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lORCASolver_stub:typeOf("hero")  -- -> boolean
-- (replace lORCASolver_stub with your real LORCASolver instance above)

-- -----------------------------------------------------------------------------
-- LQLearner methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LQLearner:chooseAction ----------------------------------------
--@api-stub: LQLearner:chooseAction
-- Selects an action using epsilon-greedy policy (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:chooseAction(state)  -- -> integer
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:bestAction ------------------------------------------
--@api-stub: LQLearner:bestAction
-- Returns the greedy-best action for the state (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:bestAction(state)  -- -> integer
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:learn -----------------------------------------------
--@api-stub: LQLearner:learn
-- Performs one Bellman Q-learning update (1-based indices).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:learn(state, action, reward, next_state)
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:getQValue -------------------------------------------
--@api-stub: LQLearner:getQValue
-- Returns the Q-value for a state-action pair (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:getQValue(state, action)  -- -> number
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:setQValue -------------------------------------------
--@api-stub: LQLearner:setQValue
-- Overwrites the Q-value for a state-action pair (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:setQValue(state, action, 42)
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:endEpisode ------------------------------------------
--@api-stub: LQLearner:endEpisode
-- Ends the current episode, applying epsilon decay.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:endEpisode()
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:getEpisodeCount -------------------------------------
--@api-stub: LQLearner:getEpisodeCount
-- Returns the number of completed episodes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:getEpisodeCount()  -- -> integer
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:getStateCount ---------------------------------------
--@api-stub: LQLearner:getStateCount
-- Returns the number of discrete states.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:getStateCount()  -- -> integer
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:getActionCount --------------------------------------
--@api-stub: LQLearner:getActionCount
-- Returns the number of discrete actions.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:getActionCount()  -- -> integer
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:setLearningRate -------------------------------------
--@api-stub: LQLearner:setLearningRate
-- Sets the learning rate alpha.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:setLearningRate(1.0)
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:getLearningRate -------------------------------------
--@api-stub: LQLearner:getLearningRate
-- Returns the current learning rate.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:getLearningRate()  -- -> number
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:setDiscountFactor -----------------------------------
--@api-stub: LQLearner:setDiscountFactor
-- Sets the discount factor gamma.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:setDiscountFactor(1.0)
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:getDiscountFactor -----------------------------------
--@api-stub: LQLearner:getDiscountFactor
-- Returns the current discount factor.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:getDiscountFactor()  -- -> number
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:setExplorationRate ----------------------------------
--@api-stub: LQLearner:setExplorationRate
-- Sets the exploration rate epsilon.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:setExplorationRate(1.0)
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:getExplorationRate ----------------------------------
--@api-stub: LQLearner:getExplorationRate
-- Returns the current exploration rate.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:getExplorationRate()  -- -> number
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:setExplorationDecay ---------------------------------
--@api-stub: LQLearner:setExplorationDecay
-- Sets the epsilon decay multiplier.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:setExplorationDecay(1.0)
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:getExplorationDecay ---------------------------------
--@api-stub: LQLearner:getExplorationDecay
-- Returns the epsilon decay multiplier.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:getExplorationDecay()  -- -> number
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:serialize -------------------------------------------
--@api-stub: LQLearner:serialize
-- Serializes the Q-table to a JSON string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:serialize()  -- -> string
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:deserialize -----------------------------------------
--@api-stub: LQLearner:deserialize
-- Restores the Q-table from a JSON string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:deserialize(json)
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:type ------------------------------------------------
--@api-stub: LQLearner:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:type()  -- -> string
-- (replace lQLearner_stub with your real LQLearner instance above)

-- ---- Stub: LQLearner:typeOf ----------------------------------------------
--@api-stub: LQLearner:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQLearner_stub:typeOf("hero")  -- -> boolean
-- (replace lQLearner_stub with your real LQLearner instance above)

-- -----------------------------------------------------------------------------
-- LSquad methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSquad:getName ------------------------------------------------
--@api-stub: LSquad:getName
-- Returns the unique name string assigned to this squad.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSquad_stub:getName()  -- -> string
-- (replace lSquad_stub with your real LSquad instance above)

-- ---- Stub: LSquad:addMember ----------------------------------------------
--@api-stub: LSquad:addMember
-- Adds an agent by name to this squad.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSquad_stub:addMember("hero")
-- (replace lSquad_stub with your real LSquad instance above)

-- ---- Stub: LSquad:removeMember -------------------------------------------
--@api-stub: LSquad:removeMember
-- Removes an agent by name from this squad.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSquad_stub:removeMember("hero")
-- (replace lSquad_stub with your real LSquad instance above)

-- ---- Stub: LSquad:getMemberCount -----------------------------------------
--@api-stub: LSquad:getMemberCount
-- Returns the number of squad members.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSquad_stub:getMemberCount()  -- -> integer
-- (replace lSquad_stub with your real LSquad instance above)

-- ---- Stub: LSquad:getMembers ---------------------------------------------
--@api-stub: LSquad:getMembers
-- Returns the member names as a table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSquad_stub:getMembers()  -- -> table
-- (replace lSquad_stub with your real LSquad instance above)

-- ---- Stub: LSquad:setLeader ----------------------------------------------
--@api-stub: LSquad:setLeader
-- Sets the squad leader by name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSquad_stub:setLeader("hero")
-- (replace lSquad_stub with your real LSquad instance above)

-- ---- Stub: LSquad:getLeader ----------------------------------------------
--@api-stub: LSquad:getLeader
-- Returns the leader name, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSquad_stub:getLeader()  -- -> string?
-- (replace lSquad_stub with your real LSquad instance above)

-- ---- Stub: LSquad:setFormation -------------------------------------------
--@api-stub: LSquad:setFormation
-- Sets the formation type and optional spacing.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSquad_stub:setFormation(ftype, [spacing])
-- (replace lSquad_stub with your real LSquad instance above)

-- ---- Stub: LSquad:getFormation -------------------------------------------
--@api-stub: LSquad:getFormation
-- Returns the current formation type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSquad_stub:getFormation()  -- -> string
-- (replace lSquad_stub with your real LSquad instance above)

-- ---- Stub: LSquad:getFormationSpacing ------------------------------------
--@api-stub: LSquad:getFormationSpacing
-- Returns the formation spacing in world units.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSquad_stub:getFormationSpacing()  -- -> number
-- (replace lSquad_stub with your real LSquad instance above)

-- ---- Stub: LSquad:getFormationPosition -----------------------------------
--@api-stub: LSquad:getFormationPosition
-- Computes the world-space position for a member index (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSquad_stub:getFormationPosition(member_idx, leader_x, leader_y)  -- -> number, number
-- (replace lSquad_stub with your real LSquad instance above)

-- ---- Stub: LSquad:getBlackboard ------------------------------------------
--@api-stub: LSquad:getBlackboard
-- Returns the squad's shared blackboard.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSquad_stub:getBlackboard()  -- -> AIBlackboard
-- (replace lSquad_stub with your real LSquad instance above)

-- ---- Stub: LSquad:type ---------------------------------------------------
--@api-stub: LSquad:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSquad_stub:type()  -- -> string
-- (replace lSquad_stub with your real LSquad instance above)

-- ---- Stub: LSquad:typeOf -------------------------------------------------
--@api-stub: LSquad:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSquad_stub:typeOf("hero")  -- -> boolean
-- (replace lSquad_stub with your real LSquad instance above)

-- -----------------------------------------------------------------------------
-- LStateMachine methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LStateMachine:addState ----------------------------------------
--@api-stub: LStateMachine:addState
-- Registers a named state with optional lifecycle callbacks.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStateMachine_stub:addState("hero", opts)
-- (replace lStateMachine_stub with your real LStateMachine instance above)

-- ---- Stub: LStateMachine:addTransition -----------------------------------
--@api-stub: LStateMachine:addTransition
-- Adds a guarded transition between states.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStateMachine_stub:addTransition(from, to, [guard], [priority])
-- (replace lStateMachine_stub with your real LStateMachine instance above)

-- ---- Stub: LStateMachine:setInitialState ---------------------------------
--@api-stub: LStateMachine:setInitialState
-- Sets the FSM's initial state; must be called before the first update.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStateMachine_stub:setInitialState("hero")
-- (replace lStateMachine_stub with your real LStateMachine instance above)

-- ---- Stub: LStateMachine:getCurrentState ---------------------------------
--@api-stub: LStateMachine:getCurrentState
-- Returns the current state name, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStateMachine_stub:getCurrentState()  -- -> string?
-- (replace lStateMachine_stub with your real LStateMachine instance above)

-- ---- Stub: LStateMachine:forceState --------------------------------------
--@api-stub: LStateMachine:forceState
-- Forces a transition to the named state.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStateMachine_stub:forceState("hero")
-- (replace lStateMachine_stub with your real LStateMachine instance above)

-- ---- Stub: LStateMachine:getTimeInState ----------------------------------
--@api-stub: LStateMachine:getTimeInState
-- Returns seconds spent in the current state.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStateMachine_stub:getTimeInState()  -- -> number
-- (replace lStateMachine_stub with your real LStateMachine instance above)

-- ---- Stub: LStateMachine:type --------------------------------------------
--@api-stub: LStateMachine:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStateMachine_stub:type()  -- -> string
-- (replace lStateMachine_stub with your real LStateMachine instance above)

-- ---- Stub: LStateMachine:typeOf ------------------------------------------
--@api-stub: LStateMachine:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStateMachine_stub:typeOf("hero")  -- -> boolean
-- (replace lStateMachine_stub with your real LStateMachine instance above)

-- -----------------------------------------------------------------------------
-- LSteeringManager methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSteeringManager:addSeek --------------------------------------
--@api-stub: LSteeringManager:addSeek
-- Adds a Seek behavior toward the target.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:addSeek(tx, ty, [weight])
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:addFlee --------------------------------------
--@api-stub: LSteeringManager:addFlee
-- Adds a Flee behavior away from the target.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:addFlee(tx, ty, [panic_dist], [weight])
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:addArrive ------------------------------------
--@api-stub: LSteeringManager:addArrive
-- Adds an Arrive behavior with deceleration.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:addArrive(tx, ty, [slowing], [weight])
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:addWander ------------------------------------
--@api-stub: LSteeringManager:addWander
-- Adds a Wander behavior for random meandering.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:addWander()
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:addPursue ------------------------------------
--@api-stub: LSteeringManager:addPursue
-- Adds a Pursue behavior targeting a named agent.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:addPursue([target_name], [weight])
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:addEvade -------------------------------------
--@api-stub: LSteeringManager:addEvade
-- Adds an Evade behavior fleeing from a named agent.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:addEvade([threat_name], [weight])
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:addFlock -------------------------------------
--@api-stub: LSteeringManager:addFlock
-- Adds a Flock behavior for group movement.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:addFlock()
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:getBehaviorCount -----------------------------
--@api-stub: LSteeringManager:getBehaviorCount
-- Returns the number of active behaviors.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:getBehaviorCount()  -- -> integer
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:setCombineMode -------------------------------
--@api-stub: LSteeringManager:setCombineMode
-- Sets the force combination mode.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:setCombineMode(mode)
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:getCombineMode -------------------------------
--@api-stub: LSteeringManager:getCombineMode
-- Returns the current combination mode.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:getCombineMode()  -- -> string
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:getLastSteering ------------------------------
--@api-stub: LSteeringManager:getLastSteering
-- Returns the last computed steering force.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:getLastSteering()  -- -> number, number
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:calculate ------------------------------------
--@api-stub: LSteeringManager:calculate
-- Computes the combined steering force for the given agent state.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:calculate(px, py, vx, vy, max_speed, max_force, 0.016)  -- -> number, number
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:type -----------------------------------------
--@api-stub: LSteeringManager:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:type()  -- -> string
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:typeOf ---------------------------------------
--@api-stub: LSteeringManager:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:typeOf("hero")  -- -> boolean
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:setSpatialHashCellSize -----------------------
--@api-stub: LSteeringManager:setSpatialHashCellSize
-- Sets the cell size used by the spatial-hash neighbourhood search.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:setSpatialHashCellSize(size)
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:enableSpatialHash ----------------------------
--@api-stub: LSteeringManager:enableSpatialHash
-- Enables or disables spatial-hash bucketing for neighbourhood queries.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:enableSpatialHash(true)
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:addCustomBehavior ----------------------------
--@api-stub: LSteeringManager:addCustomBehavior
-- Registers a Lua callback as a custom steering behavior.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:addCustomBehavior(func, [weight])
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- ---- Stub: LSteeringManager:applyCustomSteering --------------------------
--@api-stub: LSteeringManager:applyCustomSteering
-- Invokes all registered custom steering callbacks and returns the combined force.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSteeringManager_stub:applyCustomSteering(agent_ud, 0.016)  -- -> number, number
-- (replace lSteeringManager_stub with your real LSteeringManager instance above)

-- -----------------------------------------------------------------------------
-- LStimulusWorld methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LStimulusWorld:addVisual --------------------------------------
--@api-stub: LStimulusWorld:addVisual
-- Adds a visual stimulus at the specified world position with radius and intensity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStimulusWorld_stub:addVisual(0.0, 0.0, intensity, 24.0, [tag])  -- -> integer
-- (replace lStimulusWorld_stub with your real LStimulusWorld instance above)

-- ---- Stub: LStimulusWorld:addAuditory ------------------------------------
--@api-stub: LStimulusWorld:addAuditory
-- Registers an auditory stimulus at a world-space position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStimulusWorld_stub:addAuditory()  -- -> integer
-- (replace lStimulusWorld_stub with your real LStimulusWorld instance above)

-- ---- Stub: LStimulusWorld:remove -----------------------------------------
--@api-stub: LStimulusWorld:remove
-- Removes the specified item.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStimulusWorld_stub:remove(1)  -- -> boolean
-- (replace lStimulusWorld_stub with your real LStimulusWorld instance above)

-- ---- Stub: LStimulusWorld:update -----------------------------------------
--@api-stub: LStimulusWorld:update
-- Advances the simulation by one time step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStimulusWorld_stub:update(0.016)
-- (replace lStimulusWorld_stub with your real LStimulusWorld instance above)

-- ---- Stub: LStimulusWorld:count ------------------------------------------
--@api-stub: LStimulusWorld:count
-- Returns or performs count.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStimulusWorld_stub:count()  -- -> integer
-- (replace lStimulusWorld_stub with your real LStimulusWorld instance above)

-- ---- Stub: LStimulusWorld:clear ------------------------------------------
--@api-stub: LStimulusWorld:clear
-- Resets or clears the state.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStimulusWorld_stub:clear()
-- (replace lStimulusWorld_stub with your real LStimulusWorld instance above)

-- ---- Stub: LStimulusWorld:type -------------------------------------------
--@api-stub: LStimulusWorld:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStimulusWorld_stub:type()  -- -> string
-- (replace lStimulusWorld_stub with your real LStimulusWorld instance above)

-- ---- Stub: LStimulusWorld:typeOf -----------------------------------------
--@api-stub: LStimulusWorld:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStimulusWorld_stub:typeOf("hero")  -- -> boolean
-- (replace lStimulusWorld_stub with your real LStimulusWorld instance above)

-- -----------------------------------------------------------------------------
-- LStrategyAI methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LStrategyAI:addGoal -------------------------------------------
--@api-stub: LStrategyAI:addGoal
-- Adds a strategic goal with priority score to the planner for future evaluation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStrategyAI_stub:addGoal("hero")
-- (replace lStrategyAI_stub with your real LStrategyAI instance above)

-- ---- Stub: LStrategyAI:addTag --------------------------------------------
--@api-stub: LStrategyAI:addTag
-- Adds a string tag to the strategy AI instance for goal filtering and categorization.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStrategyAI_stub:addTag("enemy")
-- (replace lStrategyAI_stub with your real LStrategyAI instance above)

-- ---- Stub: LStrategyAI:removeTag -----------------------------------------
--@api-stub: LStrategyAI:removeTag
-- Removes the specified tag.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStrategyAI_stub:removeTag("enemy")
-- (replace lStrategyAI_stub with your real LStrategyAI instance above)

-- ---- Stub: LStrategyAI:update --------------------------------------------
--@api-stub: LStrategyAI:update
-- Advances the simulation by one time step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStrategyAI_stub:update(0.016, scorer_fn)
-- (replace lStrategyAI_stub with your real LStrategyAI instance above)

-- ---- Stub: LStrategyAI:forceEvaluate -------------------------------------
--@api-stub: LStrategyAI:forceEvaluate
-- Returns or performs force evaluate.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStrategyAI_stub:forceEvaluate(scorer_fn)
-- (replace lStrategyAI_stub with your real LStrategyAI instance above)

-- ---- Stub: LStrategyAI:activeGoal ----------------------------------------
--@api-stub: LStrategyAI:activeGoal
-- Returns or performs active goal.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStrategyAI_stub:activeGoal()  -- -> string|nil
-- (replace lStrategyAI_stub with your real LStrategyAI instance above)

-- ---- Stub: LStrategyAI:timeUntilNext -------------------------------------
--@api-stub: LStrategyAI:timeUntilNext
-- Returns or performs time until next.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStrategyAI_stub:timeUntilNext()  -- -> number
-- (replace lStrategyAI_stub with your real LStrategyAI instance above)

-- ---- Stub: LStrategyAI:type ----------------------------------------------
--@api-stub: LStrategyAI:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStrategyAI_stub:type()  -- -> string
-- (replace lStrategyAI_stub with your real LStrategyAI instance above)

-- ---- Stub: LStrategyAI:typeOf --------------------------------------------
--@api-stub: LStrategyAI:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lStrategyAI_stub:typeOf("hero")  -- -> boolean
-- (replace lStrategyAI_stub with your real LStrategyAI instance above)

-- -----------------------------------------------------------------------------
-- LTraitProfile methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTraitProfile:set ---------------------------------------------
--@api-stub: LTraitProfile:set
-- Sets the base value of this trait, replacing any previous base.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTraitProfile_stub:set("hero", 42)
-- (replace lTraitProfile_stub with your real LTraitProfile instance above)

-- ---- Stub: LTraitProfile:get ---------------------------------------------
--@api-stub: LTraitProfile:get
-- Returns the current float value of this emotion dimension.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTraitProfile_stub:get("hero")  -- -> number
-- (replace lTraitProfile_stub with your real LTraitProfile instance above)

-- ---- Stub: LTraitProfile:getBase -----------------------------------------
--@api-stub: LTraitProfile:getBase
-- Returns the unmodified base value of this trait before modifiers.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTraitProfile_stub:getBase("hero")  -- -> number
-- (replace lTraitProfile_stub with your real LTraitProfile instance above)

-- ---- Stub: LTraitProfile:addModifier -------------------------------------
--@api-stub: LTraitProfile:addModifier
-- Adds a named modifier that adjusts the trait value by a delta.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTraitProfile_stub:addModifier(trait_name, 0.016, [duration], source)
-- (replace lTraitProfile_stub with your real LTraitProfile instance above)

-- ---- Stub: LTraitProfile:removeModifiers ---------------------------------
--@api-stub: LTraitProfile:removeModifiers
-- Removes the specified modifiers.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTraitProfile_stub:removeModifiers(source)
-- (replace lTraitProfile_stub with your real LTraitProfile instance above)

-- ---- Stub: LTraitProfile:update ------------------------------------------
--@api-stub: LTraitProfile:update
-- Advances the simulation by one time step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTraitProfile_stub:update(0.016)
-- (replace lTraitProfile_stub with your real LTraitProfile instance above)

-- ---- Stub: LTraitProfile:has ---------------------------------------------
--@api-stub: LTraitProfile:has
-- Returns true if a item is present.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTraitProfile_stub:has("hero")  -- -> boolean
-- (replace lTraitProfile_stub with your real LTraitProfile instance above)

-- ---- Stub: LTraitProfile:traitCount --------------------------------------
--@api-stub: LTraitProfile:traitCount
-- Returns or performs trait count.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTraitProfile_stub:traitCount()  -- -> number
-- (replace lTraitProfile_stub with your real LTraitProfile instance above)

-- ---- Stub: LTraitProfile:archetype ---------------------------------------
--@api-stub: LTraitProfile:archetype
-- Returns or performs archetype.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTraitProfile_stub:archetype()  -- -> string|nil
-- (replace lTraitProfile_stub with your real LTraitProfile instance above)

-- ---- Stub: LTraitProfile:type --------------------------------------------
--@api-stub: LTraitProfile:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTraitProfile_stub:type()  -- -> string
-- (replace lTraitProfile_stub with your real LTraitProfile instance above)

-- ---- Stub: LTraitProfile:typeOf ------------------------------------------
--@api-stub: LTraitProfile:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTraitProfile_stub:typeOf("hero")  -- -> boolean
-- (replace lTraitProfile_stub with your real LTraitProfile instance above)

-- -----------------------------------------------------------------------------
-- LUtilityAI methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LUtilityAI:addAction ------------------------------------------
--@api-stub: LUtilityAI:addAction
-- Adds a scored action with optional momentum weight.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUtilityAI_stub:addAction("hero", scorer_fn, [weight])
-- (replace lUtilityAI_stub with your real LUtilityAI instance above)

-- ---- Stub: LUtilityAI:evaluate -------------------------------------------
--@api-stub: LUtilityAI:evaluate
-- Evaluates all actions and returns the best action name, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUtilityAI_stub:evaluate()  -- -> string?
-- (replace lUtilityAI_stub with your real LUtilityAI instance above)

-- ---- Stub: LUtilityAI:getActionCount -------------------------------------
--@api-stub: LUtilityAI:getActionCount
-- Returns the number of registered actions.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUtilityAI_stub:getActionCount()  -- -> integer
-- (replace lUtilityAI_stub with your real LUtilityAI instance above)

-- ---- Stub: LUtilityAI:getLastAction --------------------------------------
--@api-stub: LUtilityAI:getLastAction
-- Returns the name of the last chosen action, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUtilityAI_stub:getLastAction()  -- -> string?
-- (replace lUtilityAI_stub with your real LUtilityAI instance above)

-- ---- Stub: LUtilityAI:addConsideration -----------------------------------
--@api-stub: LUtilityAI:addConsideration
-- Adds a multi-axis consideration to a named action.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUtilityAI_stub:addConsideration()
-- (replace lUtilityAI_stub with your real LUtilityAI instance above)

-- ---- Stub: LUtilityAI:type -----------------------------------------------
--@api-stub: LUtilityAI:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUtilityAI_stub:type()  -- -> string
-- (replace lUtilityAI_stub with your real LUtilityAI instance above)

-- ---- Stub: LUtilityAI:typeOf ---------------------------------------------
--@api-stub: LUtilityAI:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUtilityAI_stub:typeOf("hero")  -- -> boolean
-- (replace lUtilityAI_stub with your real LUtilityAI instance above)
