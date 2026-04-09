# `tween` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Subsystems                             |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.tween`                                        |
| **Source**     | `src/tween/`                                         |
| **Rust Tests** | `tests/rust/unit/tween_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_tween.lua`                      |

## Purpose

Tier 1 Engine Subsystem that provides all Rust domain logic for the `lurek.tween`
property animation system: pure timing/easing state, handle types for tweens and
composite objects, and the active-pool engine that drives frame-tick orchestration.

The Lua binding (`src/lua_api/tween_api.rs`) is a **thin registration-only wrapper**
that contains no business logic — all structs, `impl` blocks, and algorithms live here.
`handle.rs` and `engine.rs` import `mlua` because they own Lua registry keys directly.

## Source Files

| File | Role |
|---|---|
| `src/tween/mod.rs` | Module root; re-exports all public types |
| `src/tween/state.rs` | `TweenState` struct, `resolve_easing`, `builtin_easing_names` |
| `src/tween/handle.rs` | `LuaTween`, `LuaTweenSequence`, `LuaTweenParallel`, `SequenceStep`, `ParallelEntry` + `impl LuaUserData` |
| `src/tween/engine.rs` | `TweenEngine`: active-pool management, `update()`, `cancel_all()` |

## Full Spec

`docs/specs/tween.md`

## Key Types

| Type | Location | Description |
|---|---|---|
| `TweenState` | `state.rs` | Pure-Rust timing: elapsed, duration, easing fn, pause flag |
| `resolve_easing(name) -> Option<fn>` | `state.rs` | Maps easing name strings to function pointers |
| `builtin_easing_names() -> &[&str]` | `state.rs` | All built-in easing names for Lua introspection |
| `LuaTween` | `handle.rs` | Single property tween UserData with callbacks and repeat/yoyo |
| `LuaTweenSequence` | `handle.rs` | Ordered step sequence UserData |
| `LuaTweenParallel` | `handle.rs` | Parallel tween group UserData |
| `SequenceStep` | `handle.rs` | Tween / Delay / Callback step variants |
| `ParallelEntry` | `handle.rs` | Inline tween entry owned by `LuaTweenParallel` |
| `TweenEngine` | `engine.rs` | Active-pool driver: tracks registry keys, drives update/cancelAll |

## Lua API Summary

All Lua-visible functions live in `src/lua_api/tween_api.rs` (thin wrapper only)
under `lurek.tween.*`.

| Function | Description |
|---|---|
| `lurek.tween.update(dt)` | Tick all active tweens/sequences/parallels |
| `lurek.tween.tween(dur, target, fields, easing)` | Create and register a property tween |
| `lurek.tween.sequence()` | Create an empty step sequence |
| `lurek.tween.parallel()` | Create a parallel tween group |
| `lurek.tween.delay(sec, fn)` | Wait + optional callback |
| `lurek.tween.cancelAll()` | Cancel and remove all active objects |
| `lurek.tween.getActiveCount()` | Number of tracked active objects |
| `lurek.tween.registerEasing(name, fn)` | Register a custom Lua easing function |
| `lurek.tween.getEasingNames()` | List all easing names (built-in + custom) |

## Rust Tests

`tests/rust/unit/tween_tests.rs` — 14 unit tests for `TweenState`, `resolve_easing`,
`builtin_easing_names`

## Lua Tests

`tests/lua/unit/test_tween.lua` — BDD suite covering all `lurek.tween.*` functions
(~50 tests across tween, sequence, parallel, delay, callbacks, repeat/yoyo)

## Design Notes

- `TweenState` uses a pure function-pointer approach (`fn(f32) -> f32`) for easing —
  no heap allocation per tween.
- Start values are **lazily captured** from the target Lua table on the first
  `lurek.tween.update()` call after creation. This lets scripts modify the target
  between `tween()` and the first frame.
- Sequences and parallels own their child tween data inline (`Vec<SequenceStep>`,
  `Vec<ParallelEntry>`) — no secondary registry tracking for steps.
- Custom Lua easing functions are stored as `LuaRegistryKey` in `TweenEngine`;
  the built-in resolution bypasses Lua entirely for zero-overhead easing.

## Separation from Related Modules

| Module | Responsibility |
|---|---|
| `src/tween/` (this module) | Property tweening: animates Lua table fields over time with callbacks, sequences, and parallels. Active-pool managed. |
| `src/animation/` | Frame-based sprite animation: switches sprite frame indices at a given FPS. No numeric interpolation. |
| `src/math/tween.rs` | Standalone numeric interpolator: manual clock, multiple values, no Lua table fields, no callbacks. Used by `lurek.math.newTween()`. |
| `src/spine/` | Skeletal bone hierarchies: parent/child transforms, slot management. Separate from all above. |
