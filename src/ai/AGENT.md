# src/ai/

Game AI toolkit providing decoupled subsystems for intelligent NPC behavior.

## What This Module Contains

FSM (finite state machines), BehaviorTree (hierarchical task networks), Steering (flocking/seek/flee), GOAP (goal-oriented action planning), QLearner (reinforcement learning), InfluenceMap (spatial threat/interest), FlowField (crowd pathing), UtilityAI (score-based decisions), Squad (group coordination), and Blackboard (shared AI state).

## Files

| File | Purpose |
|------|---------|
| `agent.rs` | `Agent` implementation |
| `behavior_tree.rs` | `BehaviorTree` implementation |
| `blackboard.rs` | `Blackboard` implementation |
| `command_queue.rs` | `CommandQueue` implementation |
| `flowfield.rs` | `Flowfield` implementation |
| `fsm.rs` | `Fsm` implementation |
| `goap.rs` | `Goap` implementation |
| `influence_map.rs` | `InfluenceMap` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `pathgrid.rs` | `Pathgrid` implementation |
| `qlearner.rs` | `Qlearner` implementation |
| `squad.rs` | `Squad` implementation |
| `steering.rs` | `Steering` implementation |
| `utility_ai.rs` | `UtilityAi` implementation |
| `world.rs` | `World` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/ai_tests.rs`
- **Lua API bindings**: `src/lua_api/ai_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
