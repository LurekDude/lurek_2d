# `lurek.tween` — Property Tweening System

## Summary

The `tween` module provides runtime property animation for Lua table fields. Unlike the math-module
primitives in `src/math/tween.rs` that interpolate a single value on demand, this system owns the
timing loop: it accepts a target table, a field name, start/end values, a duration, and an easing
function name, then writes updated values directly into the Lua table each frame.

Active tweens are tracked by `TweenEngine` and advanced via `tick(dt)`. Sequenced tweens
(`LuaTweenSequence`) run steps in order; parallel groups (`LuaTweenParallel`) run all arms
simultaneously. `TweenEngine` also maintains a registry of named custom easing callbacks. The Lua
API is exposed under `lurek.tween.*` and registered in `src/lua_api/tween_api.rs`.

Scope: this module handles timed property interpolation only — it does not own the engine clock or
the fixed-timestep accumulator. For complex multi-property animation graphs see `src/animation/`.

## Source Files

| File | Purpose |
|---|---|
| `src/tween/mod.rs` | Module root; re-exports `TweenEngine`, `TweenState`, `SequenceStep`, `ParallelEntry` |
| `src/tween/engine.rs` | `TweenEngine` — manages active tweens; `tick(dt)` advances and removes completed tweens |
| `src/tween/tween_state.rs` | `TweenState` — per-tween runtime state: target, property, progress, easing fn |
| `src/tween/sequence.rs` | `SequenceStep` — one step in a chained tween sequence |
| `src/tween/parallel.rs` | `ParallelEntry` — one arm in a simultaneous tween group |
| `src/lua_api/tween_api.rs` | Registers `lurek.tween.*`; wraps engine as `LuaTween`, sequences as `LuaTweenSequence`, parallel as `LuaTweenParallel` |

## Key Types

### Structs

#### `tween::engine::TweenEngine`

Central manager for active tween animations. Holds a `Vec<TweenState>` of running tweens plus a
`HashMap` of named custom easing closures. `tick(dt)` advances all running tweens, applies easing,
and writes interpolated values into target Lua tables. Completed tweens are removed automatically.

#### `tween::tween_state::TweenState`

Runtime state for one active tween. Tracks: target-table registry key, property name, from/to
values, elapsed and total duration, easing function, repeat count, and yoyo flag.

#### `tween::sequence::SequenceStep`

A single step in a sequential animation chain. Holds a `TweenState` and an optional on-complete
Lua callback. The chain advances to the next step when the current step finishes.

#### `tween::parallel::ParallelEntry`

A single arm in a parallel animation group. Holds a `TweenState`. All arms run simultaneously; the
group completes when every arm finishes.

#### `tween_api::LuaTween`

Lua UserData wrapping `TweenEngine`. Created via `lurek.tween.newEngine()`. Exposes `tween(...)`,
`sequence(...)`, `parallel(...)`, `update(dt)`, `stop(id)`, and custom easing registration.

#### `tween_api::LuaTweenSequence`

Lua UserData for a sequential chain of `SequenceStep` entries. Created by
`lurek.tween.sequence(steps)`. Advances steps in order; on-complete callbacks fire per step.

#### `tween_api::LuaTweenParallel`

Lua UserData for a simultaneous group of `ParallelEntry` arms. Created by
`lurek.tween.parallel(tweens)`. Completes when all arms finish.

## Architecture

`lurek.tween` provides **runtime property animation** for any Lua table field. Unlike
the math-level `src/math/tween.rs` primitive (which interpolates between two numeric
values on demand), this system owns the timing loop, applies easing, and writes
results directly into target tables each frame. It mirrors Engine C's
`Tween.tween_property` workflow:

```lua
-- animate any table field by string name
lurek.tween.tween(1.0, player, { x = 500 }, "cubicOut")
```

---

## Architecture

```
┌───────────────────────────────────────────────────┐
│ src/lua_api/tween_api.rs  ← THIN WRAPPER ONLY     │
│   pub fn register()  (no structs, no logic)        │
│            │                                       │
│            ▼                                       │
│ src/tween/engine.rs  (domain — active-pool driver) │
│   TweenEngine · update() · cancel_all()            │
│            │                                       │
│            ▼                                       │
│ src/tween/handle.rs  (domain — UserData handles)   │
│   LuaTween · LuaTweenSequence · LuaTweenParallel   │
│   SequenceStep · ParallelEntry                     │
│   impl LuaUserData for all three                   │
│            │                                       │
│            ▼                                       │
│ src/tween/state.rs  (pure Rust)                    │
│   TweenState · resolve_easing · builtin_easing_names│
│            │                                       │
│            ▼                                       │
│ src/math/easing.rs  (leaf math)                    │
└───────────────────────────────────────────────────┘
```

**Thin Wrapper Rule**: `tween_api.rs` contains only `pub fn register()` and closure
bodies that immediately delegate to domain types. All business logic, `impl` blocks,
and algorithms live in `src/tween/`.

**Update model**: Manual. The script calls `lurek.tween.update(dt)` from
`lurek.process(dt)`. No automatic engine tick.

**Start value capture**: Lazy — start values are read from the target table on the
first update tick, not at tween creation. This means the script may move the target
between frames without surprising behaviour.

---

## Module Layout

| File | Role |
|---|---|
| `src/tween/state.rs` | `TweenState`, `resolve_easing`, `builtin_easing_names` (pure Rust) |
| `src/tween/handle.rs` | `LuaTween`, `LuaTweenSequence`, `LuaTweenParallel`, `SequenceStep`, `ParallelEntry` + `impl LuaUserData` |
| `src/tween/engine.rs` | `TweenEngine`: active-pool management, `update()`, `cancel_all()` |
| `src/tween/mod.rs` | Module root + public re-exports |
| `src/lua_api/tween_api.rs` | **Thin wrapper**: only `pub fn register()` |

---

## Rust Types

### `TweenState` (src/tween/state.rs)

```rust
pub struct TweenState {
    pub duration:   f64,
    pub elapsed:    f64,
    pub easing_fn:  fn(f32) -> f32,
    pub paused:     bool,
}
```

| Method | Returns | Description |
|---|---|---|
| `new(duration, easing_name)` | `TweenState` | Falls back to `linear` on unknown name |
| `tick(dt) -> bool` | `bool` | Advance elapsed; `true` if complete |
| `reset()` | `()` | Set elapsed = 0 |
| `t_raw() -> f32` | `f32` | Clamped `(elapsed/duration)` in [0,1] |
| `t_eased() -> f64` | `f64` | `easing_fn(t_raw)` as f64 |
| `lerp(start, end) -> f64` | `f64` | Start + (end-start) × t_eased |
| `is_complete() -> bool` | `bool` | `elapsed >= duration` |

### `resolve_easing(name: &str) -> Option<fn(f32) -> f32>`

Case-insensitive lookup of built-in easing names → function pointer. Returns `None`
for unknown names (callers may fall back to linear).

### `builtin_easing_names() -> &'static [&'static str]`

Returns a 23-entry slice of all built-in easing names. Used by
`lurek.tween.getEasingNames()`.

---

## Domain Types (src/tween/)

### `TweenEngine` (src/tween/engine.rs)

Module-local `Rc<RefCell<TweenEngine>>` instantiated by `register()`. Holds:

- `active_tweens: Vec<LuaRegistryKey>` — refs to active `LuaTween` UserData
- `active_seqs: Vec<LuaRegistryKey>` — refs to active `LuaTweenSequence` UserData
- `active_pars: Vec<LuaRegistryKey>` — refs to active `LuaTweenParallel` UserData
- `custom_easings: HashMap<String, LuaRegistryKey>` — user-registered Lua fns

Uses `std::mem::take` in `update()` to drain the active list and rebuild it with
surviving entries, avoiding double-borrow.

### `LuaTween` (UserData, src/tween/handle.rs)

Created by `lurek.tween.tween(duration, target, fields, easing)`.

| Field | Type | Description |
|---|---|---|
| `state` | `TweenState` | Timing/easing core |
| `target_key` | `LuaRegistryKey` | Strong ref to target table |
| `fields` | `Vec<String>` | field names to animate |
| `end_values` | `Vec<f64>` | target numeric values |
| `start_values` | `Vec<f64>` | captured on first tick |
| `starts_captured` | `bool` | lazy capture flag |
| `active` | `bool` | live/dead flag |
| `paused` | `bool` | pause state |
| `owned_by_parent` | `bool` | set when moved into a `LuaTweenParallel` |
| `repeat_count` | `i32` | 0 = play once; -1 = infinite; n = n extra repeats |
| `cycles_remaining` | `i32` | countdown for repeat |
| `yoyo` | `bool` | reverse on alternate cycles |
| `yoyo_reversed` | `bool` | current direction flag |
| `on_complete` | `Option<LuaRegistryKey>` | callback |
| `on_update` | `Option<LuaRegistryKey>` | per-tick callback `(t: number)` |
| `on_cancel` | `Option<LuaRegistryKey>` | callback |

**Lua methods on `LuaTween`:**

| Method | Returns | Description |
|---|---|---|
| `:cancel()` | — | Stop and fire `onCancel` |
| `:pause()` | — | Pause time advance |
| `:resume()` | — | Resume from pause |
| `:isActive()` | `bool` | Live state |
| `:getProgress()` | `number` | `t_raw` in [0,1] |
| `:setRepeat(n)` | `self` | Set extra cycle count (chain) |
| `:setYoyo(enable)` | `self` | Toggle yoyo reversal (chain) |
| `:onComplete(fn)` | `self` | Register completion callback (chain) |
| `:onUpdate(fn)` | `self` | Register per-tick callback (chain) |
| `:onCancel(fn)` | `self` | Register cancel callback (chain) |

### `LuaTweenSequence` (UserData, src/tween/handle.rs)

Created by `lurek.tween.sequence()`. Inactive until `:start()`.

Steps (enum `SequenceStep`):
- `Tween { state, target_key, fields, end_values, start_values, starts_captured }`
- `Delay { duration, elapsed, callback: Option<LuaRegistryKey> }`
- `Callback(LuaRegistryKey)`

**Lua methods:**

| Method | Returns | Description |
|---|---|---|
| `:tween(dur, target, fields, easing)` | `self` | Append tween step (chain) |
| `:delay(sec)` / `:delay(sec, fn)` | `self` | Append delay ± callback (chain) |
| `:callback(fn)` | `self` | Append instant callback (chain) |
| `:start()` | `self` | Activate (registers with TweenApiState) |
| `:cancel()` | — | Deactivate sequence |
| `:isActive()` | `bool` | Live state |
| `:onComplete(fn)` | `self` | Register completion callback (chain) |

### `LuaTweenParallel` (UserData, src/tween/handle.rs)

Created by `lurek.tween.parallel()`. Inactive until `:start()`.

Entries (struct `ParallelEntry`): inline tween data with `done: bool`.

**Lua methods:**

| Method | Returns | Description |
|---|---|---|
| `:tween(dur, target, fields, easing)` | `self` | Inline append (chain) |
| `:add(tween)` | `self` | Move `LuaTween` data into parallel; marks `owned_by_parent = true` on source |
| `:start()` | `self` | Activate (registers with TweenApiState) |
| `:cancel()` | — | Deactivate parallel |
| `:isActive()` | `bool` | Live state |
| `:onComplete(fn)` | `self` | Register completion callback (chain) |

---

## Lua API Reference (`lurek.tween.*`)

### `lurek.tween.update(dt: number)`

Advance all active tweens, sequences, and parallels. Call from `lurek.process(dt)`.

```lua
lurek.process = function(dt)
    lurek.tween.update(dt)
end
```

---

### `lurek.tween.tween(duration, target, fields[, easing]) -> LuaTween`

Create and immediately register a property tween.

| Param | Type | Default | Description |
|---|---|---|---|
| `duration` | `number` | — | Seconds for one cycle |
| `target` | `table` | — | The table whose fields will animate |
| `fields` | `table` | — | `{field = end_value, ...}` |
| `easing` | `string` | `"linear"` | Built-in or custom easing name |

```lua
local obj = { x = 0, alpha = 1 }
lurek.tween.tween(0.5, obj, { x = 300, alpha = 0 }, "cubicOut")
    :onComplete(function()
        print("done", obj.x)
    end)
```

---

### `lurek.tween.sequence() -> LuaTweenSequence`

Build a step-by-step animation chain. Inactive until `:start()`.

```lua
lurek.tween.sequence()
    :tween(0.3, sprite, { y = sprite.y - 20 }, "sineOut")
    :delay(0.1)
    :tween(0.3, sprite, { y = sprite.y    }, "sineIn")
    :start()
```

---

### `lurek.tween.parallel() -> LuaTweenParallel`

Animate multiple targets simultaneously; completes when all children finish.

```lua
lurek.tween.parallel()
    :tween(1.0, player,  { x = 400 }, "quadOut")
    :tween(1.0, bg,      { x = 200 }, "quadOut")
    :onComplete(function() print("all done") end)
    :start()
```

---

### `lurek.tween.delay(seconds[, callback])`

Standalone delay. Registered immediately.

```lua
lurek.tween.delay(2.0, function()
    print("2 seconds elapsed")
end)
```

---

### `lurek.tween.cancelAll()`

Cancel every active tracked tween/sequence/parallel. Fires `onCancel` for each.

---

### `lurek.tween.getActiveCount() -> number`

Number of currently active tracked objects.

---

### `lurek.tween.registerEasing(name: string, fn: function(t:number) -> number)`

Register a custom easing function. `t` is the raw normalised time [0, 1].

```lua
lurek.tween.registerEasing("spring", function(t)
    return 1 - math.cos(t * math.pi * 4.5) * (1 - t)
end)
lurek.tween.tween(1.0, obj, { x = 100 }, "spring")
```

---

### `lurek.tween.getEasingNames() -> table`

Returns an array-table of all easing names (built-in + custom).

---

## Built-in Easing Names

```
linear
quadIn    quadOut    quadInOut
cubicIn   cubicOut   cubicInOut
quartIn   quartOut   quartInOut
sineIn    sineOut    sineInOut
expoIn    expoOut    expoInOut
circIn    circOut    circInOut
elasticIn elasticOut
bounceIn  bounceOut
backIn    backOut
```

---

## Configuration

`conf.lua` (Modules table):

```lua
modules = {
    tween = true,   -- Enable lurek.tween (default: true)
}
```

`src/engine/config.rs`:

```rust
pub struct ModulesConfig {
    pub tween: bool,
}
```

---

## Tests

| Suite | Path | Count |
|---|---|---|
| Rust unit | `tests/rust/unit/tween_tests.rs` | 14 |
| Lua BDD | `tests/lua/unit/test_tween.lua` | ~50 |

Run:

```powershell
cargo test --test tween_tests -- --nocapture
cargo test lua_test_tween -- --nocapture
```

---

## Separation of Duties

Four distinct systems handle different animation needs — they do not overlap:

| System | Namespace | Source | What it does |
|---|---|---|---|
| **Property tweening** | `lurek.tween` | `src/tween/` | Animates numeric fields of Lua tables over time with callbacks, sequences, parallels, repeat/yoyo. The system covered by this spec. |
| **Frame animation** | `lurek.animation` | `src/animation/` | Plays sprite clip timelines (`AnimClip`) using frame indices and FPS. No numeric interpolation — switches frames discretely. |
| **Numeric interpolation** | `lurek.math.newTween` | `src/math/tween.rs` | Standalone clock-driven value interpolator with no auto-registration. The script manually calls `:update(dt)` and reads values with `:getValue()`. No callbacks or table fields. |
| **Skeletal animation** | `lurek.spine` | `src/spine/` | Hierarchical bone transforms (Spine-style): parent/child bones, world-transform propagation, slot management. No property tweening. |

## Cross-Module References

- **`src/math/easing.rs`** — supplies all easing function pointers used by `TweenState`
- **`src/math/tween.rs`** — separate low-level numeric interpolator; `lurek.math.newTween()` not auto-registered
- **`src/animation/`** — frame-based sprite animation; unrelated to property tweening
- **`src/spine/`** — skeletal bone hierarchy; unrelated to property tweening
- **`src/lua_api/tween_api.rs`** — thin-wrapper registration layer for this module

---

## Examples

`examples/tween.lua` — focused usage script demonstrating all major API features.

---

## Ideas / Not Implemented

- **Path-based tweening** — animate along a Bezier or polyline
- **Color field recognition** — auto-lerp Color userdata fields
- **Lua 5.4 `__index` proxy** — intercept property access on non-table targets
- See `ideas/tween.md` (original design doc) for extended feature ideas
