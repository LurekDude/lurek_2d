---
description: "Create a new AI behavior for Lurek2D game entities. Use when implementing FSM states, behavior tree nodes, steering behaviors, or GOAP actions. Produces working Rust AI code with Lua bindings and tests."
---

# Create AI Behavior

## Prerequisites

- Read `src/ai/mod.rs` to understand existing AI types
- Read `src/lua_api/ai_api.rs` for current Lua bindings
- Read `tests/rust/game/ai_tests.rs` for test patterns
- Load the `ai-systems` skill

## Steps

1. **Choose the AI model**
   - FSM: Simple state-based behavior (idle → patrol → chase)
   - BehaviorTree: Complex decision logic with fallbacks
   - Steering: Smooth movement (seek, flee, wander, flocking)
   - GOAP: Multi-step planning with preconditions/effects
   - QLearner: Learning from experience (small state spaces only)
   - UtilityAI: Weighted action scoring

2. **Implement the Rust type**
   - Add to appropriate file in `src/ai/`
   - Follow existing patterns (DecisionModel enum, Agent struct)
   - All computation must be pure CPU math — no GPU or window access
   - Add `///` doc comments on all public items

3. **Add Lua bindings**
   - Add to `src/lua_api/ai_api.rs`
   - Follow `register()` pattern with `Rc<RefCell<SharedState>>`
   - Return `LuaResult<T>` from all Lua-callable functions
   - Register under `lurek.ai.*` namespace

4. **Write tests**
   - Add tests to `tests/rust/game/ai_tests.rs`
   - Test creation, state transitions, and expected outputs
   - Use `make_lua()` helper for Lua integration tests
   - Float comparisons: `(val - expected).abs() < 1e-5`

5. **Quality gate**
   - `cargo test ai_tests` — all pass
   - `cargo clippy` — 0 warnings in ai module
   - `cargo fmt --check` — formatted

## Acceptance Criteria

- [ ] New AI type compiles and passes tests
- [ ] Lua bindings work under `lurek.ai.*`
- [ ] Doc comments on all public items
- [ ] No GPU, audio, or window dependencies in `src/ai/`
