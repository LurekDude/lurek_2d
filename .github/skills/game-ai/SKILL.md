---
name: game-ai
description: "Load this skill when designing or implementing AI behaviour for game actors in Lurek2D using the lurek.ai.* API: finite state machines, behaviour trees, GOAP planners, steering behaviours, utility AI, Q-learning, squad formations, command queues, influence maps, or the shared Blackboard. Use for: enemy patrol/chase/flee, NPC decision-making, group tactics, pathfinding integration, AI testing. Skip it for general Rust AI module internals (see src/ai/AGENT.md) or pathfinding algorithms (see src/pathfinding/AGENT.md)."
---

# Game AI Design — Lurek2D

## Load When

- Choosing which AI model to use for a game actor (FSM vs behaviour tree vs GOAP vs utility)
- Building enemy patrol, chase, flee, idle, or attack behaviour
- Designing NPC decision trees or goal-oriented planning
- Implementing group/squad tactics or formation movement
- Adding influence maps or spatial strategy reasoning
- Integrating AI agents with physics and pathfinding
- Testing AI behaviour headlessly

## Owns

- Decision model selection guide (when to use FSM vs BTree vs GOAP vs utility AI)
- `lurek.ai.*` Lua API patterns for each model
- Blackboard usage as shared AI memory
- Steering behaviour combinations
- Q-learning setup for simple reinforcement learning
- Squad and command queue patterns for group AI
- Influence map and flow field integration
- AI testing strategies

---

## Decision Model Selection Guide

Choose the simplest model that satisfies the design requirement.

| Model | Best for | Avoid when |
|-------|---------|-----------|
| **FSM** | Small number of discrete states with clear transitions (guard: patrol→alert→attack) | > ~8 states — becomes spaghetti |
| **Behaviour Tree** | Prioritised, reusable, hierarchical actions (patrol UNTIL enemy seen THEN chase AND shoot) | Simple 2-3 state machines — overkill |
| **GOAP** | Open-ended NPC with many possible actions and goals, emergent behaviour | Real-time enemies where planning cost matters |
| **Utility AI** | Multi-axis decisions where multiple actions compete on scored criteria | Binary (yes/no) decisions — FSM is simpler |
| **Steering** | Smooth movement: seek, flee, arrive, wander, flock | Discrete turn-based movement |
| **Q-learning** | Simple adaptive agents that improve with play (tabular, discrete state space) | Large or continuous state spaces — use FSM instead |

---

## AI World Setup

All AI agents live inside an `AIWorld` registry. Create one world per scene.

```lua
function lurek.init()
    world = lurek.ai.newWorld()
    grid  = lurek.pathfinding.newGrid(40, 30, 16)   -- integration with pathfinding
end
```

---

## FSM — Finite State Machine

Best for enemies with clear discrete modes.

```lua
local guard = world:newAgent("guard", startX, startY)
local fsm   = guard:useFsm()

-- Define states
fsm:addState("patrol",  onEnterPatrol, onUpdatePatrol, onExitPatrol)
fsm:addState("alert",   nil,           onUpdateAlert,  nil)
fsm:addState("attack",  nil,           onUpdateAttack, nil)

-- Add transitions (higher priority number = checked first)
fsm:addTransition("patrol", "alert",  1, function() return canSeePlayer() end)
fsm:addTransition("alert",  "attack", 2, function() return isClose(32) end)
fsm:addTransition("alert",  "patrol", 1, function() return lostSight(5) end)

fsm:setState("patrol")

-- Per-frame update
function lurek.process(dt)
    world:update(dt)   -- updates all agents
end
```

```lua
-- State callbacks have access to dt and the agent
function onUpdatePatrol(agent, dt)
    local next = patrolPath[agent.waypointIndex]
    agent:seek(next.x, next.y, 80)   -- steering: move toward waypoint at speed 80
    if agent:distanceTo(next.x, next.y) < 8 then
        agent.waypointIndex = (agent.waypointIndex % #patrolPath) + 1
    end
end
```

---

## Behaviour Tree

Best for complex, reusable, hierarchical NPC logic.

```lua
local npc = world:newAgent("npc", x, y)
local bt  = npc:useBt()

-- Build tree with composite nodes
local root = bt:sequence({
    bt:condition(function(a) return not a:blackboard("alert") end),
    bt:action(doPatrol),
    bt:selector({
        bt:sequence({
            bt:condition(canSeePlayer),
            bt:action(facePlayer),
            bt:action(shootAtPlayer),
        }),
        bt:action(resumePatrol),
    }),
})
bt:setRoot(root)

-- Node return values: "success", "failure", "running"
function doPatrol(agent)
    agent:seek(nextWaypoint())
    return "running"
end
```

### Common node types

| Node | Type | Returns success when |
|------|------|---------------------|
| `bt:sequence({...})` | Composite | ALL children succeed |
| `bt:selector({...})` | Composite | ANY child succeeds |
| `bt:parallel({...}, n)` | Composite | N children succeed simultaneously |
| `bt:inverter(child)` | Decorator | Child returns failure |
| `bt:repeater(child, n)` | Decorator | Child ran N times |
| `bt:succeeder(child)` | Decorator | Always (wraps any child) |
| `bt:condition(fn)` | Leaf | `fn(agent)` returns truthy |
| `bt:action(fn)` | Leaf | `fn(agent)` returns `"success"` |

---

## Blackboard — Shared AI Memory

The `Blackboard` is a hierarchical key-value store. Write local facts per-agent; read global facts (e.g. player position) via parent chain.

```lua
-- Global blackboard on the world — all agents can read these
world:blackboard():set("playerX", player.x)
world:blackboard():set("playerY", player.y)
world:blackboard():set("alertLevel", 0)

-- Agent-local blackboard (parent = world blackboard)
local bb = guard:blackboard()
bb:set("waypointIndex", 1)
bb:set("lastSeenX", nil)

-- Read: walks parent chain if not found locally
local px = bb:get("playerX")   -- reads from global blackboard

-- Update global facts each frame
function lurek.process(dt)
    world:blackboard():set("playerX", player.x)
    world:blackboard():set("playerY", player.y)
    world:update(dt)
end
```

---

## Steering Behaviours

Steering behaviours produce smooth movement forces combined by `SteeringManager`.

```lua
local enemy = world:newAgent("enemy", x, y)
local sm    = enemy:useSteering()

-- Add behaviours (weight, enabled)
sm:seek(targetX, targetY, 1.0)       -- move toward target
sm:arrive(targetX, targetY, 1.0, 40) -- decelerate as it gets close (radius=40)
sm:wander(0.5)                        -- random drift
sm:flee(dangerX, dangerY, 0.8)       -- run away from a point
sm:evade(pursuerAgent, 0.9)          -- predict and flee a moving agent
sm:pursue(preyAgent, 1.0)            -- predict and intercept a moving agent
sm:flock({buddy1, buddy2}, 0.6)      -- separation+cohesion+alignment

-- Combination mode
sm:setCombineMode("weighted")   -- sum all weighted forces (default)
sm:setCombineMode("priority")   -- use first non-zero force (for override behaviour)

-- Apply per-frame
function lurek.process(dt)
    world:update(dt)
    -- agent position updated automatically by SteeringManager
end
```

---

## GOAP — Goal-Oriented Action Planning

Best for emergent NPCs with many possible actions and multiple goals.

```lua
local npc    = world:newAgent("villager", x, y)
local planner = npc:useGoap()

-- World state (boolean facts)
local actions = {
    {
        name = "gather_food",
        preconditions = { has_tool = true },
        effects = { has_food = true },
        cost = 1,
        perform = function(agent) gatherAnimation(agent) end,
    },
    {
        name = "craft_tool",
        preconditions = { has_wood = true },
        effects = { has_tool = true },
        cost = 2,
        perform = function(agent) craftAnimation(agent) end,
    },
}
planner:setActions(actions)
planner:setGoal({ has_food = true })

-- GOAP searches for cheapest action sequence to reach goal
-- Call re-plan when the situation changes:
planner:replan({ has_tool = false, has_wood = true })
```

---

## Utility AI — Scored Action Selection

Best for NPCs that weigh many competing factors simultaneously.

```lua
local npc = world:newAgent("merchant", x, y)
local ua  = npc:useUtility()

ua:addAction("sell_goods",  function(agent)
    return agent:blackboard():get("inventory_full") and 0.9 or 0.1
end)
ua:addAction("restock",     function(agent)
    local stock = agent:blackboard():get("stock_level")
    return 1.0 - stock   -- low stock = high score
end)
ua:addAction("take_break",  function(agent)
    local fatigue = agent:blackboard():get("fatigue")
    return fatigue > 0.7 and 0.8 or 0.0
end)

-- Returns the action name with highest score each frame
local action = ua:selectAction()
performAction(npc, action)
```

---

## Squad — Group Formation

```lua
local squad = world:newSquad("alpha")
squad:addMember(agent1)
squad:addMember(agent2)
squad:addMember(agent3)

-- Formation types: "line", "wedge", "circle", "column", "none"
squad:setFormation("wedge")
squad:setLeader(agent1)
squad:moveTo(targetX, targetY)   -- all members offset from leader

-- Formation updates automatically in world:update(dt)
```

---

## Influence Map — Strategic Spatial Reasoning

```lua
local imap = lurek.pathfinding.newInfluenceMap(40, 30, 16)

-- Add named layers
imap:addLayer("player_threat")
imap:addLayer("enemy_presence")

-- Stamp values (position, radius, strength, layer)
imap:stamp(player.x, player.y, 80, 1.0, "player_threat")
imap:stamp(enemy.x, enemy.y, 40, 0.8, "enemy_presence")

-- Propagate influence across cells
imap:propagate("player_threat", 0.7)   -- decay factor

-- Decay over time
imap:decay("player_threat", 0.95, dt)

-- Query to find best position (minimize player_threat, maximize cover)
local sx, sy = imap:findMin("player_threat")   -- safest cell
```

---

## Testing AI

AI runs headlessly (no GPU, audio, or window needed):

```lua
-- tests/lua/unit/test_ai.lua
describe("lurek.ai FSM", function()
    it("transitions from patrol to alert when condition fires", function()
        local w   = lurek.ai.newWorld()
        local a   = w:newAgent("guard", 0, 0)
        local fsm = a:useFsm()
        fsm:addState("patrol", nil, nil, nil)
        fsm:addState("alert",  nil, nil, nil)

        local triggered = false
        fsm:addTransition("patrol", "alert", 1, function() return triggered end)
        fsm:setState("patrol")

        w:update(0.016)
        expect_equal("patrol", a:getState())

        triggered = true
        w:update(0.016)
        expect_equal("alert", a:getState())
    end)
end)
```

**Rule**: Create a fresh `AIWorld` per test — worlds are stateful and must not leak across tests.
