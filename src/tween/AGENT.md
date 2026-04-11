# `tween` — Agent Reference

| Property         | Value                                                                         |
|------------------|-------------------------------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                                               |
| **Status**       | Implemented — Full                                                            |
| **Lua API**      | `lurek.tween` (10 functions, 3 UserData types)                                |
| **Source**       | `src/tween/`                                                                  |
| **Rust Tests**   | `tests/rust/unit/tween_tests.rs`                                              |
| **Lua Tests**    | `tests/lua/unit/test_tween.lua`                                               |
| **Architecture** | `docs/architecture/engine-architecture.md` § Tier 1 Modules                  |

## Purpose

`src/tween/` provides runtime property animation for Lua table fields. It owns the timing
loop, applies easing, and writes interpolated values directly into target Lua tables each
frame via `TweenEngine::update(dt)`. It supports sequential step chains (`LuaTweenSequence`),
parallel groups (`LuaTweenParallel`), repeat and yoyo modes, and custom easing callbacks.
The Rust code in `handle.rs` and `engine.rs` carries `mlua` imports because the handle
types hold `LuaRegistryKey`; the Lua bridge in `src/lua_api/tween_api.rs` is registration-only.

## Source Files

| File        | Purpose                                                                        |
|-------------|--------------------------------------------------------------------------------|
| `mod.rs`    | Module root; re-exports all public types.                                      |
| `state.rs`  | `TweenState` — pure-Rust timing; `resolve_easing`, `builtin_easing_names`.    |
| `handle.rs` | `LuaTween`, `LuaTweenSequence`, `LuaTweenParallel`, `SequenceStep`, `ParallelEntry` + `impl LuaUserData`. |
| `engine.rs` | `TweenEngine` — active-pool driver: tracks registry keys, drives update/cancelAll. |

## Full Specification

Full spec: [`docs/specs/tween.md`](../../../docs/specs/tween.md)
