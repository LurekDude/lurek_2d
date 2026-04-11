# `tween` — Agent Reference

## Module Info

- Module name: `tween`
- Module group: Feature Systems
- Spec path: `docs/specs/tween.md`
- Lua API path(s): `src/lua_api/tween_api.rs`
- Rust test path(s): `tests/rust/unit/tween_tests.rs`
- Lua test path(s): `tests/lua/unit/test_tween.lua`, `tests/lua/stress/test_tween_stress.lua`, `tests/lua/integration/test_tween_entity.lua`, `tests/lua/integration/test_tween_camera.lua`, `tests/lua/integration/test_tween_animation.lua`

## Module Purpose

The `tween` module owns time-based property interpolation for Lua-facing game objects. Its job is to take named numeric fields on Lua tables, apply easing over time, support repeats and yoyo playback, and coordinate single tweens, sequential chains, and parallel groups through a shared update engine.

This module exists so scripted gameplay code can animate values declaratively without embedding interpolation logic into every feature module. `TweenState` provides the pure numeric timing and easing core. The handle types carry the Lua registry references and state machines for single tweens, sequences, and parallel groups. `TweenEngine` then advances all active handles each frame and cleans them up when they complete or are cancelled.

The module intentionally does not own the main game clock, frame scheduling, scene update order, or any particular animated domain object. It also does not define a generic Rust-side property graph; the target values live in Lua tables and are updated from there. Systems such as camera, animation, UI, and ECS may all be animated by tween, but they retain ownership of their own state and meaning.

## Files

- `mod.rs`: Declares the tween submodules and re-exports the core timing state, handle types, and engine.
- `state.rs`: Defines `TweenState` plus built-in easing lookup and easing-name enumeration.
- `handle.rs`: Defines the Lua-backed domain handle types for single tweens, sequences, parallel groups, and their step or entry records.
- `engine.rs`: Defines `TweenEngine`, the active-object pool that ticks live tween handles and releases them when done.

## Key Types

- `TweenState`: The pure timing and easing core that tracks elapsed time, completion, and interpolation progress without Lua dependencies.
- `TweenEngine`: The active tween pool that updates all registered tweens, sequences, and parallel groups each frame.
- `LuaTween`: The single-property-group tween handle that animates named numeric fields on a Lua table.
- `LuaTweenSequence`: The ordered step runner that executes tween, delay, and callback steps one after another.
- `LuaTweenParallel`: The grouped runner that executes multiple tween entries at the same time.
- `SequenceStep`: The enum-like workflow step container used inside sequences.
- `ParallelEntry`: The per-arm tween record stored inside a parallel group.