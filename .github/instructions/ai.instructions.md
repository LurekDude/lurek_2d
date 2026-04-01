---
applyTo: "src/ai/**"
---

# AI Module Instructions

Rules for working on `src/ai/` — the game AI subsystem.

## Module Rules

- All AI computation is **pure CPU math** — no GPU, window, or audio imports allowed
- AI types must be decoupled — an `Agent` can be driven by any `DecisionModel` (FSM, BT, Steering, or combination)
- Inter-agent communication goes through `Blackboard` — never direct struct access between agents
- All public types must have `///` doc comments

## Dependency Direction

- `ai` depends on `math` (Vec2 for steering, grid coordinates)
- `ai` must NOT depend on `graphics`, `audio`, `physics`, `engine`, `input`, or `window`
- `lua_api/ai_api.rs` bridges AI types to the Lua API

## Testing

- Tests live in `tests/ai_tests.rs`
- Test setup uses `make_lua()` helper creating a Lua VM
- Verify agent lifecycle: add, remove, count, query
- Test FSM transitions, BT node execution, steering vector output
- GOAP: test plan generation with known preconditions/effects
- QLearner: test reward accumulation and policy convergence over episodes

## Naming

- State machine states: lowercase strings (`"idle"`, `"patrol"`, `"chase"`)
- BT node types: enum variants (`Sequence`, `Selector`, `Parallel`, `Decorator`)
- Steering behaviors: verb names (`seek`, `flee`, `wander`, `arrive`)
