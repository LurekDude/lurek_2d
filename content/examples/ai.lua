-- content/examples/ai.lua
-- Hand-written coverage of the lurek.ai API (240 items).
--
-- The lurek.ai namespace exposes Lurek2D's full game-AI toolkit: worlds and
-- agents, FSMs, behaviour trees, steering, Q-learning, utility AI, GOAP, HTN,
-- MCTS, ORCA crowd avoidance, neural nets, genetic / neuroevolution, bandits,
-- influence maps, squads with formations, command queues, traits, perception,
-- emotion models, needs, the AI director, strategy planners, and AI LOD.
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
  uai:addAction("flee", function() return 0.8 end)
  uai:addAction("attack", function() return 0.4 end)
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
  ua:addAction("patrol", function() return 0.4 end)
  ua:addConsideration(
    "patrol",
    "health_curve",
    function() return 0.8 end,
    function(x) return x * x end   -- quadratic custom curve
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
  local fx, fy = sm:calculate(200, 200, 0, 0, 100)
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
  local fx, fy = cs:evaluate(150, 150)
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
  sm:addEvade(400, 300, 80, 50, 1.0)
  local fx, fy = sm:calculate(200, 200, 0, 0, 100)
  lurek.log.info("evade: " .. fx .. "," .. fy, "ai")
end

--@api-stub: SteeringManager:addFlee
-- Adds a flee behaviour that steers directly away from the threat position.
-- Unlike addEvade, flee reacts to current position not predicted future position.
do  -- SteeringManager:addFlee
  local sm = lurek.ai.newSteeringManager()
  sm:addFlee(400, 300, 1.0)
  local fx, fy = sm:calculate(200, 200, 0, 0, 100)
  lurek.log.info("flee: " .. fx .. "," .. fy, "ai")
end

--@api-stub: SteeringManager:addFlock
-- Adds a flocking behaviour combining separation, alignment, and cohesion.
-- Pass a neighbour radius and the per-component weights as a table or individual args.
do  -- SteeringManager:addFlock
  local sm = lurek.ai.newSteeringManager()
  sm:addFlock(80, 1.0, 0.8, 0.6)
  local fx, fy = sm:calculate(200, 200, 10, 0, 100)
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
  traits:addModifier("courage", "fear_potion", -0.3)
  lurek.log.info("effective courage: " .. traits:get("courage"), "ai")
end

--@api-stub: SteeringManager:addPursue
-- Adds a pursue behaviour that steers toward the predicted future position of a target.
-- More effective than addSeek against moving targets; uses linear prediction.
do  -- SteeringManager:addPursue
  local sm = lurek.ai.newSteeringManager()
  sm:addPursue(400, 300, 80, 50, 1.0)
  local fx, fy = sm:calculate(200, 200, 0, 0, 100)
  lurek.log.info("pursue: " .. fx .. "," .. fy, "ai")
end

--@api-stub: SteeringManager:addSeek
-- Adds a seek behaviour that steers directly toward the target position.
-- The simplest steering force; weight=1.0 uses the full max-force budget.
do  -- SteeringManager:addSeek
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(500, 400, 1.0)
  local fx, fy = sm:calculate(100, 100, 0, 0, 150)
  lurek.log.info("seek force: " .. fx .. "," .. fy, "ai")
end

--@api-stub: ContextSteering:addSeekTarget
-- Adds a seek target to the context steering desire map.
-- Multiple seek targets blend via the slot weights; the final direction maximises total desire.
do  -- ContextSteering:addSeekTarget
  local cs = lurek.ai.newContextSteering(16)
  cs:addSeekTarget(500, 300, 1.0)
  cs:addSeekTarget(400, 400, 0.6)
  local fx, fy = cs:evaluate(200, 200)
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
  sw:addVisual(300, 200, 0, 180, 200, 1.0, "player")
  sw:addAuditory(300, 200, 1.0, 80, 0.5, "footstep")
  lurek.log.info("stimuli count: " .. sw:count(), "ai")
end

--@api-stub: SteeringManager:addWander
-- Adds a wander behaviour producing smooth random-direction steering.
-- Adjust circleRadius and maxTurnRate to control how erratic the wandering appears.
do  -- SteeringManager:addWander
  local sm = lurek.ai.newSteeringManager()
  sm:addWander(25, 50, 8, 0.4)
  local fx, fy = sm:calculate(200, 200, 0, 0, 100)
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
  im:blend("threat", "resource", 0.5)
  lurek.log.info("blend complete", "ai")
end

--@api-stub: SteeringManager:calculate
-- Calculates the combined steering force for the current agent state.
-- Returns two floats (fx, fy); apply them to the agent's velocity each physics step.
do  -- SteeringManager:calculate
  local sm = lurek.ai.newSteeringManager()
  sm:addSeek(400, 300, 1.0)
  local fx, fy = sm:calculate(100, 100, 0, 0, 120)
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
  local fx, fy = cs:evaluate(200, 200)
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
  local px, py = squad:getFormationPosition("guard_01", 400, 300, 0)
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
  local cells = im:queryRect("resource", 100, 100, 300, 300, 0.5)
  lurek.log.info("cells found: " .. #cells, "ai")
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
  orca:compute()
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
  local tier = lod:tierFor(350)
  lurek.log.info("lod tier at 350: " .. tier, "ai")
end

--@api-stub: ORCASolver:addAgent
-- Registers an agent with the ORCA solver so it participates in velocity planning.
-- Each agent needs a position, preferred velocity, radius, and max speed.
do  -- ORCASolver:addAgent
  local solver = lurek.ai.newORCASolver()
  solver:addAgent(1, 200, 300, 50, 100)
  solver:update(1/60)
  lurek.log.info("ORCA agent added", "ai")
end

--@api-stub: NeuralNet:addLayer
-- Adds a hidden layer with the specified neuron count and activation function.
-- Call before NeuralNet:build() to define the network architecture.
do  -- NeuralNet:addLayer
  local net = lurek.ai.newNeuralNet()
  net:addLayer(4, "relu")
  net:addLayer(4, "relu")
  net:build(2, 1)
  lurek.log.info("layer count: " .. net:getLayerCount(), "ai")
end
