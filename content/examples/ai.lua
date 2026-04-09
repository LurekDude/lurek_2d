-- examples/ai.lua
-- lurek.ai — Game AI subsystems: AIWorld, FSM, Behavior Trees, Steering,
-- Q-Learning, Utility AI, GOAP, Influence Maps, Squads, and Command Queues.

-- ── AIWorld ───────────────────────────────────────────────────────────────────

-- newWorld() → AIWorld
-- Container that manages AI agents and a shared global blackboard.
local world = lurek.ai.newWorld()

-- addAgent(name, x, y) → Agent
local agent = world:addAgent("soldier_01", 100, 200)

-- getAgent(name) → Agent?
local found = world:getAgent("soldier_01")

-- removeAgent(name)
world:removeAgent("soldier_01")

-- getAgentCount() → integer
local n = world:getAgentCount()

-- getGlobalBlackboard() → Blackboard
local global_bb = world:getGlobalBlackboard()

-- update(dt) — tick all agents
world:update(0.016)

-- ── Agent Methods ─────────────────────────────────────────────────────────────

-- Recreate agent for demos below
local a = world:addAgent("hero", 400, 300)

-- Identity
local name = a:getName()    -- "hero"

-- Position and movement
a:setPosition(500, 300)
local ax, ay = a:getPosition()

a:setVelocity(50, 0)         -- pixels/s
local vx, vy = a:getVelocity()

a:setMaxSpeed(200)
local ms = a:getMaxSpeed()

a:setMaxForce(400)
local mf = a:getMaxForce()

a:setPriority(10)            -- higher = processed first each tick
local pri = a:getPriority()

-- Decision model (set at construction or update)
-- "fsm" | "bt" | "utility" | "goap" — actual model object set via setDecisionModel
a:setDecisionModel(fsm_object)
local decision_model = a:getDecisionModel()

-- Tags for group classification
a:addTag("ally")
a:addTag("melee")
a:removeTag("melee")
local has = a:hasTag("ally")  -- true

-- Per-agent blackboard
local bb = a:getBlackboard()

-- ── Blackboard ────────────────────────────────────────────────────────────────

-- newBlackboard() → Blackboard (standalone, or use agent/world getBlackboard())
local bb2 = lurek.ai.newBlackboard()

-- setNumber / getNumber
global_bb:setNumber("player_x", 320)
local px = global_bb:getNumber("player_x")   -- 320

-- setString / getString
global_bb:setString("state", "patrol")
local state = global_bb:getString("state")   -- "patrol"

-- setBool / getBool
global_bb:setBool("alerted", false)
local alerted = global_bb:getBool("alerted")  -- false

-- hasKey(key) → boolean
local has_key = global_bb:hasKey("player_x")  -- true

-- remove(key)
global_bb:remove("state")

-- ── Finite State Machine ──────────────────────────────────────────────────────

-- newStateMachine() → StateMachine
local fsm = lurek.ai.newStateMachine()

-- addState(name, onEnter, onExit, onUpdate)
-- onEnter/onExit/onUpdate are Lua callbacks: function(agent, dt)
fsm:addState("patrol",
    function(agent) print(agent:getName() .. " starts patrolling") end,
    function(agent) print(agent:getName() .. " stops patrolling") end,
    function(agent, dt)
        -- movement logic here
    end
)

fsm:addState("chase",
    function(agent) agent:getBlackboard():setBool("chasing", true) end,
    function(agent) agent:getBlackboard():setBool("chasing", false) end,
    function(agent, dt) end
)

-- addTransition(from, to, condition_fn)
-- condition_fn(agent) → boolean : returns true to trigger transition
fsm:addTransition("patrol", "chase", function(agent)
    local bb3 = agent:getBlackboard()
    return bb3:getBool("alerted")
end)

fsm:addTransition("chase", "patrol", function(agent)
    return not agent:getBlackboard():getBool("alerted")
end)

-- setInitialState(name)
fsm:setInitialState("patrol")

-- update(agent, dt) — tick the FSM for a given agent
fsm:update(a, 0.016)

-- getCurrentState(agent) → string
local cur = fsm:getCurrentState(a)  -- "patrol"

-- ── Behavior Tree ─────────────────────────────────────────────────────────────

-- newBehaviorTree() → BehaviorTree
local bt = lurek.ai.newBehaviorTree()

-- BT node constructors (return BTNode objects)
local root_seq = lurek.ai.newSequence()         -- runs children left-to-right until one fails
local selector  = lurek.ai.newSelector()        -- tries children until one succeeds
local parallel  = lurek.ai.newParallel("requireAll", "requireOne")  -- run all children concurrently
local inverter  = lurek.ai.newInverter()        -- inverts child result (success↔failure)
local repeater  = lurek.ai.newRepeater(5)       -- repeat child N times (0 = infinite)
local succeeder = lurek.ai.newSucceeder()        -- always succeeds

local action = lurek.ai.newAction(function(agent, dt)
    -- perform an action; return "success" | "failure" | "running"
    agent:setPosition(agent:getPosition())   -- example: stay in place
    return "success"
end)

local condition = lurek.ai.newCondition(function(agent, dt)
    return agent:getBlackboard():getBool("alerted")  -- true = success
end)

-- addChild(node) — attach children to composite/decorator nodes
root_seq:addChild(condition)
root_seq:addChild(action)

-- setRoot(node) — assign root node to the tree
bt:setRoot(root_seq)

-- update(agent, dt) → "success" | "failure" | "running"
local result = bt:update(a, 0.016)

-- ── Steering Behaviors ────────────────────────────────────────────────────────

-- newSteeringManager() → SteeringManager
local steering = lurek.ai.newSteeringManager()

-- addBehavior(type, weight, opts?) — types include:
"seek", "flee", "pursue", "evade", "arrive", "wander",
"cohesion", "separation", "alignment", "obstacleAvoidance",
"pathFollow", "interpose", "hide"
steering:addBehavior("seek",     1.0)
steering:addBehavior("arrive",   1.0, { slowRadius = 80, stopRadius = 10 })
steering:addBehavior("wander",   0.3, { wanderRadius = 50, wanderDist = 100 })
steering:addBehavior("separation", 0.8)

-- setTarget(x, y) — target position for seek/flee/pursue/evade/arrive/interpose/hide
steering:setTarget(600, 400)

-- update(agent, dt) → force_x, force_y — returns a steering force
local fx, fy = steering:update(a, 0.016)

-- applyForce(agent) — directly applies the computed force to the agent
steering:applyForce(a)

-- ── Q-Learning ────────────────────────────────────────────────────────────────

-- newQLearner(stateCount, actionCount) → QLearner
local q = lurek.ai.newQLearner(16, 4)   -- 16 states, 4 actions

-- setLearningRate(v) / getLearningRate() → number
q:setLearningRate(0.1)

-- setDiscount(v) / getDiscount() → number
q:setDiscount(0.95)

-- setEpsilon(v) / getEpsilon() → number  (exploration rate)
q:setEpsilon(0.1)

-- chooseAction(state) → integer (action index, 0-based)
local action_idx = q:chooseAction(0)

-- update(state, action, reward, nextState)
q:update(0, action_idx, 1.0, 1)

-- getBestAction(state) → integer
local best = q:getBestAction(2)

-- ── Utility AI ────────────────────────────────────────────────────────────────

-- newUtilityAI() → UtilityAI
local util_ai = lurek.ai.newUtilityAI()

-- addAction(name, scorer_fn, executor_fn)
-- scorer_fn(agent, blackboard) → number (0..1 how useful this action is right now)
-- executor_fn(agent, dt) — called when this action wins
util_ai:addAction("attack",
    function(ag, bb) return bb:getNumber("distance_to_enemy") < 150 and 1.0 or 0.0 end,
    function(ag, dt) -- attack logic
    end
)

util_ai:addAction("flee",
    function(ag, bb) return ag:getBlackboard():getNumber("health") < 20 and 0.9 or 0.0 end,
    function(ag, dt) -- flee logic
    end
)

-- update(agent, dt) — score all actions and execute the highest-scoring one
util_ai:update(a, 0.016)

-- getBestAction(agent) → string — just query without executing
local best_action = util_ai:getBestAction(a)

-- ── GOAP (Goal-Oriented Action Planning) ──────────────────────────────────────

-- newGOAPPlanner() → GOAPPlanner
local goap = lurek.ai.newGOAPPlanner()

-- addAction(name, preconditions, effects, cost, executor_fn)
goap:addAction("getAmmo",
    { hasAmmo = false },
    { hasAmmo = true },
    1.0,
    function(agent, dt) -- collect ammo logic
    end
)

goap:addAction("shootEnemy",
    { hasAmmo = true, canSeeEnemy = true },
    { enemyDead = true },
    1.0,
    function(agent, dt) -- shoot logic
    end
)

-- plan(agent, worldState, goalState) → boolean — compute a plan
local worldState = { hasAmmo = false, canSeeEnemy = true, enemyDead = false }
local goalState  = { enemyDead = true }
local planned = goap:plan(a, worldState, goalState)

-- update(agent, dt) — execute current plan step
if planned then
    goap:update(a, 0.016)
end

-- getDone() → boolean — true when plan is complete or failed
local done = goap:getDone()

-- ── Influence Map ─────────────────────────────────────────────────────────────

-- newInfluenceMap(width, height, cellSize) → InfluenceMap
local imap = lurek.ai.newInfluenceMap(50, 40, 20)

-- addLayer(name) → integer (layer id)
local threat_layer = imap:addLayer("threat")
local control_layer = imap:addLayer("control")

-- propagate(layer, x, y, strength, falloff)
imap:propagate(threat_layer, 300, 200, 1.0, 0.1)

-- getValue(layer, x, y) → number
local v = imap:getValue(threat_layer, 300, 200)

-- update(decayRate?)
imap:update(0.95)

-- ── Squad (Formation) ─────────────────────────────────────────────────────────

-- newSquad(name) → Squad
local squad = lurek.ai.newSquad("alpha_squad")

-- addMember(agent) / removeMember(agent)
squad:addMember(a)

-- setFormation(type, opts?) — types: "line", "column", "wedge", "circle", "box"
squad:setFormation("wedge", { spacing = 30 })

-- getFormationPosition(memberIndex) → x, y
local fx2, fy2 = squad:getFormationPosition(0)

-- update(leaderX, leaderY, leaderAngle, dt)
squad:update(400, 300, 0, 0.016)

-- ── Command Queue (RTS) ───────────────────────────────────────────────────────

-- newCommandQueue() → CommandQueue
local cmdq = lurek.ai.newCommandQueue()

-- push(command) — command is a table with a "type" field
cmdq:push({ type = "moveTo", x = 500, y = 300, speed = 150 })
cmdq:push({ type = "attack", targetName = "enemy_01" })
cmdq:push({ type = "idle",   duration = 2.0 })

-- update(agent, dt) — execute front command; auto-advances when done
cmdq:update(a, 0.016)

-- hasCommands() → boolean
local busy = cmdq:hasCommands()

-- clearCommands()
cmdq:clearCommands()

-- ─── AIWorld ──────────────────────────────────────────────────────────────────────────
-- Type-identity methods on AIWorld — use when a shared function receives any AI
-- container object and needs to branch on type at runtime.

local world_type = world:type()          -- "AIWorld"
local world_is   = world:typeOf("AIWorld")  -- true

-- ─── Agent ────────────────────────────────────────────────────────────────────────────
-- Type-identity methods on Agent — complement getName/getPosition; use when an
-- event callback receives an unknown AI object and must guard on type.

local a_type = a:type()         -- "Agent"
local a_is   = a:typeOf("Agent")  -- true

-- ─── BTNode ───────────────────────────────────────────────────────────────────────────
-- Low-level BTNode introspection and mutation — build custom composite wrappers
-- and hot-edit tree structure without rebuilding from scratch each frame.

local child_count = btnode:getChildCount()   -- integer: number of direct children
local rep_count   = btnode:getCount()        -- integer: repeat budget (0 = infinite)
local node_kind   = btnode:getNodeType()     -- "Repeater" | "Sequence" | "Leaf" | …

-- reset() clears all running-child bookmarks and repeater iteration counters;
-- call before re-ticking a cached tree at the start of a new decision cycle.
btnode:reset()

-- setChild(node) replaces the single wrapped child of a decorator node
-- (Invert / Repeat / Delay).  Pass btroot (the root Sequence defined above) to
-- make this decorator wrap the entire subtree.
btnode:setChild(btroot)      -- decorator now wraps the root Sequence

-- setCount(n) changes the repeat budget on an existing Repeater node.
btnode:setCount(3)           -- repeat up to 3 times, then propagate failure

-- Parallel policy — set BOTH axes explicitly; they are independent of each other.
-- setFailurePolicy: "any" → abort as soon as one child fails
"all" → only fail once ALL children have failed
-- setSuccessPolicy: "all" → require every child to succeed before succeeding
"any" → succeed the moment any one child succeeds
btnode:setFailurePolicy("any")    -- early abort on first child failure
btnode:setSuccessPolicy("all")    -- unanimous success required

local btnode_type = btnode:type()            -- "BTNode"
local btnode_is   = btnode:typeOf("BTNode")  -- true

-- ─── BehaviorTree ─────────────────────────────────────────────────────────────────
-- Read the result of the last tick without re-ticking — lets a StateMachine
-- transition condition poll the tree status each frame at zero cost.

local last_status = behaviortree:getLastStatus()  -- "success" | "failure" | "running"

local bt_type = behaviortree:type()               -- "BehaviorTree"
local bt_is   = behaviortree:typeOf("BehaviorTree")  -- true

-- ─── Blackboard ───────────────────────────────────────────────────────────────────────
-- Key-management and introspection for the per-agent Blackboard — complement
-- setNumber/getString/setBool; guard optional reads with has() to avoid nil.

local has_last_x = blackboard:has("last_known_x")  -- bool: true if key was written
local keys = blackboard:getKeys()   -- { "enemy_visible", "last_known_x", … }
local sz   = blackboard:getSize()   -- integer: total key count

-- Surgically erase one key without wiping the rest of the board.
blackboard:clear("enemy_visible")

local bb_type = blackboard:type()               -- "Blackboard"
local bb_is   = blackboard:typeOf("Blackboard") -- true

-- ─── CommandQueue ─────────────────────────────────────────────────────────────────
-- Queue-inspection and mid-flight cancellation — the core primitive for RTS
-- interrupt patterns (e.g. a new attack order cancels an ongoing patrol leg).

local q_count = cmdq:getCount()    -- integer: commands still queued
local q_empty = cmdq:isEmpty()     -- true when no commands remain

-- getCurrentType and getCurrentTarget peek at the front command without
-- consuming it; both return nil when the queue is empty.
local cur_type   = cmdq:getCurrentType()    -- "moveTo" | "attack" | … | nil
local cx, cy     = cmdq:getCurrentTarget()  -- world-space (x, y) or nil

-- cancelCurrent() aborts the front command only if it was pushed as
-- interruptible — non-interruptible commands (e.g. "attack") are left intact.
cmdq:cancelCurrent()

-- clear() discards ALL pending commands — use on agent death or when the
-- player issues a "halt all units" order.
cmdq:clear()

local cq_type = cmdq:type()                -- "CommandQueue"
local cq_is   = cmdq:typeOf("CommandQueue")  -- true

-- ─── GOAPPlanner ──────────────────────────────────────────────────────────────────
-- Supplemental count accessors — useful in debug UI panels that list the full
-- goal and action inventory, and in unit-test assertions.

local n_actions = goapplanner:getActionCount()  -- integer: registered action count
local n_goals   = goapplanner:getGoalCount()    -- integer: registered goal count

local goap_type = goapplanner:type()                 -- "GOAPPlanner"
local goap_is   = goapplanner:typeOf("GOAPPlanner")  -- true

-- ─── InfluenceMap ─────────────────────────────────────────────────────────────────
-- Bulk-clear, per-frame decay, and grid-dimension accessors — building blocks
-- for dynamic threat maps that reset at wave boundaries and fade over time.

-- Zero all layers simultaneously — use at wave-start or level-load.
influencemap:clearAll()

-- Zero a single named layer while leaving all others intact.
influencemap:clearLayer("threat")

-- Multiply every cell by the decay factor each frame so that stale influence
-- fades naturally rather than persisting until it is explicitly cleared.
influencemap:decay("threat", 0.95)

-- Grid dimensions for overlay rendering or manual cell-iteration loops.
local cell_sz = influencemap:getCellSize()  -- world units per cell (e.g. 20)
local grid_w  = influencemap:getWidth()     -- column count
local grid_h  = influencemap:getHeight()    -- row count

-- Locate the hottest and coldest cells; useful for directing units toward the
-- highest-threat position or placing spawn points at the safest location.
local max_xy = influencemap:getMaxPosition("threat")  -- {x, y} world pos of highest-influence cell
local min_xy = influencemap:getMinPosition("threat")  -- {x, y} world pos of lowest-influence cell

-- Guard before accessing a layer whose existence is not guaranteed.
local has_threat = influencemap:hasLayer("threat")  -- bool

local im_type = influencemap:type()                -- "InfluenceMap"
local im_is   = influencemap:typeOf("InfluenceMap")  -- true

-- ─── QLearner ─────────────────────────────────────────────────────────────────────────
-- Hyperparameter accessors, episode lifecycle, Q-value inspection, and JSON
-- serialisation — together they enable saving and restoring a trained agent.

-- Read back current hyperparameters.
local alpha   = qlearner:getLearningRate()      -- number (e.g. 0.1)
local gamma   = qlearner:getDiscountFactor()    -- number (e.g. 0.95)
local epsilon = qlearner:getExplorationRate()   -- current ε
local e_decay = qlearner:getExplorationDecay()  -- ε multiplier applied per episode

-- Override hyperparameters at runtime (curriculum schedules, annealing).
qlearner:setDiscountFactor(0.99)
qlearner:setExplorationRate(0.05)
qlearner:setExplorationDecay(0.999)

-- Space dimensions.
local n_states = qlearner:getStateCount()   -- integer: discrete state count
local n_act    = qlearner:getActionCount()  -- integer: discrete action count

-- Inspect a single Q-value; indices are 1-based.
local qv = qlearner:getQValue(1, 2)  -- Q(state=1, action=2) → number

-- bestAction() returns the greedy-best action with NO exploration roll — use it
-- when evaluation mode is active (ε = 0) or for a deterministic final policy.
local best = qlearner:bestAction(1)   -- integer: greedy-best action index for state 1 (1-based)

-- endEpisode() applies epsilon decay and increments the episode counter.
qlearner:endEpisode()
local episodes = qlearner:getEpisodeCount()  -- integer: completed episodes to date

-- Serialize the full Q-table to JSON and restore it from a saved string —
-- integrate with lurek.savegame to persist learned behaviour across play sessions.
local saved_json = qlearner:serialize()      -- JSON string
qlearner:deserialize(saved_json)             -- restore Q-table from a prior save

local ql_type = qlearner:type()              -- "QLearner"
local ql_is   = qlearner:typeOf("QLearner")  -- true

-- ─── Squad ────────────────────────────────────────────────────────────────────────────
-- Member-roster management and formation inspection — implement dynamic rosters
-- (unit deaths, reinforcements) and populate HUD squad-status panels.

local formation = squad:getFormation()         -- "wedge" | "line" | "circle" | …
local spacing   = squad:getFormationSpacing()  -- world units between formation slots

-- Promote a new leader; the leader occupies slot 0 in the formation.
squad:setLeader("commander")
local leader = squad:getLeader()               -- "commander" | nil

-- Remove a casualty from the roster without dissolving the squad.
squad:removeMember("scout_02")

local n_members = squad:getMemberCount()  -- integer: current roster size
local names     = squad:getMembers()      -- { "commander", "rifleman_01", … }

local sq_type = squad:type()              -- "Squad"
local sq_is   = squad:typeOf("Squad")     -- true

-- ─── StateMachine ─────────────────────────────────────────────────────────────────
-- Override transitions and query dwell time — essential for hit-stun, death,
-- and timeout transitions that must bypass configured guard conditions.

-- forceState() ignores ALL transition guards — use for external triggers such
-- as a "hit" event or a global stun that must interrupt the current state.
statemachine:forceState("stunned")

-- getTimeInState() returns seconds elapsed since the last state entry; use to
-- implement "patrol for N seconds then return to idle" timeout patterns.
local dwell = statemachine:getTimeInState()  -- number (seconds)

local fsm_type = statemachine:type()                  -- "StateMachine"
local fsm_is   = statemachine:typeOf("StateMachine")  -- true

-- ─── SteeringManager ─────────────────────────────────────────────────────────────
-- Manager-level tuning: inspect the last computed force vector and control how
-- multiple behavior outputs are blended without touching individual weights.

local n_beh            = steeringmanager:getBehaviorCount()   -- integer: active behaviors
local last_fx, last_fy = steeringmanager:getLastSteering()    -- (vx, vy) last output force

-- getCombineMode() returns the active blend strategy (default: "weighted").
local mode = steeringmanager:getCombineMode()  -- "weighted" | "priority" | "blended"

-- setCombineMode(strategy) — three strategies:
"weighted"  → weighted sum of all forces (smooth; all behaviors contribute)
"priority"  → highest-weight behavior wins outright (decisive switching)
"blended"   → forces are normalised then averaged (equal-magnitude blend)
steeringmanager:setCombineMode("priority")  -- one winner per frame

local stm_type = steeringmanager:type()                      -- "SteeringManager"
local stm_is   = steeringmanager:typeOf("SteeringManager")   -- true

-- ─── UtilityAI ─────────────────────────────────────────────────────────────────────────
-- Score all actions and inspect the winner without triggering side effects — use
-- in debug overlays and unit tests that must not execute game logic.

-- evaluate() scores every action and returns the winner's name — identical to
-- update() but does NOT invoke the executor callback.
local best_action = utilityai:evaluate()       -- "attack" | "flee" | … | nil

local n_uai_act  = utilityai:getActionCount()  -- integer: registered action count
local last_taken = utilityai:getLastAction()   -- last-executed action name or nil

local uai_type = utilityai:type()               -- "UtilityAI"
local uai_is   = utilityai:typeOf("UtilityAI")  -- true

-- ─────────────────────────────────────────────────────────────────────────────
-- Blackboard
-- A shared key-value store for AI agents to communicate decisions and state.
-- Use with lurek.ai.newWorld() and agent:setBlackboard().
-- ─────────────────────────────────────────────────────────────────────────────

local bb = lurek.ai.newBlackboard("shared")

-- Write facts (boolean, number, or string values)
bb:set("enemy_visible", true)
bb:set("last_seen_x",   320.0)
bb:set("target_name",   "player")

-- Read facts back; returns nil if the key has never been set
local visible  = bb:get("enemy_visible")   -- true
local x        = bb:get("last_seen_x")     -- 320.0

-- All currently set fact keys
local all_keys = bb:keys()   -- { "enemy_visible", "last_seen_x", "target_name" }

-- Snapshot copies all facts into a plain Lua table (useful for serialising AI state)
local snap = bb:snapshot()   -- { enemy_visible=true, last_seen_x=320.0, target_name="player" }

-- Revision counter increments on every write (use to detect stale reads)
local rev = bb:getRevision()   -- 3 (one per set() call above)

-- Watch a specific key for changes (returns a subscription id)
local id1 = bb:watch("enemy_visible", function(key, val, old)
    lurek.log.info(string.format("[BB] %s changed: %s -> %s", key, tostring(old), tostring(val)))
end)

-- Watch ALL keys with the wildcard "*"
local id2 = bb:watch("*", function(key, val, old)
    lurek.log.debug(string.format("[BB] any write: %s = %s", key, tostring(val)))
end)

-- Trigger callbacks
bb:set("enemy_visible", false)

-- Unsubscribe a specific watcher by id
bb:unwatch(id1)
bb:unwatch(id2)

lurek.log.info("[ai.lua] Blackboard example complete")
