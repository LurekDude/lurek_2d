# `tween` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.tween` |
| **Source** | `src/tween/` |
| **Rust Tests** | `tests/rust/unit/tween_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_tween.lua`, `tests/lua/stress/test_tween_stress.lua`, `tests/lua/integration/test_tween_entity.lua`, `tests/lua/integration/test_tween_camera.lua`, `tests/lua/integration/test_tween_animation.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The `tween` module owns time-based property interpolation for Lua-facing game objects. Its job is to take named numeric fields on Lua tables, apply easing over time, support repeats and yoyo playback, and coordinate single tweens, sequential chains, and parallel groups through a shared update engine.

This module exists so scripted gameplay code can animate values declaratively without embedding interpolation logic into every feature module. `TweenState` provides the pure numeric timing and easing core. The handle types carry the Lua registry references and state machines for single tweens, sequences, and parallel groups. `TweenEngine` then advances all active handles each frame and cleans them up when they complete or are cancelled.

The module intentionally does not own the main game clock, frame scheduling, scene update order, or any particular animated domain object. It also does not define a generic Rust-side property graph; the target values live in Lua tables and are updated from there. Systems such as camera, animation, UI, and ECS may all be animated by tween, but they retain ownership of their own state and meaning.

**Scope boundary**: This module currently depends on `math`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.tween.* (Lua API — src/lua_api/tween_api.rs)
    |
    v
src/tween/mod.rs
    |- engine.rs - engine
    |- handle.rs - handle
    |- state.rs - state
```

---

## Source Files

| File | Purpose |
|------|---------|
| `engine.rs` | Defines `TweenEngine`, the active-object pool that ticks live tween handles and releases them when done. |
| `handle.rs` | Defines the Lua-backed domain handle types for single tweens, sequences, parallel groups, and their step or entry records. |
| `mod.rs` | Declares the tween submodules and re-exports the core timing state, handle types, and engine. |
| `state.rs` | Defines `TweenState` plus built-in easing lookup and easing-name enumeration. |

---

## Submodules

### `tween::engine`

Defines `TweenEngine`, the active-object pool that ticks live tween handles and releases them when done.

- **`TweenEngine`** (struct): Active-object pool and frame-tick driver for the `lurek.tween` system.

### `tween::handle`

Defines the Lua-backed domain handle types for single tweens, sequences, parallel groups, and their step or entry records.

- **`LuaTween`** (struct): Lua UserData for a single property tween: animates named fields on a target table.
- **`SequenceStep`** (enum): A single step inside a [`LuaTweenSequence`].
- **`LuaTweenSequence`** (struct): Lua UserData for an ordered animation sequence: steps run one after another.
- **`ParallelEntry`** (struct): An inline tween entry owned and ticked by a [`LuaTweenParallel`].
- **`LuaTweenParallel`** (struct): Lua UserData for a parallel animation group: all child tweens run simultaneously.

### `tween::state`

Defines `TweenState` plus built-in easing lookup and easing-name enumeration.

- **`TweenState`** (struct): Pure numeric tween timing state: elapsed time, easing function, and pause flag.

---

## Key Types

### Public Types

#### `TweenState`

The pure timing and easing core that tracks elapsed time, completion, and interpolation progress without Lua dependencies.

#### `TweenEngine`

The active tween pool that updates all registered tweens, sequences, and parallel groups each frame.

#### `LuaTween`

The single-property-group tween handle that animates named numeric fields on a Lua table.

#### `LuaTweenSequence`

The ordered step runner that executes tween, delay, and callback steps one after another.

#### `LuaTweenParallel`

The grouped runner that executes multiple tween entries at the same time.

#### `SequenceStep`

The enum-like workflow step container used inside sequences.

#### `ParallelEntry`

The per-arm tween record stored inside a parallel group.

---

## Lua API

Exposed under `lurek.tween.*` by `src/lua_api/tween_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.tween.update` | Advances all active tweens, sequences, and parallels by `dt` seconds. |
| `lurek.tween.tween` | Creates a new property tween and registers it for automatic updating. |
| `lurek.tween.sequence` | Creates an empty TweenSequence. Add steps with :tween(), :delay(), :callback(), |
| `lurek.tween.parallel` | Creates an empty TweenParallel. Add entries with :tween() or :add(tween), |
| `lurek.tween.delay` | Creates a no-op tween that waits `seconds`, then optionally calls `callback`. |
| `lurek.tween.cancelAll` | Cancels all active tweens, sequences, and parallels immediately. |
| `lurek.tween.getActiveCount` | Returns the number of currently active tween objects (tweens + seqs + pars). |
| `lurek.tween.registerEasing` | Registers a custom easing function under `name`. `fn(t)` receives 0..1, returns 0..1. |
| `lurek.tween.getEasingNames` | Returns a list of all available easing names (built-in + custom). |

### `Tween` Methods

| Method | Description |
|--------|-------------|
| `tween:pause(...)` | Pauses this tween; time stops advancing but the tween is not cancelled. |
| `tween:resume(...)` | Resumes a paused tween. |
| `tween:isActive(...)` | Returns true if the tween is still running (not completed or cancelled). |
| `tween:getProgress(...)` | Returns raw 0..1 playback progress (not eased, not accounting for yoyo). |
| `tween:setRepeat(...)` | Sets the number of extra play cycles after the first (0 = play once, -1 = infinite). |
| `tween:setYoyo(...)` | Enables or disables yoyo (ping-pong) on each repeat cycle. |

### `TweenParallel` Methods

| Method | Description |
|--------|-------------|
| `tweenparallel:cancel(...)` | Cancels the parallel group immediately. |
| `tweenparallel:isActive(...)` | Returns true if the parallel is running and not yet complete. |

### `TweenSequence` Methods

| Method | Description |
|--------|-------------|
| `tweensequence:cancel(...)` | Cancels the sequence and stops all pending steps. |
| `tweensequence:isActive(...)` | Returns true if the sequence has been started and has not yet completed. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.tween.
if lurek.tween then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 6 |
| `enum` | 1 |
| `fn` (Lua API) | 19 |
| **Total** | **26** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `math` | Imports or references `math` from `src/math/`. | Cross-group dependency from Feature Systems to Foundations. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/tween/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
