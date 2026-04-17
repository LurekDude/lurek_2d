-- content/examples/ai.lua
-- Lurek2D lurek.ai API Reference
-- Run with: cargo run -- content/examples/ai
--
-- Scenario: An open-world RPG with AI-driven NPCs — behavior trees for enemy
-- guards, finite state machines for villager routines, steering behaviours for
-- crowd movement, Q-learning for adaptive enemies, utility AI for NPC decisions,
-- GOAP for quest-giving NPCs, influence maps for territory control, squads for
-- coordinated patrols, blackboards for shared knowledge, neural nets for
-- difficulty tuning, emotion models for NPC moods, ORCA for crowd avoidance,
-- genetic algorithms for procedural creature stats, context steering for
-- obstacle avoidance, needs systems for survival mechanics, AI director for
-- dynamic difficulty, HTN planning for complex quest sequences, MCTS for
-- tactical combat decisions, and neuroevolution for breeding champion fighters.

print("=== lurek.ai — Open-World RPG AI Systems ===\n")

-- =============================================================================
-- AI World & Agents — top-level simulation container
-- =============================================================================

-- ---- Stub: lurek.ai.newWorld ---------------------------------------------
--@api-stub: lurek.ai.newWorld
-- The AIWorld is the root container for all AI agents in the scene.
-- Create it once during level load and call update() each frame.
local ai_world = lurek.ai.newWorld()
print("AI world created — ready to accept agents")

-- ---- Stub: AIWorld:addAgent -----------------------------------------------
--@api-stub: AIWorld:addAgent
-- Register named agents at world positions. Each agent gets a private
-- blackboard, tags, and a decision model slot for FSM/BT/Utility.
local guard = ai_world:addAgent("guard_captain", {x = 100, y = 200})
local villager = ai_world:addAgent("baker", {x = 300, y = 400})
local wolf = ai_world:addAgent("alpha_wolf", {x = 500, y = 100})
local scout = ai_world:addAgent("scout_drone", {x = 50, y = 50})
print("4 agents added: guard_captain, baker, alpha_wolf, scout_drone")
print("  guard spawned at gatehouse entrance (100, 200)")
print("  baker spawned at bakery interior (300, 400)")

-- ---- Stub: AIWorld:getAgent -----------------------------------------------
--@api-stub: AIWorld:getAgent
-- Retrieve an agent handle by name for later configuration.
-- Returns nil if the name is not found in the world.
local g = ai_world:getAgent("guard_captain")
if g then
    print("retrieved agent handle for: " .. g:getName())
else
    print("guard_captain not found in AI world")
end

-- ---- Stub: AIWorld:getAgentCount ------------------------------------------
--@api-stub: AIWorld:getAgentCount
-- Use agent count for HUD display or to gate spawning logic.
local agent_count = ai_world:getAgentCount()
print("total agents in world: " .. tostring(agent_count))
if agent_count >= 4 then
    print("  world is populated — skipping additional spawns")
end

-- ---- Stub: AIWorld:getGlobalBlackboard ------------------------------------
--@api-stub: AIWorld:getGlobalBlackboard
-- The global blackboard is shared across all agents — use it for world-level
-- facts like "alarm_active", "time_of_day", or "player_last_seen_pos".
local global_bb = ai_world:getGlobalBlackboard()
global_bb:setString("time_of_day", "night")
global_bb:setBool("alarm_active", false)
global_bb:setNumber("player_threat_level", 0.3)
print("global blackboard configured:")
print("  time_of_day = " .. tostring(global_bb:getString("time_of_day")))
print("  alarm_active = " .. tostring(global_bb:getBool("alarm_active")))

-- ---- Stub: AIWorld:update -------------------------------------------------
--@api-stub: AIWorld:update
-- Call once per frame with delta time. This ticks all agents' decision models,
-- steering behaviours, and state machines simultaneously.
local dt = 0.016  -- ~60 FPS frame time
ai_world:update(dt)
ai_world:update(dt)
ai_world:update(dt)
print("AI world stepped 3 frames (48ms total game time)")

-- ---- Stub: AIWorld:type ---------------------------------------------------
--@api-stub: AIWorld:type
-- ---- Stub: AIWorld:typeOf -------------------------------------------------
--@api-stub: AIWorld:typeOf
-- Type introspection for debug overlays.
print("world type: " .. tostring(ai_world:type()))
print("world typeOf check: " .. tostring(ai_world:typeOf("AIWorld")))

-- =============================================================================
-- Agent — individual NPC properties
-- =============================================================================

-- ---- Stub: Agent:getName --------------------------------------------------
--@api-stub: Agent:getName
-- Each agent has a unique name assigned at creation. Use it for debug logging,
-- save/load identification, or HUD labelling.
local guard_name = guard:getName()
local wolf_name = wolf:getName()
print("guard name: " .. guard_name .. ", wolf name: " .. wolf_name)

-- ---- Stub: Agent:setPosition ----------------------------------------------
--@api-stub: Agent:setPosition
-- Teleport the guard to a new patrol waypoint. In a real game this would be
-- called during cutscenes, spawn logic, or after loading a save file.
guard:setPosition(120, 210)
villager:setPosition(310, 390)
print("guard repositioned to gatehouse inner post (120, 210)")
print("baker moved to oven area (310, 390)")

-- ---- Stub: Agent:getPosition ----------------------------------------------
--@api-stub: Agent:getPosition
-- Read back position for distance checks, line-of-sight, or minimap markers.
local gx, gy = guard:getPosition()
local wx, wy = wolf:getPosition()
local dist = math.sqrt((gx - wx)^2 + (gy - wy)^2)
print("guard at (" .. gx .. ", " .. gy .. ")")
print("wolf at (" .. wx .. ", " .. wy .. ")")
print("distance guard<->wolf: " .. string.format("%.1f", dist) .. " units")

-- ---- Stub: Agent:setVelocity ----------------------------------------------
--@api-stub: Agent:setVelocity
-- Set the agent's movement direction and speed. Steering behaviours override
-- this each frame, but you can set it manually for scripted sequences.
guard:setVelocity(2.0, 0.0)   -- patrol east at 2 units/sec
wolf:setVelocity(-3.0, 1.5)   -- wolf loping southwest
print("guard velocity set to (2.0, 0.0) — eastward patrol")
print("wolf velocity set to (-3.0, 1.5) — approaching from northeast")

-- ---- Stub: Agent:getVelocity ----------------------------------------------
--@api-stub: Agent:getVelocity
-- Read velocity for prediction or animation blend calculations.
local gvx, gvy = guard:getVelocity()
local speed = math.sqrt(gvx^2 + gvy^2)
print("guard velocity: (" .. gvx .. ", " .. gvy .. ") speed=" .. string.format("%.2f", speed))
if speed > 1.5 then
    print("  guard is jogging — play jog animation")
else
    print("  guard is walking — play walk animation")
end

-- ---- Stub: Agent:setMaxSpeed ----------------------------------------------
--@api-stub: Agent:setMaxSpeed
-- Cap movement speed so agents don't exceed their animation's top pace.
guard:setMaxSpeed(4.0)     -- armoured guard moves slower
wolf:setMaxSpeed(8.0)      -- wolf is much faster
villager:setMaxSpeed(2.5)  -- baker ambles slowly
print("max speeds: guard=4.0, wolf=8.0, baker=2.5")

-- ---- Stub: Agent:getMaxSpeed ----------------------------------------------
--@api-stub: Agent:getMaxSpeed
-- Read max speed to calculate arrival time or chase feasibility.
local guard_max = guard:getMaxSpeed()
local wolf_max = wolf:getMaxSpeed()
print("guard max speed: " .. tostring(guard_max))
if wolf_max > guard_max then
    print("  wolf can outrun the guard — guard should call for backup!")
end

-- ---- Stub: Agent:setMaxForce ----------------------------------------------
--@api-stub: Agent:setMaxForce
-- Max force controls how sharply steering behaviours can turn the agent.
-- Low force = wide lazy turns (vehicles), high force = snappy direction changes.
guard:setMaxForce(10.0)   -- armoured guard: sluggish turns
wolf:setMaxForce(25.0)    -- wolf: agile, quick direction changes
print("max force: guard=10.0 (heavy), wolf=25.0 (agile)")

-- ---- Stub: Agent:getMaxForce ----------------------------------------------
--@api-stub: Agent:getMaxForce
local guard_force = guard:getMaxForce()
print("guard max steering force: " .. tostring(guard_force))

-- ---- Stub: Agent:setPriority ----------------------------------------------
--@api-stub: Agent:setPriority
-- Higher priority agents get processed first. Use for boss enemies or
-- player-critical NPCs that must always have up-to-date AI.
guard:setPriority(5)    -- high priority: gate guard is mission-critical
villager:setPriority(1) -- low priority: baker is background flavour
wolf:setPriority(3)     -- medium: threat to player but not scripted
print("priorities: guard=5 (critical), wolf=3 (threat), baker=1 (ambient)")

-- ---- Stub: Agent:getPriority ----------------------------------------------
--@api-stub: Agent:getPriority
local gp = guard:getPriority()
print("guard priority: " .. tostring(gp))

-- ---- Stub: Agent:setDecisionModel -----------------------------------------
--@api-stub: Agent:setDecisionModel
-- Attach an FSM, BT, or UtilityAI to drive this agent's behaviour.
-- We'll create the FSM below and attach it here.
local guard_fsm = lurek.ai.newStateMachine()
guard_fsm:addState("patrol", {
    enter = function() print("    [guard] entering patrol route") end,
    update = function(dt) end,
    exit = function() print("    [guard] leaving patrol") end,
    transitions = { {target = "alert", condition = function()
        return global_bb:getBool("alarm_active")
    end} }
})
guard_fsm:addState("alert", {
    enter = function() print("    [guard] ALERT — drawing weapon!") end,
    update = function(dt) end,
    exit = function() print("    [guard] standing down") end,
    transitions = { {target = "patrol", condition = function()
        return not global_bb:getBool("alarm_active")
    end} }
})
guard_fsm:setInitialState("patrol")
guard:setDecisionModel(guard_fsm)
print("guard decision model: finite state machine (patrol <-> alert)")

-- ---- Stub: Agent:getDecisionModel -----------------------------------------
--@api-stub: Agent:getDecisionModel
-- Retrieve the current decision model to inspect its state or swap it.
local model = guard:getDecisionModel()
print("guard has decision model: " .. tostring(model ~= nil))

-- ---- Stub: Agent:addTag ---------------------------------------------------
--@api-stub: Agent:addTag
-- Tags let you query groups of agents efficiently — "hostile", "merchant",
-- "quest_giver" — without maintaining separate lists.
guard:addTag("hostile")
guard:addTag("armored")
guard:addTag("faction_royal")
villager:addTag("friendly")
villager:addTag("merchant")
wolf:addTag("hostile")
wolf:addTag("animal")
print("guard tags: hostile, armored, faction_royal")
print("villager tags: friendly, merchant")

-- ---- Stub: Agent:removeTag ------------------------------------------------
--@api-stub: Agent:removeTag
-- Remove a tag when the game state changes (e.g. guard is bribed).
guard:removeTag("hostile")
print("guard bribed — removed 'hostile' tag, now neutral")

-- ---- Stub: Agent:hasTag ---------------------------------------------------
--@api-stub: Agent:hasTag
-- Check tags before applying damage, dialog, or loot tables.
local is_hostile = guard:hasTag("hostile")
local is_armored = guard:hasTag("armored")
print("guard hostile: " .. tostring(is_hostile) .. ", armored: " .. tostring(is_armored))
if not is_hostile and is_armored then
    print("  neutral armored NPC — show barter dialog")
end

-- ---- Stub: Agent:getBlackboard --------------------------------------------
--@api-stub: Agent:getBlackboard
-- Each agent's private blackboard stores agent-specific memory:
-- last seen player position, health state, ammo count, etc.
local guard_bb = guard:getBlackboard()
guard_bb:setNumber("patrol_waypoint_idx", 0)
guard_bb:setNumber("suspicion_level", 0.0)
guard_bb:setBool("has_key", true)
print("guard blackboard initialised:")
print("  patrol_waypoint_idx = 0")
print("  has_key = " .. tostring(guard_bb:getBool("has_key")))

-- ---- Stub: Agent:type -----------------------------------------------------
--@api-stub: Agent:type
-- ---- Stub: Agent:typeOf ---------------------------------------------------
--@api-stub: Agent:typeOf
print("agent type: " .. tostring(guard:type()))
print("agent typeOf Agent: " .. tostring(guard:typeOf("Agent")))

-- =============================================================================
-- Blackboard — shared knowledge store
-- =============================================================================

-- ---- Stub: lurek.ai.newBlackboard -----------------------------------------
--@api-stub: lurek.ai.newBlackboard
-- Standalone blackboards can be used outside the AI world — for example,
-- as a parameter store for a quest system or dialog tree.
local quest_bb = lurek.ai.newBlackboard()
print("standalone blackboard created for quest tracking")

-- ---- Stub: Blackboard:setNumber ------------------------------------------
--@api-stub: Blackboard:setNumber
-- Track numeric quest state: kill counts, collected items, distances.
quest_bb:setNumber("wolves_killed", 0)
quest_bb:setNumber("bounty_gold", 50)
quest_bb:setNumber("quest_timer_sec", 300.0)
print("quest state: wolves_killed=0, bounty=50g, timer=300s")

-- ---- Stub: Blackboard:setBool --------------------------------------------
--@api-stub: Blackboard:setBool
-- Boolean flags for quest milestones or world state toggles.
quest_bb:setBool("quest_accepted", true)
quest_bb:setBool("boss_defeated", false)
quest_bb:setBool("escape_route_open", false)
print("quest flags: accepted=true, boss_defeated=false")

-- ---- Stub: Blackboard:setString ------------------------------------------
--@api-stub: Blackboard:setString
-- Store text keys for dialog responses, objective descriptions, faction names.
quest_bb:setString("quest_giver", "Mayor Thornton")
quest_bb:setString("objective", "Clear the wolf den north of town")
quest_bb:setString("reward_item", "silver_sword")
print("quest: '" .. quest_bb:getString("objective") .. "' from " .. quest_bb:getString("quest_giver"))

-- ---- Stub: Blackboard:has ------------------------------------------------
--@api-stub: Blackboard:has
-- Check if a key exists before reading — prevents nil errors in conditionals.
if quest_bb:has("quest_giver") then
    print("quest giver is set: " .. quest_bb:getString("quest_giver"))
end
if not quest_bb:has("completion_time") then
    print("no completion_time recorded yet — quest still active")
end

-- ---- Stub: Blackboard:remove ----------------------------------------------
--@api-stub: Blackboard:remove
-- Remove keys when they become irrelevant (e.g. timer expired, phase ended).
quest_bb:remove("quest_timer_sec")
print("quest timer removed — now using event-driven completion")
print("  timer key exists: " .. tostring(quest_bb:has("quest_timer_sec")))

-- ---- Stub: Blackboard:getKeys ---------------------------------------------
--@api-stub: Blackboard:getKeys
-- Dump all keys for a debug overlay or save-game serialization.
local keys = quest_bb:getKeys()
print("blackboard keys (" .. #keys .. "):")
for i, k in ipairs(keys) do
    print("  [" .. i .. "] " .. k)
end

-- ---- Stub: Blackboard:getSize ---------------------------------------------
--@api-stub: Blackboard:getSize
local bb_size = quest_bb:getSize()
print("blackboard entries: " .. tostring(bb_size))

-- ---- Stub: Blackboard:clear -----------------------------------------------
--@api-stub: Blackboard:clear
-- Wipe the quest blackboard when starting a new game or switching quests.
local old_size = quest_bb:getSize()
quest_bb:clear()
print("blackboard cleared: " .. old_size .. " -> " .. quest_bb:getSize() .. " entries")

-- ---- Stub: Blackboard:type ------------------------------------------------
--@api-stub: Blackboard:type
-- ---- Stub: Blackboard:typeOf ----------------------------------------------
--@api-stub: Blackboard:typeOf
print("blackboard type: " .. tostring(quest_bb:type()))
print("blackboard typeOf: " .. tostring(quest_bb:typeOf("Blackboard")))

-- =============================================================================
-- Finite State Machine — villager daily routine
-- =============================================================================

-- ---- Stub: lurek.ai.newStateMachine ---------------------------------------
--@api-stub: lurek.ai.newStateMachine
-- The baker follows a 3-state daily cycle: baking, selling, sleeping.
-- Each state has enter/update/exit hooks and conditional transitions.
local baker_fsm = lurek.ai.newStateMachine()
print("baker FSM created for daily routine cycle")

-- ---- Stub: StateMachine:addState ------------------------------------------
--@api-stub: StateMachine:addState
-- Define states with behaviour hooks and transition conditions.
baker_fsm:addState("baking", {
    enter = function()
        print("    [baker] fires up the oven at dawn")
    end,
    update = function(dt)
        -- Simulate kneading dough each frame
    end,
    exit = function()
        print("    [baker] pulls loaves from oven")
    end,
    transitions = {
        { target = "selling", condition = function()
            return global_bb:getString("time_of_day") == "morning"
        end }
    }
})
baker_fsm:addState("selling", {
    enter = function() print("    [baker] opens shop window") end,
    update = function(dt) end,
    exit = function() print("    [baker] closes shop for the day") end,
    transitions = {
        { target = "sleeping", condition = function()
            return global_bb:getString("time_of_day") == "night"
        end }
    }
})
baker_fsm:addState("sleeping", {
    enter = function() print("    [baker] heads upstairs to bed") end,
    update = function(dt) end,
    exit = function() print("    [baker] wakes up at dawn") end,
    transitions = {
        { target = "baking", condition = function()
            return global_bb:getString("time_of_day") == "dawn"
        end }
    }
})
print("baker states: baking -> selling -> sleeping -> baking (cycle)")

-- ---- Stub: StateMachine:setInitialState -----------------------------------
--@api-stub: StateMachine:setInitialState
-- Set the starting state. The enter() hook fires on first update().
baker_fsm:setInitialState("baking")
print("baker initial state: baking (dawn start)")

-- ---- Stub: StateMachine:getCurrentState -----------------------------------
--@api-stub: StateMachine:getCurrentState
-- Query current state for HUD display or save-game persistence.
local bstate = baker_fsm:getCurrentState()
print("baker current state: " .. tostring(bstate))

-- ---- Stub: StateMachine:forceState ----------------------------------------
--@api-stub: StateMachine:forceState
-- Force a state change during cutscenes or scripted events.
-- Bypasses transition conditions.
baker_fsm:forceState("selling")
print("baker forced to 'selling' state (market event triggered)")
print("  new state: " .. tostring(baker_fsm:getCurrentState()))

-- ---- Stub: StateMachine:getTimeInState ------------------------------------
--@api-stub: StateMachine:getTimeInState
-- How long the NPC has been in this state — use for patience timers,
-- animation blending, or "idle too long" checks.
local time_selling = baker_fsm:getTimeInState()
print("baker time in selling state: " .. string.format("%.3f", time_selling) .. "s")

-- ---- Stub: StateMachine:type ----------------------------------------------
--@api-stub: StateMachine:type
-- ---- Stub: StateMachine:typeOf --------------------------------------------
--@api-stub: StateMachine:typeOf
print("FSM type: " .. tostring(baker_fsm:type()))
print("FSM typeOf: " .. tostring(baker_fsm:typeOf("StateMachine")))

-- =============================================================================
-- Behavior Tree — guard combat AI
-- =============================================================================

-- ---- Stub: lurek.ai.newBehaviorTree ---------------------------------------
--@api-stub: lurek.ai.newBehaviorTree
-- A behavior tree for the guard: checks for threats, decides to investigate
-- or attack, and falls back to patrol if nothing is found.
local guard_bt = lurek.ai.newBehaviorTree()
print("guard behavior tree created")

-- ---- Stub: lurek.ai.newSelector ------------------------------------------
--@api-stub: lurek.ai.newSelector
-- A selector tries children left-to-right until one succeeds (OR logic).
-- Use for "try attack, else investigate, else patrol" fallback chains.
local combat_selector = lurek.ai.newSelector()
print("combat selector: try attack -> investigate -> patrol")

-- ---- Stub: lurek.ai.newSequence -------------------------------------------
--@api-stub: lurek.ai.newSequence
-- A sequence runs children left-to-right until one fails (AND logic).
-- Use for "spot enemy AND draw weapon AND charge" multi-step actions.
local attack_sequence = lurek.ai.newSequence()
print("attack sequence: spot -> draw weapon -> charge -> strike")

-- ---- Stub: lurek.ai.newParallel -------------------------------------------
--@api-stub: lurek.ai.newParallel
-- Parallel runs all children simultaneously. Use for "patrol AND scan for threats"
-- where both behaviours must run concurrently.
local patrol_and_scan = lurek.ai.newParallel()
print("parallel node: patrol route + scan surroundings simultaneously")

-- ---- Stub: lurek.ai.newCondition ------------------------------------------
--@api-stub: lurek.ai.newCondition
-- Conditions are leaf nodes that check game state without side effects.
-- Returns success/failure based on the predicate.
local can_see_enemy = lurek.ai.newCondition(function()
    local threat = global_bb:getNumber("player_threat_level")
    return threat > 0.5
end)
print("condition node: 'can see enemy' (threat > 0.5)")

local has_ammo = lurek.ai.newCondition(function()
    return guard_bb:getNumber("suspicion_level") > 0.0
end)
print("condition node: 'suspicious' (suspicion > 0)")

-- ---- Stub: lurek.ai.newAction ---------------------------------------------
--@api-stub: lurek.ai.newAction
-- Action nodes perform game-world side effects: move, attack, play sound.
local swing_sword = lurek.ai.newAction(function()
    print("    [guard] swings sword at target!")
    return "success"
end)
local shout_alarm = lurek.ai.newAction(function()
    print("    [guard] shouts: INTRUDER!")
    global_bb:setBool("alarm_active", true)
    return "success"
end)
local walk_patrol = lurek.ai.newAction(function()
    local idx = guard_bb:getNumber("patrol_waypoint_idx")
    guard_bb:setNumber("patrol_waypoint_idx", idx + 1)
    return "success"
end)
print("action nodes: swing_sword, shout_alarm, walk_patrol")

-- ---- Stub: lurek.ai.newInverter ------------------------------------------
--@api-stub: lurek.ai.newInverter
-- Inverter flips success to failure and vice versa. Use for "if NOT safe, flee".
local not_safe = lurek.ai.newInverter()
not_safe:setChild(can_see_enemy)
print("inverter: NOT(can_see_enemy) = area is safe")

-- ---- Stub: lurek.ai.newRepeater ------------------------------------------
--@api-stub: lurek.ai.newRepeater
-- Repeater runs its child N times. Use for "attack 3 times then reassess".
local triple_strike = lurek.ai.newRepeater()
triple_strike:setCount(3)
triple_strike:setChild(swing_sword)
print("repeater: swing sword x3")

-- ---- Stub: lurek.ai.newSucceeder -----------------------------------------
--@api-stub: lurek.ai.newSucceeder
-- Succeeder always returns success regardless of child result.
-- Use to ensure optional actions don't break a sequence.
local optional_taunt = lurek.ai.newSucceeder()
optional_taunt:setChild(shout_alarm)
print("succeeder: alarm shout is optional (sequence continues even if it fails)")

-- ---- Stub: BTNode:addChild ------------------------------------------------
--@api-stub: BTNode:addChild
-- Build the tree by adding children to composite nodes.
attack_sequence:addChild(can_see_enemy)
attack_sequence:addChild(shout_alarm)
attack_sequence:addChild(triple_strike)

combat_selector:addChild(attack_sequence)
combat_selector:addChild(walk_patrol)

patrol_and_scan:addChild(combat_selector)
patrol_and_scan:addChild(not_safe)
print("tree assembled: parallel(selector(attack_seq, patrol), inverter)")

-- ---- Stub: BTNode:getChildCount -------------------------------------------
--@api-stub: BTNode:getChildCount
print("combat selector children: " .. tostring(combat_selector:getChildCount()))
print("attack sequence children: " .. tostring(attack_sequence:getChildCount()))

-- ---- Stub: BTNode:reset ---------------------------------------------------
--@api-stub: BTNode:reset
-- Reset clears running state on all nodes. Call between encounters or
-- when the guard loses sight of the player.
combat_selector:reset()
print("combat tree reset — guard returns to default behaviour")

-- ---- Stub: BTNode:setChild ------------------------------------------------
--@api-stub: BTNode:setChild
-- Decorators (inverter, repeater, succeeder) wrap a single child.
-- setChild replaces the wrapped node — useful for runtime behaviour swaps.
not_safe:setChild(has_ammo)
print("inverter child swapped: now inverts 'has_ammo' check")

-- ---- Stub: BTNode:setCount ------------------------------------------------
--@api-stub: BTNode:setCount
-- Change how many times a repeater loops. Useful for difficulty scaling.
triple_strike:setCount(5)
print("repeater count increased to 5 (hard mode: 5 rapid strikes)")

-- ---- Stub: BTNode:getCount ------------------------------------------------
--@api-stub: BTNode:getCount
local rep_count = triple_strike:getCount()
print("repeater count: " .. tostring(rep_count))

-- ---- Stub: BTNode:setSuccessPolicy ----------------------------------------
--@api-stub: BTNode:setSuccessPolicy
-- Parallel success policy: "one" = succeed if any child succeeds,
-- "all" = succeed only when every child succeeds.
patrol_and_scan:setSuccessPolicy("one")
print("parallel success policy: 'one' (succeed if either patrol or scan succeeds)")

-- ---- Stub: BTNode:setFailurePolicy ----------------------------------------
--@api-stub: BTNode:setFailurePolicy
-- Failure policy: "one" = fail on first child failure, "all" = fail only if all fail.
patrol_and_scan:setFailurePolicy("all")
print("parallel failure policy: 'all' (fail only if both patrol AND scan fail)")

-- ---- Stub: BTNode:getNodeType ---------------------------------------------
--@api-stub: BTNode:getNodeType
-- Introspect node type for debug tree visualisation.
print("combat_selector node type: " .. tostring(combat_selector:getNodeType()))
print("attack_sequence node type: " .. tostring(attack_sequence:getNodeType()))
print("triple_strike node type: " .. tostring(triple_strike:getNodeType()))

-- ---- Stub: BTNode:type ----------------------------------------------------
--@api-stub: BTNode:type
-- ---- Stub: BTNode:typeOf --------------------------------------------------
--@api-stub: BTNode:typeOf
print("BT node type: " .. tostring(combat_selector:type()))
print("BT node typeOf: " .. tostring(combat_selector:typeOf("BTNode")))

-- ---- Stub: BehaviorTree:setRoot -------------------------------------------
--@api-stub: BehaviorTree:setRoot
-- Assign the top-level composite as the tree root.
guard_bt:setRoot(patrol_and_scan)
print("guard BT root set to parallel(patrol + scan)")

-- ---- Stub: BehaviorTree:getLastStatus -------------------------------------
--@api-stub: BehaviorTree:getLastStatus
-- After update, check if the tree returned success, failure, or running.
local status = guard_bt:getLastStatus()
print("guard BT last status: " .. tostring(status))

-- ---- Stub: BehaviorTree:getDebugState -------------------------------------
--@api-stub: BehaviorTree:getDebugState
-- Get a snapshot of which nodes are running/succeeded/failed for debug overlay.
local dbg = guard_bt:getDebugState()
if dbg then
    print("BT debug state available — " .. type(dbg) .. " with node states")
end

-- ---- Stub: BehaviorTree:type ----------------------------------------------
--@api-stub: BehaviorTree:type
-- ---- Stub: BehaviorTree:typeOf --------------------------------------------
--@api-stub: BehaviorTree:typeOf
print("BT type: " .. tostring(guard_bt:type()))
print("BT typeOf: " .. tostring(guard_bt:typeOf("BehaviorTree")))

-- =============================================================================
-- Steering Behaviours — crowd movement
-- =============================================================================

-- ---- Stub: lurek.ai.newSteeringManager ------------------------------------
--@api-stub: lurek.ai.newSteeringManager
-- The steering manager combines multiple steering behaviours (seek, flee,
-- wander, separation) into a single velocity vector per frame.
local steer_mgr = lurek.ai.newSteeringManager()
print("steering manager created for crowd NPCs")

-- ---- Stub: SteeringManager:getBehaviorCount -------------------------------
--@api-stub: SteeringManager:getBehaviorCount
local bcount = steer_mgr:getBehaviorCount()
print("active steering behaviours: " .. tostring(bcount))

-- ---- Stub: SteeringManager:setCombineMode ---------------------------------
--@api-stub: SteeringManager:setCombineMode
-- "weighted_average" blends all forces; "priority" uses the highest-priority
-- behaviour that returns a non-zero force.
steer_mgr:setCombineMode("weighted_average")
print("steering combine mode: weighted_average (smooth crowd flow)")

-- ---- Stub: SteeringManager:getCombineMode ---------------------------------
--@api-stub: SteeringManager:getCombineMode
print("current combine mode: " .. tostring(steer_mgr:getCombineMode()))

-- ---- Stub: SteeringManager:getLastSteering --------------------------------
--@api-stub: SteeringManager:getLastSteering
-- After computing, read the resulting steering force vector.
local sx, sy = steer_mgr:getLastSteering()
print("last steering vector: (" .. tostring(sx) .. ", " .. tostring(sy) .. ")")

-- ---- Stub: SteeringManager:setSpatialHashCellSize -------------------------
--@api-stub: SteeringManager:setSpatialHashCellSize
-- Tune the spatial hash cell size for neighbour queries.
-- Smaller cells = more precise but more overhead. Match to agent density.
steer_mgr:setSpatialHashCellSize(64.0)
print("spatial hash cell size: 64px (good for ~20 agents in 1024x768)")

-- ---- Stub: SteeringManager:enableSpatialHash -----------------------------
--@api-stub: SteeringManager:enableSpatialHash
-- Enable spatial hashing for O(1) neighbour lookups when you have many agents.
steer_mgr:enableSpatialHash(true)
print("spatial hash enabled — separation/avoidance queries accelerated")

-- ---- Stub: SteeringManager:type -------------------------------------------
--@api-stub: SteeringManager:type
-- ---- Stub: SteeringManager:typeOf -----------------------------------------
--@api-stub: SteeringManager:typeOf
print("steering mgr type: " .. tostring(steer_mgr:type()))
print("steering mgr typeOf: " .. tostring(steer_mgr:typeOf("SteeringManager")))

-- =============================================================================
-- Context Steering — obstacle avoidance for the wolf
-- =============================================================================

-- ---- Stub: lurek.ai.newContextSteering ------------------------------------
--@api-stub: lurek.ai.newContextSteering
-- Context steering uses interest/danger maps over directional slots to produce
-- smooth avoidance behaviour. Better than basic steering for dense environments.
local ctx_steer = lurek.ai.newContextSteering()
print("context steering created for wolf navigation")

-- ---- Stub: ContextSteering:addSeekTarget ----------------------------------
--@api-stub: ContextSteering:addSeekTarget
-- The wolf wants to approach the player's campfire at (400, 300).
ctx_steer:addSeekTarget(400, 300, 1.0)
print("wolf seek target: campfire at (400, 300), weight 1.0")

-- ---- Stub: ContextSteering:addWander --------------------------------------
--@api-stub: ContextSteering:addWander
-- Add a small wander impulse so the wolf doesn't beeline perfectly straight.
ctx_steer:addWander(0.3)
print("wolf wander added (weight 0.3) for natural-looking path")

-- ---- Stub: ContextSteering:addAvoidPoint ----------------------------------
--@api-stub: ContextSteering:addAvoidPoint
-- The wolf avoids the guard's torch at (120, 210) within 80-unit radius.
ctx_steer:addAvoidPoint(120, 210, 80.0, 2.0)
print("wolf avoids guard torch at (120, 210) radius=80, danger=2.0")

-- ---- Stub: ContextSteering:addAvoidBounds ---------------------------------
--@api-stub: ContextSteering:addAvoidBounds
-- Keep the wolf inside the forest boundary (0,0)-(600,500).
ctx_steer:addAvoidBounds(0, 0, 600, 500, 1.5)
print("wolf constrained to forest bounds (0,0)-(600,500)")

-- ---- Stub: ContextSteering:clearBehaviors ---------------------------------
--@api-stub: ContextSteering:clearBehaviors
-- Clear all behaviours when the wolf switches from hunting to fleeing.
local before_clear = ctx_steer:slotCount()
ctx_steer:clearBehaviors()
print("context steering cleared: " .. before_clear .. " slots, behaviours reset")

-- Re-add for evaluation demo
ctx_steer:addSeekTarget(400, 300, 1.0)
ctx_steer:addAvoidPoint(120, 210, 80.0, 2.0)

-- ---- Stub: ContextSteering:evaluate ---------------------------------------
--@api-stub: ContextSteering:evaluate
-- Evaluate resolves the interest/danger maps into a final direction and magnitude.
local dir_x, dir_y = ctx_steer:evaluate()
print("wolf resolved direction: (" .. string.format("%.2f", dir_x) .. ", " .. string.format("%.2f", dir_y) .. ")")

-- ---- Stub: ContextSteering:chosenMagnitude --------------------------------
--@api-stub: ContextSteering:chosenMagnitude
-- Magnitude indicates confidence — high means a clear path, low means squeezed.
local mag = ctx_steer:chosenMagnitude()
print("wolf steering magnitude: " .. string.format("%.2f", mag))
if mag < 0.3 then
    print("  wolf is trapped — all directions blocked!")
end

-- ---- Stub: ContextSteering:slotCount --------------------------------------
--@api-stub: ContextSteering:slotCount
-- Number of directional slots in the context map (typically 8 or 16).
local slots = ctx_steer:slotCount()
print("context steering resolution: " .. tostring(slots) .. " directional slots")

-- =============================================================================
-- Q-Learning — adaptive enemy behaviour
-- =============================================================================

-- ---- Stub: lurek.ai.newQLearner -------------------------------------------
--@api-stub: lurek.ai.newQLearner
-- Train a wolf to choose between "stalk", "pounce", "howl", "flee" based on
-- distance and health states. The Q-table updates after each encounter.
local wolf_ql = lurek.ai.newQLearner({
    states = {"far_healthy", "far_wounded", "close_healthy", "close_wounded"},
    actions = {"stalk", "pounce", "howl", "flee"},
    learning_rate = 0.1,
    discount_factor = 0.95,
    exploration_rate = 0.3
})
print("wolf Q-learner: 4 states x 4 actions, epsilon=0.3")

-- ---- Stub: QLearner:chooseAction ------------------------------------------
--@api-stub: QLearner:chooseAction
-- Choose an action with epsilon-greedy exploration. Early in training this
-- will pick random actions; later it exploits learned Q-values.
local action1 = wolf_ql:chooseAction("far_healthy")
print("wolf chose action in 'far_healthy' state: " .. tostring(action1))

-- ---- Stub: QLearner:bestAction --------------------------------------------
--@api-stub: QLearner:bestAction
-- Pure exploitation: always pick the highest Q-value action (no exploration).
-- Use this for the final deployed AI or to display "optimal" play.
local best = wolf_ql:bestAction("close_wounded")
print("best action for 'close_wounded': " .. tostring(best))

-- ---- Stub: QLearner:getQValue ---------------------------------------------
--@api-stub: QLearner:getQValue
-- Inspect specific Q-values for balancing or debug display.
local q_val = wolf_ql:getQValue("close_healthy", "pounce")
print("Q(close_healthy, pounce) = " .. string.format("%.3f", q_val))

-- ---- Stub: QLearner:endEpisode --------------------------------------------
--@api-stub: QLearner:endEpisode
-- Call after each wolf encounter ends. The reward updates the Q-table.
-- Positive rewards for successful hunts, negative for getting wounded.
wolf_ql:endEpisode(1.0)  -- wolf caught prey: +1 reward
print("episode ended with reward +1.0 (successful hunt)")

-- ---- Stub: QLearner:getEpisodeCount ---------------------------------------
--@api-stub: QLearner:getEpisodeCount
local episodes = wolf_ql:getEpisodeCount()
print("total training episodes: " .. tostring(episodes))

-- ---- Stub: QLearner:getStateCount -----------------------------------------
--@api-stub: QLearner:getStateCount
print("Q-learner state count: " .. tostring(wolf_ql:getStateCount()))

-- ---- Stub: QLearner:getActionCount ----------------------------------------
--@api-stub: QLearner:getActionCount
print("Q-learner action count: " .. tostring(wolf_ql:getActionCount()))

-- ---- Stub: QLearner:setLearningRate ---------------------------------------
--@api-stub: QLearner:setLearningRate
-- Lower the learning rate as training progresses for more stable convergence.
wolf_ql:setLearningRate(0.05)
print("learning rate reduced to 0.05 (late-training stabilisation)")

-- ---- Stub: QLearner:getLearningRate ---------------------------------------
--@api-stub: QLearner:getLearningRate
print("current learning rate: " .. tostring(wolf_ql:getLearningRate()))

-- ---- Stub: QLearner:setDiscountFactor -------------------------------------
--@api-stub: QLearner:setDiscountFactor
-- Higher discount = more weight on future rewards. Good for patient strategies.
wolf_ql:setDiscountFactor(0.99)
print("discount factor: 0.99 (wolf values long-term ambush payoff)")

-- ---- Stub: QLearner:getDiscountFactor -------------------------------------
--@api-stub: QLearner:getDiscountFactor
print("discount factor: " .. tostring(wolf_ql:getDiscountFactor()))

-- ---- Stub: QLearner:setExplorationRate ------------------------------------
--@api-stub: QLearner:setExplorationRate
-- Reduce exploration as the wolf learns — fewer random actions over time.
wolf_ql:setExplorationRate(0.1)
print("exploration rate: 0.1 (mostly exploiting learned strategy)")

-- ---- Stub: QLearner:getExplorationRate ------------------------------------
--@api-stub: QLearner:getExplorationRate
print("exploration rate: " .. tostring(wolf_ql:getExplorationRate()))

-- ---- Stub: QLearner:setExplorationDecay -----------------------------------
--@api-stub: QLearner:setExplorationDecay
-- Automatic decay: multiply epsilon by this factor after each episode.
wolf_ql:setExplorationDecay(0.995)
print("exploration decay: 0.995 per episode (gradual convergence)")

-- ---- Stub: QLearner:getExplorationDecay -----------------------------------
--@api-stub: QLearner:getExplorationDecay
print("exploration decay: " .. tostring(wolf_ql:getExplorationDecay()))

-- ---- Stub: QLearner:serialize ---------------------------------------------
--@api-stub: QLearner:serialize
-- Save the trained Q-table to persist learned behaviour across game sessions.
local q_data = wolf_ql:serialize()
print("Q-table serialised: " .. tostring(#q_data) .. " bytes")

-- ---- Stub: QLearner:deserialize -------------------------------------------
--@api-stub: QLearner:deserialize
-- Restore a previously trained Q-table from a save file.
wolf_ql:deserialize(q_data)
print("Q-table restored from saved data — wolf remembers past encounters")

-- ---- Stub: QLearner:type --------------------------------------------------
--@api-stub: QLearner:type
-- ---- Stub: QLearner:typeOf ------------------------------------------------
--@api-stub: QLearner:typeOf
print("Q-learner type: " .. tostring(wolf_ql:type()))
print("Q-learner typeOf: " .. tostring(wolf_ql:typeOf("QLearner")))

-- =============================================================================
-- Utility AI — NPC decision making
-- =============================================================================

-- ---- Stub: lurek.ai.newUtilityAI ------------------------------------------
--@api-stub: lurek.ai.newUtilityAI
-- Utility AI scores candidate actions and picks the highest-scoring one.
-- Use for NPCs with many possible activities that depend on context.
local villager_util = lurek.ai.newUtilityAI({
    { name = "eat",   score = function() return 0.8 end },
    { name = "sleep", score = function() return 0.3 end },
    { name = "work",  score = function() return 0.6 end },
    { name = "chat",  score = function() return 0.4 end },
    { name = "shop",  score = function() return 0.5 end }
})
print("villager utility AI: 5 actions (eat, sleep, work, chat, shop)")

-- ---- Stub: UtilityAI:evaluate ---------------------------------------------
--@api-stub: UtilityAI:evaluate
-- Evaluate all candidates and pick the winner. Call each frame or on events.
local chosen = villager_util:evaluate()
print("villager chose: " .. tostring(chosen) .. " (highest utility score)")

-- ---- Stub: UtilityAI:getActionCount ---------------------------------------
--@api-stub: UtilityAI:getActionCount
print("utility AI candidate actions: " .. tostring(villager_util:getActionCount()))

-- ---- Stub: UtilityAI:getLastAction ----------------------------------------
--@api-stub: UtilityAI:getLastAction
-- Check what the NPC decided last frame for animation or dialog branching.
local last = villager_util:getLastAction()
print("last action chosen: " .. tostring(last))

-- ---- Stub: UtilityAI:type -------------------------------------------------
--@api-stub: UtilityAI:type
-- ---- Stub: UtilityAI:typeOf -----------------------------------------------
--@api-stub: UtilityAI:typeOf
print("utility AI type: " .. tostring(villager_util:type()))
print("utility AI typeOf: " .. tostring(villager_util:typeOf("UtilityAI")))

-- =============================================================================
-- GOAP Planner — quest-giving NPC
-- =============================================================================

-- ---- Stub: lurek.ai.newGOAPPlanner ----------------------------------------
--@api-stub: lurek.ai.newGOAPPlanner
-- Goal-Oriented Action Planning: the quest NPC plans a sequence of actions
-- to achieve a goal state. The planner searches backward from the goal.
local goap = lurek.ai.newGOAPPlanner({
    actions = {
        { name = "gather_herbs", preconditions = {}, effects = {has_herbs = true}, cost = 2 },
        { name = "brew_potion",  preconditions = {has_herbs = true}, effects = {has_potion = true}, cost = 3 },
        { name = "heal_patient", preconditions = {has_potion = true}, effects = {patient_healed = true}, cost = 1 },
        { name = "buy_herbs",    preconditions = {}, effects = {has_herbs = true}, cost = 5 }
    },
    goals = {
        { name = "cure_plague", state = {patient_healed = true}, priority = 10 }
    }
})
print("GOAP planner: 4 actions, 1 goal (cure_plague)")
print("  cheapest path: gather_herbs(2) -> brew_potion(3) -> heal_patient(1) = cost 6")
print("  alternative: buy_herbs(5) -> brew_potion(3) -> heal_patient(1) = cost 9")

-- ---- Stub: GOAPPlanner:getActionCount -------------------------------------
--@api-stub: GOAPPlanner:getActionCount
print("GOAP actions available: " .. tostring(goap:getActionCount()))

-- ---- Stub: GOAPPlanner:getGoalCount ---------------------------------------
--@api-stub: GOAPPlanner:getGoalCount
print("GOAP goals defined: " .. tostring(goap:getGoalCount()))

-- ---- Stub: GOAPPlanner:getMaxIterations -----------------------------------
--@api-stub: GOAPPlanner:getMaxIterations
-- Cap search iterations to prevent frame spikes on complex goal networks.
local max_iter = goap:getMaxIterations()
print("GOAP max iterations: " .. tostring(max_iter))

-- ---- Stub: GOAPPlanner:setMaxIterations -----------------------------------
--@api-stub: GOAPPlanner:setMaxIterations
goap:setMaxIterations(500)
print("GOAP max iterations set to 500 (complex quest chains)")

-- ---- Stub: GOAPPlanner:type -----------------------------------------------
--@api-stub: GOAPPlanner:type
-- ---- Stub: GOAPPlanner:typeOf ---------------------------------------------
--@api-stub: GOAPPlanner:typeOf
print("GOAP type: " .. tostring(goap:type()))
print("GOAP typeOf: " .. tostring(goap:typeOf("GOAPPlanner")))

-- =============================================================================
-- Influence Map — territory control
-- =============================================================================

-- ---- Stub: lurek.ai.newInfluenceMap ---------------------------------------
--@api-stub: lurek.ai.newInfluenceMap
-- Influence maps track area control. Each cell in the grid accumulates influence
-- from nearby agents. Use for territory display, tactical decisions, or fog of war.
local inf_map = lurek.ai.newInfluenceMap(32, 24, 32.0)  -- 32x24 grid, 32px cells
print("influence map: 32x24 grid, 32px cells (covers 1024x768 world)")

-- ---- Stub: InfluenceMap:addLayer ------------------------------------------
--@api-stub: InfluenceMap:addLayer
-- Separate layers for different factions or influence types.
inf_map:addLayer("royal_guard", 0.0)
inf_map:addLayer("wolf_pack", 0.0)
inf_map:addLayer("merchant_zone", 0.0)
print("influence layers: royal_guard, wolf_pack, merchant_zone")

-- ---- Stub: InfluenceMap:hasLayer ------------------------------------------
--@api-stub: InfluenceMap:hasLayer
print("has 'royal_guard' layer: " .. tostring(inf_map:hasLayer("royal_guard")))
print("has 'bandit' layer: " .. tostring(inf_map:hasLayer("bandit")))

-- ---- Stub: InfluenceMap:decay ---------------------------------------------
--@api-stub: InfluenceMap:decay
-- Decay all influence values each frame so stale positions fade out naturally.
-- Factor 0.95 means 5% decay per tick — influence lingers for ~60 frames.
inf_map:decay("royal_guard", 0.95)
inf_map:decay("wolf_pack", 0.90)
print("influence decayed: guard(0.95 retention), wolf(0.90 retention)")

-- ---- Stub: InfluenceMap:clearLayer ----------------------------------------
--@api-stub: InfluenceMap:clearLayer
-- Reset a single layer — use when a faction retreats or a zone is captured.
inf_map:clearLayer("wolf_pack")
print("wolf_pack influence cleared (wolves fled the area)")

-- ---- Stub: InfluenceMap:clearAll ------------------------------------------
--@api-stub: InfluenceMap:clearAll
-- Wipe all layers — use on level transitions or game reset.
inf_map:clearAll()
print("all influence layers cleared (new level loaded)")

-- Re-add layers for further demos
inf_map:addLayer("royal_guard", 0.0)
inf_map:addLayer("wolf_pack", 0.0)

-- ---- Stub: InfluenceMap:getMaxPosition ------------------------------------
--@api-stub: InfluenceMap:getMaxPosition
-- Find the hotspot with highest influence — e.g. where guards are concentrated.
local max_x, max_y = inf_map:getMaxPosition("royal_guard")
print("guard concentration peak at: (" .. tostring(max_x) .. ", " .. tostring(max_y) .. ")")

-- ---- Stub: InfluenceMap:getMinPosition ------------------------------------
--@api-stub: InfluenceMap:getMinPosition
-- Find the cold spot — least guarded area for sneaking or flanking.
local min_x, min_y = inf_map:getMinPosition("royal_guard")
print("guard blind spot at: (" .. tostring(min_x) .. ", " .. tostring(min_y) .. ")")
print("  sneak through here to avoid detection!")

-- ---- Stub: InfluenceMap:getWidth ------------------------------------------
--@api-stub: InfluenceMap:getWidth
print("influence map width: " .. tostring(inf_map:getWidth()) .. " cells")

-- ---- Stub: InfluenceMap:getHeight -----------------------------------------
--@api-stub: InfluenceMap:getHeight
print("influence map height: " .. tostring(inf_map:getHeight()) .. " cells")

-- ---- Stub: InfluenceMap:getCellSize ---------------------------------------
--@api-stub: InfluenceMap:getCellSize
print("cell size: " .. tostring(inf_map:getCellSize()) .. "px")

-- ---- Stub: InfluenceMap:type ----------------------------------------------
--@api-stub: InfluenceMap:type
-- ---- Stub: InfluenceMap:typeOf --------------------------------------------
--@api-stub: InfluenceMap:typeOf
print("influence map type: " .. tostring(inf_map:type()))
print("influence map typeOf: " .. tostring(inf_map:typeOf("InfluenceMap")))

-- =============================================================================
-- Squad — coordinated patrol group
-- =============================================================================

-- ---- Stub: lurek.ai.newSquad ----------------------------------------------
--@api-stub: lurek.ai.newSquad
-- Squads group agents under a leader with a formation. Use for coordinated
-- patrols, military units, or wolf packs that move as a group.
local patrol_squad = lurek.ai.newSquad("gatehouse_patrol", {
    formation = "wedge",
    spacing = 40.0
})
print("squad 'gatehouse_patrol' created: wedge formation, 40px spacing")

-- ---- Stub: Squad:getName --------------------------------------------------
--@api-stub: Squad:getName
print("squad name: " .. patrol_squad:getName())

-- ---- Stub: Squad:addMember ------------------------------------------------
--@api-stub: Squad:addMember
-- Add agents to the squad. The first added becomes the default leader.
patrol_squad:addMember(guard)
patrol_squad:addMember(scout)
print("squad members: guard_captain + scout_drone")

-- ---- Stub: Squad:removeMember ---------------------------------------------
--@api-stub: Squad:removeMember
-- Remove an agent from the squad (e.g. killed, reassigned, deserted).
patrol_squad:removeMember(scout)
print("scout removed from squad (reassigned to tower duty)")

-- Re-add for further demos
patrol_squad:addMember(scout)

-- ---- Stub: Squad:getMemberCount -------------------------------------------
--@api-stub: Squad:getMemberCount
local member_count = patrol_squad:getMemberCount()
print("squad size: " .. tostring(member_count) .. " members")

-- ---- Stub: Squad:getMembers -----------------------------------------------
--@api-stub: Squad:getMembers
-- Iterate members for AoE effects, group healing, or formation updates.
local members = patrol_squad:getMembers()
print("squad roster:")
for i, m in ipairs(members) do
    local mx, my = m:getPosition()
    print("  [" .. i .. "] " .. m:getName() .. " at (" .. mx .. ", " .. my .. ")")
end

-- ---- Stub: Squad:setLeader ------------------------------------------------
--@api-stub: Squad:setLeader
-- The leader determines formation anchor point. Promote the guard to lead.
patrol_squad:setLeader(guard)
print("guard_captain promoted to squad leader")

-- ---- Stub: Squad:getLeader ------------------------------------------------
--@api-stub: Squad:getLeader
local leader = patrol_squad:getLeader()
print("squad leader: " .. tostring(leader and leader:getName()))

-- ---- Stub: Squad:getFormation ---------------------------------------------
--@api-stub: Squad:getFormation
print("formation type: " .. tostring(patrol_squad:getFormation()))

-- ---- Stub: Squad:getFormationSpacing --------------------------------------
--@api-stub: Squad:getFormationSpacing
print("formation spacing: " .. tostring(patrol_squad:getFormationSpacing()) .. "px")

-- ---- Stub: Squad:getBlackboard --------------------------------------------
--@api-stub: Squad:getBlackboard
-- Squad blackboard shares intel between all members — spotted enemies,
-- rally points, ammo caches.
local squad_bb = patrol_squad:getBlackboard()
squad_bb:setString("rally_point", "gatehouse_courtyard")
squad_bb:setNumber("enemies_spotted", 0)
print("squad blackboard: rally_point=gatehouse_courtyard, enemies_spotted=0")

-- ---- Stub: Squad:type -----------------------------------------------------
--@api-stub: Squad:type
-- ---- Stub: Squad:typeOf ---------------------------------------------------
--@api-stub: Squad:typeOf
print("squad type: " .. tostring(patrol_squad:type()))
print("squad typeOf: " .. tostring(patrol_squad:typeOf("Squad")))

-- =============================================================================
-- Command Queue — issuing orders to agents
-- =============================================================================

-- ---- Stub: lurek.ai.newCommandQueue ---------------------------------------
--@api-stub: lurek.ai.newCommandQueue
-- Command queues let you issue a series of orders (move, attack, wait, interact)
-- that the agent executes in sequence. RTS-style "shift-click" waypoints.
local guard_cmds = lurek.ai.newCommandQueue()
print("guard command queue created")

-- Queue up a patrol route: move to waypoints, then loop
guard_cmds:clear() -- ensure empty start

-- ---- Stub: CommandQueue:getCount ------------------------------------------
--@api-stub: CommandQueue:getCount
local cmd_count = guard_cmds:getCount()
print("queued commands: " .. tostring(cmd_count))

-- ---- Stub: CommandQueue:isEmpty -------------------------------------------
--@api-stub: CommandQueue:isEmpty
if guard_cmds:isEmpty() then
    print("command queue empty — guard is idle, needs orders")
end

-- ---- Stub: CommandQueue:getCurrentType ------------------------------------
--@api-stub: CommandQueue:getCurrentType
-- What kind of command is the agent currently executing?
local cmd_type = guard_cmds:getCurrentType()
print("current command type: " .. tostring(cmd_type))

-- ---- Stub: CommandQueue:getCurrentTarget ----------------------------------
--@api-stub: CommandQueue:getCurrentTarget
-- Get the target of the current command (position, entity ID, etc.).
local cmd_target = guard_cmds:getCurrentTarget()
print("current command target: " .. tostring(cmd_target))

-- ---- Stub: CommandQueue:cancelCurrent -------------------------------------
--@api-stub: CommandQueue:cancelCurrent
-- Cancel the current command and move to the next in queue.
-- Use when a higher-priority event interrupts (e.g. alarm triggered).
guard_cmds:cancelCurrent()
print("current command cancelled — guard responds to alarm")

-- ---- Stub: CommandQueue:clear ---------------------------------------------
--@api-stub: CommandQueue:clear
-- Wipe all queued commands. Use during cutscenes or emergency state changes.
guard_cmds:clear()
print("all commands cleared — guard stands at attention")

-- ---- Stub: CommandQueue:type ----------------------------------------------
--@api-stub: CommandQueue:type
-- ---- Stub: CommandQueue:typeOf --------------------------------------------
--@api-stub: CommandQueue:typeOf
print("command queue type: " .. tostring(guard_cmds:type()))
print("command queue typeOf: " .. tostring(guard_cmds:typeOf("CommandQueue")))

-- =============================================================================
-- Trait Profile — NPC personality system
-- =============================================================================

-- ---- Stub: lurek.ai.newTraitProfile ---------------------------------------
--@api-stub: lurek.ai.newTraitProfile
-- Trait profiles define NPC personality: courage, greed, patience, aggression.
-- Base values are set at creation; modifiers from buffs/debuffs stack on top.
local guard_traits = lurek.ai.newTraitProfile()
print("guard trait profile created")

-- ---- Stub: TraitProfile:set -----------------------------------------------
--@api-stub: TraitProfile:set
-- Set base trait values. Scale 0.0 to 1.0. These are the NPC's natural tendencies.
guard_traits:set("courage", 0.8)
guard_traits:set("loyalty", 0.9)
guard_traits:set("patience", 0.5)
guard_traits:set("aggression", 0.6)
guard_traits:set("greed", 0.2)
print("guard base traits: courage=0.8, loyalty=0.9, patience=0.5")

-- ---- Stub: TraitProfile:get -----------------------------------------------
--@api-stub: TraitProfile:get
-- Get the effective trait value (base + all active modifiers).
local courage = guard_traits:get("courage")
print("guard effective courage: " .. string.format("%.2f", courage))

-- ---- Stub: TraitProfile:getBase -------------------------------------------
--@api-stub: TraitProfile:getBase
-- Get only the base value, ignoring modifiers.
local base_courage = guard_traits:getBase("courage")
print("guard base courage: " .. string.format("%.2f", base_courage))

-- ---- Stub: TraitProfile:addModifier ---------------------------------------
--@api-stub: TraitProfile:addModifier
-- Add temporary modifiers from game events: potions, fear effects, injuries.
guard_traits:addModifier("courage", "fear_spell", -0.3)
guard_traits:addModifier("aggression", "battle_rage", 0.2)
print("modifiers applied: fear_spell (courage -0.3), battle_rage (aggression +0.2)")
print("  effective courage now: " .. string.format("%.2f", guard_traits:get("courage")))

-- ---- Stub: TraitProfile:removeModifiers -----------------------------------
--@api-stub: TraitProfile:removeModifiers
-- Remove all modifiers for a trait when the effect expires.
guard_traits:removeModifiers("courage")
print("fear_spell expired — courage modifiers removed")
print("  courage restored to: " .. string.format("%.2f", guard_traits:get("courage")))

-- ---- Stub: TraitProfile:update --------------------------------------------
--@api-stub: TraitProfile:update
-- Tick trait modifiers (decay, expiration, etc.).
guard_traits:update(0.016)
print("trait profile updated (16ms tick)")

-- ---- Stub: TraitProfile:has -----------------------------------------------
--@api-stub: TraitProfile:has
print("has 'courage' trait: " .. tostring(guard_traits:has("courage")))
print("has 'magic_affinity' trait: " .. tostring(guard_traits:has("magic_affinity")))

-- ---- Stub: TraitProfile:traitCount ----------------------------------------
--@api-stub: TraitProfile:traitCount
print("total traits defined: " .. tostring(guard_traits:traitCount()))

-- ---- Stub: TraitProfile:archetype -----------------------------------------
--@api-stub: TraitProfile:archetype
-- Returns a string describing the dominant personality archetype.
local arch = guard_traits:archetype()
print("guard archetype: " .. tostring(arch))

-- =============================================================================
-- Stimulus World — sensory perception for NPCs
-- =============================================================================

-- ---- Stub: lurek.ai.newStimulusWorld --------------------------------------
--@api-stub: lurek.ai.newStimulusWorld
-- The stimulus world tracks visual and auditory signals that NPCs can detect.
-- Each stimulus has a position, intensity, and decay rate.
local stimulus = lurek.ai.newStimulusWorld()
print("stimulus world created for NPC perception")

-- ---- Stub: StimulusWorld:addVisual ----------------------------------------
--@api-stub: StimulusWorld:addVisual
-- A visual stimulus: player's torch flickering at (200, 150) — visible within 120 units.
stimulus:addVisual(200, 150, 0.8, 120.0)
print("visual stimulus: torch light at (200, 150), intensity=0.8, range=120")

-- ---- Stub: StimulusWorld:addAuditory --------------------------------------
--@api-stub: StimulusWorld:addAuditory
-- An auditory stimulus: player's footsteps at (250, 180) — audible within 80 units.
stimulus:addAuditory(250, 180, 0.5, 80.0)
print("auditory stimulus: footsteps at (250, 180), intensity=0.5, range=80")

-- ---- Stub: StimulusWorld:remove -------------------------------------------
--@api-stub: StimulusWorld:remove
-- Remove a specific stimulus (e.g. torch extinguished, player stopped moving).
stimulus:remove(0)
print("stimulus #0 removed (torch extinguished)")

-- ---- Stub: StimulusWorld:update -------------------------------------------
--@api-stub: StimulusWorld:update
-- Tick all stimuli: decay intensity, remove expired ones.
stimulus:update(0.016)
print("stimulus world updated — signals decaying naturally")

-- ---- Stub: StimulusWorld:count --------------------------------------------
--@api-stub: StimulusWorld:count
print("active stimuli: " .. tostring(stimulus:count()))

-- ---- Stub: StimulusWorld:clear --------------------------------------------
--@api-stub: StimulusWorld:clear
stimulus:clear()
print("all stimuli cleared (scene transition)")

-- =============================================================================
-- Need System — survival mechanics
-- =============================================================================

-- ---- Stub: lurek.ai.newNeedSystem -----------------------------------------
--@api-stub: lurek.ai.newNeedSystem
-- Needs-based AI: villagers have hunger, tiredness, social needs that
-- drive behaviour. The most urgent need determines the next action.
local needs = lurek.ai.newNeedSystem()
print("need system created for villager survival AI")

-- ---- Stub: NeedSystem:addNeed ---------------------------------------------
--@api-stub: NeedSystem:addNeed
-- Define needs with initial value, decay rate per second, and urgency threshold.
needs:addNeed("hunger",     { value = 0.3, decay = 0.02, threshold = 0.7 })
needs:addNeed("tiredness",  { value = 0.5, decay = 0.01, threshold = 0.8 })
needs:addNeed("social",     { value = 0.1, decay = 0.005, threshold = 0.6 })
needs:addNeed("safety",     { value = 0.0, decay = 0.03, threshold = 0.5 })
print("needs: hunger(0.3), tiredness(0.5), social(0.1), safety(0.0)")
print("  hunger decays at 0.02/s — villager gets hungry every ~35s")

-- ---- Stub: NeedSystem:update ----------------------------------------------
--@api-stub: NeedSystem:update
-- Tick needs forward. All values increase by their decay rate * dt.
needs:update(10.0)  -- simulate 10 seconds passing
print("needs updated after 10s of game time")

-- ---- Stub: NeedSystem:mostUrgent ------------------------------------------
--@api-stub: NeedSystem:mostUrgent
-- Find the need closest to or above its urgency threshold.
local urgent = needs:mostUrgent()
print("most urgent need: " .. tostring(urgent))

-- ---- Stub: NeedSystem:satisfy ---------------------------------------------
--@api-stub: NeedSystem:satisfy
-- Satisfy a need (eating reduces hunger, sleeping reduces tiredness).
needs:satisfy("hunger", 0.5)
print("villager ate bread: hunger reduced by 0.5")

-- ---- Stub: NeedSystem:valueOf ---------------------------------------------
--@api-stub: NeedSystem:valueOf
-- Read current value for HUD bars or AI decision functions.
local hunger_val = needs:valueOf("hunger")
local tired_val = needs:valueOf("tiredness")
print("hunger: " .. string.format("%.2f", hunger_val) .. ", tiredness: " .. string.format("%.2f", tired_val))

-- =============================================================================
-- AI Director — dynamic difficulty
-- =============================================================================

-- ---- Stub: lurek.ai.newAIDirector -----------------------------------------
--@api-stub: lurek.ai.newAIDirector
-- The AI Director monitors player performance and adjusts difficulty in
-- real-time. Inspired by Left 4 Dead's director: controls spawn rates,
-- loot drops, and ambient intensity based on tension curves.
local director = lurek.ai.newAIDirector({
    tension_min = 0.0,
    tension_max = 1.0,
    build_rate = 0.05,
    relax_rate = 0.03,
    peak_duration = 15.0
})
print("AI Director created: tension range [0, 1], build=0.05/s, relax=0.03/s")

-- ---- Stub: AIDirector:pushEvent -------------------------------------------
--@api-stub: AIDirector:pushEvent
-- Feed player events into the director. Kills increase tension; deaths reset it.
director:pushEvent("player_kill", 0.15)
director:pushEvent("player_kill", 0.15)
director:pushEvent("player_damage_taken", 0.08)
print("events pushed: 2 kills (+0.30), 1 hit taken (+0.08)")

-- ---- Stub: AIDirector:update ----------------------------------------------
--@api-stub: AIDirector:update
-- Tick the director. It smooths tension over time using build/relax rates.
director:update(1.0)  -- 1 second of game time
print("director updated — tension curve adjusted")

-- ---- Stub: AIDirector:tension ---------------------------------------------
--@api-stub: AIDirector:tension
local tension = director:tension()
print("current tension: " .. string.format("%.2f", tension))

-- ---- Stub: AIDirector:phase -----------------------------------------------
--@api-stub: AIDirector:phase
-- Phases: "build" (tension rising), "peak" (holding high tension), "relax" (cooling down).
local phase = director:phase()
print("director phase: " .. tostring(phase))

-- ---- Stub: AIDirector:spawnRateFactor -------------------------------------
--@api-stub: AIDirector:spawnRateFactor
-- Use this multiplier on your spawn timer to increase/decrease enemy density.
local spawn_factor = director:spawnRateFactor()
print("spawn rate factor: " .. string.format("%.2f", spawn_factor) .. "x")

-- ---- Stub: AIDirector:lootFactor ------------------------------------------
--@api-stub: AIDirector:lootFactor
-- Loot factor: higher during relax phases to reward surviving a peak.
local loot = director:lootFactor()
print("loot factor: " .. string.format("%.2f", loot) .. "x")

-- ---- Stub: AIDirector:ambientIntensity ------------------------------------
--@api-stub: AIDirector:ambientIntensity
-- Controls ambient effects: music intensity, fog density, lighting mood.
local ambient = director:ambientIntensity()
print("ambient intensity: " .. string.format("%.2f", ambient))

-- ---- Stub: AIDirector:setTension ------------------------------------------
--@api-stub: AIDirector:setTension
-- Manually override tension for scripted sequences (boss intro, cutscene).
director:setTension(0.9)
print("tension manually set to 0.9 (boss fight imminent)")

-- ---- Stub: AIDirector:reset -----------------------------------------------
--@api-stub: AIDirector:reset
-- Reset the director for a new level or after a major story event.
director:reset()
print("AI director reset — tension curve starts fresh")

-- =============================================================================
-- AI LOD — level of detail for distant agents
-- =============================================================================

-- ---- Stub: lurek.ai.newAILod ----------------------------------------------
--@api-stub: lurek.ai.newAILod
-- AI LOD reduces computation for distant or off-screen agents.
-- Close agents get full BT + steering; distant ones get simplified updates.
local ai_lod = lurek.ai.newAILod({
    tiers = {
        { name = "full",    distance = 200,  update_hz = 60 },
        { name = "reduced", distance = 500,  update_hz = 10 },
        { name = "minimal", distance = 1000, update_hz = 2 },
        { name = "frozen",  distance = 2000, update_hz = 0 }
    }
})
print("AI LOD: 4 tiers (full/reduced/minimal/frozen)")
print("  full: <200px, 60Hz | reduced: <500px, 10Hz | minimal: <1000px, 2Hz")

-- ---- Stub: AILod:tierFor --------------------------------------------------
--@api-stub: AILod:tierFor
-- Query which LOD tier an agent falls into based on distance to camera.
local tier = ai_lod:tierFor(150.0)   -- agent 150px from camera
print("agent at 150px: tier '" .. tostring(tier) .. "' (should be 'full')")
local far_tier = ai_lod:tierFor(800.0)
print("agent at 800px: tier '" .. tostring(far_tier) .. "' (should be 'minimal')")

-- ---- Stub: AILod:shouldUpdate ---------------------------------------------
--@api-stub: AILod:shouldUpdate
-- Frame-rate check: should this agent update this frame given its LOD tier?
local should = ai_lod:shouldUpdate(300.0)
print("agent at 300px should update this frame: " .. tostring(should))

-- ---- Stub: AILod:tierCount ------------------------------------------------
--@api-stub: AILod:tierCount
print("LOD tier count: " .. tostring(ai_lod:tierCount()))

-- ---- Stub: AILod:tierName -------------------------------------------------
--@api-stub: AILod:tierName
-- Get tier name by index for debug overlay display.
for i = 0, ai_lod:tierCount() - 1 do
    print("  tier[" .. i .. "] = " .. tostring(ai_lod:tierName(i)))
end

-- =============================================================================
-- HTN Domain — hierarchical task network for complex quests
-- =============================================================================

-- ---- Stub: lurek.ai.newHTNDomain ------------------------------------------
--@api-stub: lurek.ai.newHTNDomain
-- HTN planning decomposes high-level goals into primitive tasks.
-- Use for quest NPCs that need to plan multi-step sequences.
local htn = lurek.ai.newHTNDomain()
print("HTN domain created for quest NPC planning")

-- ---- Stub: HTNDomain:addPrimitive -----------------------------------------
--@api-stub: HTNDomain:addPrimitive
-- Primitive tasks are directly executable actions with preconditions and effects.
htn:addPrimitive("travel_to_mine", {
    preconditions = function(state) return state.has_pickaxe end,
    effects = function(state) state.at_mine = true end,
    cost = 3
})
htn:addPrimitive("mine_ore", {
    preconditions = function(state) return state.at_mine and state.has_pickaxe end,
    effects = function(state) state.has_ore = true end,
    cost = 5
})
htn:addPrimitive("smelt_ore", {
    preconditions = function(state) return state.has_ore end,
    effects = function(state) state.has_ingot = true; state.has_ore = false end,
    cost = 4
})
print("HTN primitives: travel_to_mine(3), mine_ore(5), smelt_ore(4)")

-- ---- Stub: HTNDomain:addCompound -----------------------------------------
--@api-stub: HTNDomain:addCompound
-- Compound tasks decompose into sequences of primitives or other compounds.
htn:addCompound("craft_weapon", {
    methods = {
        { precondition = function(state) return state.has_pickaxe end,
          subtasks = {"travel_to_mine", "mine_ore", "smelt_ore"} },
    }
})
print("HTN compound: craft_weapon -> [travel, mine, smelt]")

-- ---- Stub: HTNDomain:plan -------------------------------------------------
--@api-stub: HTNDomain:plan
-- Generate a plan from the current world state toward the goal.
local plan = htn:plan({ has_pickaxe = true, at_mine = false, has_ore = false })
if plan then
    print("HTN plan generated:")
    for i, step in ipairs(plan) do
        print("  step " .. i .. ": " .. tostring(step))
    end
end

-- ---- Stub: HTNDomain:taskCount --------------------------------------------
--@api-stub: HTNDomain:taskCount
print("HTN domain task count: " .. tostring(htn:taskCount()))

-- =============================================================================
-- MCTS Engine — tactical combat decisions
-- =============================================================================

-- ---- Stub: lurek.ai.newMCTSEngine ----------------------------------------
--@api-stub: lurek.ai.newMCTSEngine
-- Monte Carlo Tree Search for complex tactical decisions: which unit to attack,
-- where to position, when to use abilities. Runs thousands of simulated games.
local mcts = lurek.ai.newMCTSEngine({
    iterations = 1000,
    exploration = 1.41,
    max_depth = 20,
    time_limit_ms = 16  -- fit within one frame
})
print("MCTS engine: 1000 iterations, exploration=1.41, 16ms budget")
print("  useful for turn-based combat AI or complex decision points")

-- =============================================================================
-- Emotion Model — NPC moods
-- =============================================================================

-- ---- Stub: lurek.ai.newEmotionModel ---------------------------------------
--@api-stub: lurek.ai.newEmotionModel
-- Track NPC emotional state. Emotions influence dialogue choices, facial
-- animations, and willingness to cooperate or fight.
local guard_emotions = lurek.ai.newEmotionModel()
print("guard emotion model created")

-- ---- Stub: EmotionModel:add -----------------------------------------------
--@api-stub: EmotionModel:add
-- Register emotion channels with base intensity and decay rate.
guard_emotions:add("anger",     { base = 0.0, decay = 0.05 })
guard_emotions:add("fear",      { base = 0.0, decay = 0.03 })
guard_emotions:add("happiness", { base = 0.5, decay = 0.01 })
guard_emotions:add("suspicion", { base = 0.2, decay = 0.04 })
print("emotions: anger(0), fear(0), happiness(0.5), suspicion(0.2)")

-- ---- Stub: EmotionModel:trigger -------------------------------------------
--@api-stub: EmotionModel:trigger
-- Game events trigger emotional responses. Intensity stacks with existing levels.
guard_emotions:trigger("anger", 0.4)      -- player trespassed
guard_emotions:trigger("suspicion", 0.3)  -- heard strange noise
print("triggered: anger +0.4 (trespass), suspicion +0.3 (strange noise)")

-- ---- Stub: EmotionModel:get -----------------------------------------------
--@api-stub: EmotionModel:get
local anger = guard_emotions:get("anger")
local suspicion = guard_emotions:get("suspicion")
print("anger: " .. string.format("%.2f", anger) .. ", suspicion: " .. string.format("%.2f", suspicion))

-- ---- Stub: EmotionModel:dominant ------------------------------------------
--@api-stub: EmotionModel:dominant
-- Which emotion is strongest right now? Use for facial expression or voice tone.
local dom = guard_emotions:dominant()
print("dominant emotion: " .. tostring(dom))

-- ---- Stub: EmotionModel:isActive ------------------------------------------
--@api-stub: EmotionModel:isActive
-- Check if a specific emotion is above its activation threshold.
print("anger active: " .. tostring(guard_emotions:isActive("anger")))
print("fear active: " .. tostring(guard_emotions:isActive("fear")))

-- ---- Stub: EmotionModel:update --------------------------------------------
--@api-stub: EmotionModel:update
-- Decay all emotions over time. Anger fades, happiness lingers.
guard_emotions:update(5.0)  -- 5 seconds of game time
print("emotions after 5s decay:")
print("  anger: " .. string.format("%.2f", guard_emotions:get("anger")))
print("  suspicion: " .. string.format("%.2f", guard_emotions:get("suspicion")))

-- ---- Stub: EmotionModel:reset ---------------------------------------------
--@api-stub: EmotionModel:reset
-- Reset all emotions to base values (e.g. new day, scene change).
guard_emotions:reset()
print("guard emotions reset to baseline (new day)")

-- =============================================================================
-- ORCA Solver — crowd collision avoidance
-- =============================================================================

-- ---- Stub: lurek.ai.newORCASolver -----------------------------------------
--@api-stub: lurek.ai.newORCASolver
-- ORCA (Optimal Reciprocal Collision Avoidance) computes collision-free
-- velocities for crowds of agents. Each agent gets a safe velocity that
-- avoids all neighbours while staying close to its preferred direction.
local orca = lurek.ai.newORCASolver({
    time_horizon = 2.0,
    agent_radius = 10.0
})
print("ORCA solver: time_horizon=2s, agent_radius=10px")

-- ---- Stub: ORCASolver:addAgent --------------------------------------------
--@api-stub: ORCASolver:addAgent
-- Register agents with position and radius. Returns an agent index.
local orca_guard = orca:addAgent(100, 200, 12.0)    -- guard: larger radius (armoured)
local orca_villager = orca:addAgent(300, 400, 8.0)   -- villager: smaller
local orca_wolf = orca:addAgent(500, 100, 10.0)      -- wolf: medium
print("ORCA agents: guard(r=12), villager(r=8), wolf(r=10)")

-- ---- Stub: ORCASolver:setPreferredVelocity --------------------------------
--@api-stub: ORCASolver:setPreferredVelocity
-- Set where each agent wants to go. ORCA adjusts these to avoid collisions.
orca:setPreferredVelocity(orca_guard, 2.0, 0.0)      -- guard walks east
orca:setPreferredVelocity(orca_villager, -1.0, 0.5)   -- villager walks southwest
orca:setPreferredVelocity(orca_wolf, 0.0, 3.0)        -- wolf runs south
print("preferred velocities set for all ORCA agents")

-- ---- Stub: ORCASolver:setPosition -----------------------------------------
--@api-stub: ORCASolver:setPosition
-- Update agent positions each frame before computing safe velocities.
orca:setPosition(orca_guard, 105, 200)
orca:setPosition(orca_villager, 298, 402)
print("ORCA positions updated (one frame of movement)")

-- ---- Stub: ORCASolver:compute ---------------------------------------------
--@api-stub: ORCASolver:compute
-- Compute collision-free velocities for all agents simultaneously.
orca:compute()
print("ORCA computed — all agents have safe velocities")

-- ---- Stub: ORCASolver:getSafeVelocity -------------------------------------
--@api-stub: ORCASolver:getSafeVelocity
-- Read the adjusted velocity for each agent. Apply this instead of preferred.
local svx, svy = orca:getSafeVelocity(orca_guard)
print("guard safe velocity: (" .. string.format("%.2f", svx) .. ", " .. string.format("%.2f", svy) .. ")")
local wvx, wvy = orca:getSafeVelocity(orca_wolf)
print("wolf safe velocity: (" .. string.format("%.2f", wvx) .. ", " .. string.format("%.2f", wvy) .. ")")

-- ---- Stub: ORCASolver:agentCount ------------------------------------------
--@api-stub: ORCASolver:agentCount
print("ORCA agent count: " .. tostring(orca:agentCount()))

-- =============================================================================
-- Neural Net — difficulty tuning
-- =============================================================================

-- ---- Stub: lurek.ai.newNeuralNet ------------------------------------------
--@api-stub: lurek.ai.newNeuralNet
-- A simple feedforward neural network for real-time AI decisions.
-- Input: player stats -> Output: difficulty adjustments.
local nn = lurek.ai.newNeuralNet()
print("neural network created for difficulty prediction")

-- ---- Stub: NeuralNet:addLayer ---------------------------------------------
--@api-stub: NeuralNet:addLayer
-- Build the network layer by layer. Input(4) -> Hidden(8) -> Output(3).
-- Input features: player_level, kill_rate, death_rate, accuracy
-- Output: spawn_multiplier, damage_scale, loot_bonus
nn:addLayer(4, "input")
nn:addLayer(8, "relu")
nn:addLayer(3, "sigmoid")
print("network architecture: 4 -> 8(ReLU) -> 3(sigmoid)")

-- ---- Stub: NeuralNet:forward ----------------------------------------------
--@api-stub: NeuralNet:forward
-- Forward pass: feed player stats, get difficulty adjustments.
local player_stats = {15.0, 2.3, 0.5, 0.72}  -- level 15, 2.3 kills/min, 0.5 deaths/min, 72% accuracy
local output = nn:forward(player_stats)
if output then
    print("difficulty prediction:")
    print("  spawn multiplier: " .. string.format("%.3f", output[1]))
    print("  damage scale:     " .. string.format("%.3f", output[2]))
    print("  loot bonus:       " .. string.format("%.3f", output[3]))
end

-- ---- Stub: NeuralNet:setWeights -------------------------------------------
--@api-stub: NeuralNet:setWeights
-- Load pre-trained weights from a file or GA-evolved weights.
local weight_count = nn:paramCount()
local trained_weights = {}
for i = 1, weight_count do
    trained_weights[i] = math.random() * 2 - 1  -- random init for demo
end
nn:setWeights(trained_weights)
print("loaded " .. weight_count .. " weights into network")

-- ---- Stub: NeuralNet:getWeights -------------------------------------------
--@api-stub: NeuralNet:getWeights
-- Extract weights for saving, crossover in GA, or inspection.
local w = nn:getWeights()
print("extracted " .. #w .. " weights from network")
print("  first 3 weights: " .. string.format("%.3f, %.3f, %.3f", w[1], w[2], w[3]))

-- ---- Stub: NeuralNet:paramCount -------------------------------------------
--@api-stub: NeuralNet:paramCount
print("total trainable parameters: " .. tostring(nn:paramCount()))

-- ---- Stub: NeuralNet:layerCount -------------------------------------------
--@api-stub: NeuralNet:layerCount
print("network layers: " .. tostring(nn:layerCount()))

-- =============================================================================
-- Genetic Algorithm — procedural creature stats
-- =============================================================================

-- ---- Stub: lurek.ai.newGeneticAlgorithm -----------------------------------
--@api-stub: lurek.ai.newGeneticAlgorithm
-- Evolve creature stat distributions: HP, attack, defense, speed.
-- Each chromosome is a vector of trait values. Fitness rewards balanced builds.
local ga = lurek.ai.newGeneticAlgorithm({
    population_size = 20,
    chromosome_length = 4,  -- HP, ATK, DEF, SPD
    mutation_rate = 0.05,
    crossover_rate = 0.7
})
print("GA: pop=20, genes=4 (HP/ATK/DEF/SPD), mutation=5%, crossover=70%")

-- ---- Stub: GeneticAlgorithm:evolve ----------------------------------------
--@api-stub: GeneticAlgorithm:evolve
-- Run one generation of selection, crossover, and mutation.
ga:evolve()
print("generation evolved — new creature variants produced")

-- ---- Stub: GeneticAlgorithm:generation ------------------------------------
--@api-stub: GeneticAlgorithm:generation
print("current generation: " .. tostring(ga:generation()))

-- ---- Stub: GeneticAlgorithm:popSize ---------------------------------------
--@api-stub: GeneticAlgorithm:popSize
print("population size: " .. tostring(ga:popSize()))

-- ---- Stub: GeneticAlgorithm:setFitness ------------------------------------
--@api-stub: GeneticAlgorithm:setFitness
-- Assign fitness scores to each individual. Higher = better survival.
for i = 0, ga:popSize() - 1 do
    -- Fitness: reward balanced stats (low variance across HP/ATK/DEF/SPD)
    local fitness = math.random() * 10.0
    ga:setFitness(i, fitness)
end
print("fitness assigned to all " .. ga:popSize() .. " creatures")

-- ---- Stub: GeneticAlgorithm:getGenes --------------------------------------
--@api-stub: GeneticAlgorithm:getGenes
-- Inspect a specific individual's chromosome.
local genes = ga:getGenes(0)
if genes then
    print("creature #0 genes: HP=" .. string.format("%.1f", genes[1])
        .. " ATK=" .. string.format("%.1f", genes[2])
        .. " DEF=" .. string.format("%.1f", genes[3])
        .. " SPD=" .. string.format("%.1f", genes[4]))
end

-- ---- Stub: GeneticAlgorithm:bestGenes -------------------------------------
--@api-stub: GeneticAlgorithm:bestGenes
-- Get the fittest individual's chromosome for spawning elite enemies.
local best_genes = ga:bestGenes()
if best_genes then
    print("elite creature: HP=" .. string.format("%.1f", best_genes[1])
        .. " ATK=" .. string.format("%.1f", best_genes[2])
        .. " DEF=" .. string.format("%.1f", best_genes[3])
        .. " SPD=" .. string.format("%.1f", best_genes[4]))
end

-- =============================================================================
-- Multi-Armed Bandit — loot table optimization
-- =============================================================================

-- ---- Stub: lurek.ai.newBandit ---------------------------------------------
--@api-stub: lurek.ai.newBandit
-- Multi-armed bandit for A/B testing game features or optimising loot drops.
-- Each arm is a loot table variant; rewards measure player engagement.
local bandit = lurek.ai.newBandit({
    arms = 4,             -- 4 loot table variants to test
    strategy = "ucb1"     -- Upper Confidence Bound for exploration/exploitation
})
print("bandit created: 4 arms (loot variants), UCB1 strategy")

-- ---- Stub: Bandit:select --------------------------------------------------
--@api-stub: Bandit:select
-- Select which loot table variant to use for this player encounter.
local arm = bandit:select()
print("bandit selected arm " .. tostring(arm) .. " for this drop")

-- ---- Stub: Bandit:update --------------------------------------------------
--@api-stub: Bandit:update
-- After the player interacts with the loot, report the reward.
-- Higher reward = player engaged more (picked up items, used them, etc).
bandit:update(arm, 0.8)   -- arm performed well (player liked the loot)
print("arm " .. tostring(arm) .. " updated with reward 0.8")

-- ---- Stub: Bandit:bestArm -------------------------------------------------
--@api-stub: Bandit:bestArm
-- After many rounds, check which arm has the highest average reward.
local best_arm = bandit:bestArm()
print("best-performing loot variant: arm " .. tostring(best_arm))

-- ---- Stub: Bandit:reset ---------------------------------------------------
--@api-stub: Bandit:reset
-- Reset all statistics to start fresh (new game season, balance patch).
bandit:reset()
print("bandit stats reset — starting new loot experiment")

-- ---- Stub: Bandit:armCount ------------------------------------------------
--@api-stub: Bandit:armCount
print("bandit arm count: " .. tostring(bandit:armCount()))

-- ---- Stub: Bandit:totalPulls ----------------------------------------------
--@api-stub: Bandit:totalPulls
print("total selections so far: " .. tostring(bandit:totalPulls()))

-- =============================================================================
-- Neuroevolution — breeding champion fighters
-- =============================================================================

-- ---- Stub: lurek.ai.newNeuroevolution -------------------------------------
--@api-stub: lurek.ai.newNeuroevolution
-- Neuroevolution combines neural networks with genetic algorithms.
-- Each individual is a neural net; GA evolves the weights over generations.
local neuro = lurek.ai.newNeuroevolution({
    population_size = 30,
    input_size = 6,     -- enemy: dist, angle, hp, my_hp, my_stamina, cooldown
    hidden_sizes = {8, 6},
    output_size = 4,    -- actions: attack, dodge, heal, advance
    mutation_rate = 0.1
})
print("neuroevolution: pop=30, net=6->8->6->4, mutation=10%")

-- ---- Stub: Neuroevolution:evolve ------------------------------------------
--@api-stub: Neuroevolution:evolve
-- Run one generation: select fittest, crossover weights, mutate.
neuro:evolve()
print("neuroevolution generation evolved")

-- ---- Stub: Neuroevolution:setFitness --------------------------------------
--@api-stub: Neuroevolution:setFitness
-- Score each fighter based on combat performance (damage dealt, survival time).
for i = 0, neuro:popSize() - 1 do
    local fight_score = math.random() * 100.0
    neuro:setFitness(i, fight_score)
end
print("fitness scores assigned to all " .. neuro:popSize() .. " fighters")

-- ---- Stub: Neuroevolution:chromosomeToNet ---------------------------------
--@api-stub: Neuroevolution:chromosomeToNet
-- Extract a specific individual's neural net for evaluation.
local fighter_net = neuro:chromosomeToNet(0)
print("fighter #0 network extracted (" .. tostring(fighter_net:paramCount()) .. " params)")

-- ---- Stub: Neuroevolution:bestNetwork -------------------------------------
--@api-stub: Neuroevolution:bestNetwork
-- Get the champion fighter's network for deployment as a boss enemy.
local champion = neuro:bestNetwork()
print("champion network: " .. tostring(champion:paramCount()) .. " parameters")
print("  deploy this as the arena boss AI!")

-- ---- Stub: Neuroevolution:bestFitness ------------------------------------
--@api-stub: Neuroevolution:bestFitness
local best_fit = neuro:bestFitness()
print("champion fitness: " .. string.format("%.1f", best_fit))

-- ---- Stub: Neuroevolution:popSize -----------------------------------------
--@api-stub: Neuroevolution:popSize
print("neuroevolution population: " .. tostring(neuro:popSize()))

-- ---- Stub: Neuroevolution:generation --------------------------------------
--@api-stub: Neuroevolution:generation
print("neuroevolution generation: " .. tostring(neuro:generation()))

-- =============================================================================
-- Strategy AI — goal-driven faction AI
-- =============================================================================

-- ---- Stub: lurek.ai.newStrategyAI -----------------------------------------
--@api-stub: lurek.ai.newStrategyAI
-- High-level strategic AI that manages long-term faction goals.
-- Evaluates goals by priority and context tags, then activates the best one.
local faction_ai = lurek.ai.newStrategyAI({
    evaluation_interval = 5.0  -- re-evaluate every 5 seconds
})
print("strategy AI created: re-evaluates every 5s")

-- ---- Stub: StrategyAI:addGoal ---------------------------------------------
--@api-stub: StrategyAI:addGoal
-- Define strategic goals with priorities and context conditions.
faction_ai:addGoal("expand_territory", {
    priority = 8,
    condition = function(tags)
        return tags.military_strength > 50
    end,
    action = function() print("  [faction] expanding borders!") end
})
faction_ai:addGoal("defend_homeland", {
    priority = 10,
    condition = function(tags)
        return tags.under_attack == true
    end,
    action = function() print("  [faction] rallying defenders!") end
})
faction_ai:addGoal("trade_resources", {
    priority = 5,
    condition = function(tags)
        return tags.gold_reserves > 100
    end,
    action = function() print("  [faction] sending trade caravan") end
})
print("goals: expand(p=8), defend(p=10), trade(p=5)")

-- ---- Stub: StrategyAI:addTag ----------------------------------------------
--@api-stub: StrategyAI:addTag
-- Set context tags that goals use to evaluate their conditions.
faction_ai:addTag("military_strength", 75)
faction_ai:addTag("gold_reserves", 200)
faction_ai:addTag("under_attack", false)
print("faction tags: military=75, gold=200, under_attack=false")

-- ---- Stub: StrategyAI:removeTag -------------------------------------------
--@api-stub: StrategyAI:removeTag
-- Remove a tag when it's no longer relevant (e.g. war ended).
faction_ai:removeTag("under_attack")
print("removed 'under_attack' tag (peace treaty signed)")

-- ---- Stub: StrategyAI:update ----------------------------------------------
--@api-stub: StrategyAI:update
-- Tick the strategy AI. It will re-evaluate goals at the configured interval.
faction_ai:update(5.0)  -- trigger evaluation
print("strategy AI updated — goals evaluated")

-- ---- Stub: StrategyAI:forceEvaluate ---------------------------------------
--@api-stub: StrategyAI:forceEvaluate
-- Force immediate re-evaluation (e.g. sudden enemy invasion).
faction_ai:addTag("under_attack", true)
faction_ai:forceEvaluate()
print("forced evaluation after sudden invasion — defend should activate")

-- ---- Stub: StrategyAI:activeGoal ------------------------------------------
--@api-stub: StrategyAI:activeGoal
local active = faction_ai:activeGoal()
print("active strategic goal: " .. tostring(active))

-- ---- Stub: StrategyAI:timeUntilNext ---------------------------------------
--@api-stub: StrategyAI:timeUntilNext
-- How long until the next scheduled evaluation?
local until_next = faction_ai:timeUntilNext()
print("next evaluation in: " .. string.format("%.1f", until_next) .. "s")

-- =============================================================================
-- Cleanup — remove agents from the world
-- =============================================================================

-- ---- Stub: AIWorld:removeAgent --------------------------------------------
--@api-stub: AIWorld:removeAgent
-- Remove an agent when it dies, despawns, or exits the scene.
local removed = ai_world:removeAgent("alpha_wolf")
print("wolf removed from AI world: " .. tostring(removed))
print("remaining agents: " .. tostring(ai_world:getAgentCount()))

print("\n-- ai.lua example complete --")
