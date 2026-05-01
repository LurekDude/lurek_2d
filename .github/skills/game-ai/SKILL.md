---
name: game-ai
description: "Load this skill when designing or implementing lurek.ai.* game behavior like FSMs, behavior trees, GOAP, steering, or squad logic. Skip it for Rust AI internals or pathfinding algorithms."
---
# game-ai

## Mission
- Own game-facing AI patterns built on lurek.ai.*.

## When To Load
- Design or write FSM, BT, GOAP, steering, or utility AI.
- Build enemy or NPC behavior.
- Connect AI to game actions.

## When To Skip
- Rust AI internals.
- Pathfinding algorithm work.

## Domain Knowledge
- How AI worlds and agents wire up: call `lurek.ai.newWorld()` once per scene, call `world:addAgent("name")` for each agent, then drive the whole world from `lurek.process(dt)` by calling `world:update(dt)`. The FSM/BT/GOAP decision model is assigned per-agent; it is not a global world setting. See `content/examples/ai.lua` for every constructor with realistic state names.
- How FSMs work in code: `src/ai/fsm.rs` implements guarded priority transitions. The update cycle is: (1) check all transitions from current state in descending priority order, (2) fire the first whose guard returns true, (3) call `on_exit` on the old state, reset `time_in_state`, call `on_enter` on the new state, (4) call `on_update(dt)` on the current state. To add a transition, call `fsm:addTransition("from", "to", guardFn, priority)`.
- How blackboards work: `src/ai/blackboard.rs` is a typed key-value store with parent chain lookup. An agent's blackboard looks up its parent (world global blackboard) when a key is not found locally. Writes always stay local. Three value types: `Number(f64)`, `Bool(bool)`, `Text(String)`. Use blackboards to pass signals between agents and between AI subsystems — for example, write `"player_seen" = true` on the world blackboard so any agent can read it.
- FSM vs BT decision rule: use FSMs for behaviors with fewer than ~8 states and predictable transitions. Use behavior trees when the behavior is hierarchical (select best action from a priority list, run subtrees conditionally). The engine supports `lurek.ai.newBehaviorTree()` with `Sequence`, `Selector`, `Condition`, and `Action` node types. Avoid mixing FSM and BT on the same agent — pick one model per agent.
- Steering and squads: `lurek.ai.newSteeringAgent()` drives movement. Steering is independent of FSM/BT; attach it to any agent and call `agent:setSteeringTarget(x, y)` each frame. Squads (`lurek.ai.newSquad()`) share a squad-level blackboard — write formation or tactical data there so all members can read it without per-agent coupling.
- Test edge states explicitly via `tests/lua/unit/test_ai_unit.lua`: idle, chase, lose-target, reset, empty world, conflicting goals, no-valid-action. These are the common failure modes. The Lua test file is headless — no window required — which means every FSM state name and transition guard can be verified without running the full engine.
- `pathfind` owns grid search and route math. `ai` owns decision-making and behavior composition. Never call pathfinding algorithms directly in an AI script; call `lurek.pathfind.findPath(world, x1, y1, x2, y2)` and use the returned waypoint list to set steering targets.
## Companion File Index
- None.

## References
- docs/specs/ai.md
- src/lua_api/ai_api.rs
- tests/lua/unit/test_ai_unit.lua
- docs/specs/pathfind.md
