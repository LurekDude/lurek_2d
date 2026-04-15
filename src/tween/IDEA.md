# IDEA.md — `tween` module

> Migrated from `ideas/features/animation.md` (tween sections).
> Status checked against `src/tween/` and `src/lua_api/tween_api.rs`.
> Lua namespace: `lurek.tween`.

---

## Features

### ✅ DONE — `lurek.tween.tween(opts)` — Basic Interpolation
**Source**: features/animation.md — Tween section / tween_api.rs:86

Property interpolation from start/end values over a duration with easing function.
Returns `LuaTween` handle.

---

### ✅ DONE — Sequence (`lurek.tween.sequence(...)`)
**Source**: tween_api.rs:86, src/tween/handle.rs

Sequential chained tweens via `LuaTweenSequence`. `sequence:add(tween)`.

---

### ✅ DONE — Parallel (`lurek.tween.parallel(...)`)
**Source**: tween_api.rs:86, src/tween/handle.rs

Parallel simultaneous tweens via `LuaTweenParallel`.

---

### ✅ DONE — Delay
**Source**: tween_api.rs, line documentation: `delay`

`lurek.tween.delay(seconds)` — creates a no-op tween usable inside sequences.

---

### ✅ DONE — Pause / Resume
**Source**: tween_api.rs:35 — `fields.add_field_method_get("paused")`

`tween.paused = true/false` — tween-level pause control.

---

### ✅ DONE — Custom Easing Registration
**Source**: tween_api.rs:87 — `registerEasing`, `getEasingNames`

`lurek.tween.registerEasing(name, fn)` — plug in custom Lua easing curves.
`getEasingNames()` enumerates all built-in and custom easings.

---

### ✅ DONE — cancelAll / getActiveCount
**Source**: tween_api.rs:87

Global management utilities.

---

### ✅ DONE — Manual Update Required (`lurek.tween.update(dt)`)
**Source**: tween_api.rs:100

Must call `lurek.tween.update(dt)` from `lurek.process`. Engine does not auto-step.

---

### ❌ TODO — onComplete Callback on Tween Object
**Source**: features/animation.md — Tween section

No per-tween `onComplete` callback found in the API from Lua. Must use sequences with
side-effect tweens or manual polling (`tween:isDone()`).

```lua
t:onComplete(function() print("done") end)
```

---

### ✅ DONE — `tween.to(target, props, duration, easing)` — Object Property Sugar
**Source**: features/animation.md — Tween section / Suggestions

No in-place object property mutation (direct table field interpolation). Current API
requires using start/end values then manually applying to target. LÖVE2-style sugar:

```lua
lurek.tween.to(player, {x = 200, y = 300}, 0.5, "easeInOut")
```

---

### ❌ TODO — yoyo / pingpong Loop Mode
**Source**: features/animation.md — Tween section

No reverse-direction alternation on repeat. Must build manually with two tweens.

---

### ❌ TODO — Springs (Physics-Based Interpolation)
**Source**: features/animation.md — Tween section / Suggestions

No spring-based interpolation (stiffness, damping). Springs produce natural overshooting
motion that cannot be replicated with static easing functions.

```lua
lurek.tween.spring(target, {x = 200}, {stiffness=100, damping=10})
```

---

### 🔇 LOW — Coroutine yield inside tween sequence
**Source**: features/animation.md

No tween-sequence step that yields a coroutine until the tween finishes. Low priority
if timer coroutine wait is also missing (see `src/timer/IDEA.md`).
