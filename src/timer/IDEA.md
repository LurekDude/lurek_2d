# IDEA.md — `timer` module

> Migrated from `ideas/features/timer.md`.
> Status checked against `src/timer/` and `src/lua_api/timer_api.rs`.
> Lua namespace: `lurek.time`.

---

## Features

### ✅ DONE — Delta Time, FPS, Frame Count
**Source**: features/timer.md — Summary

`lurek.time.dt()`, `lurek.time.fps()`, `lurek.time.frameCount()`.

---

### ✅ DONE — Named Scheduled Events (`after`, `every`)
**Source**: features/timer.md — Summary

`lurek.time.after(delay, fn, name?)` — one-shot. `lurek.time.every(interval, fn, name?)` — repeating.
Named event cancel/list/check implemented.

---

### ✅ DONE — Time Scale (Slow-Mo / Fast-Forward)
**Source**: features/timer.md — Summary

`lurek.time.setTimeScale(scale)` — affects scheduled events and `dt()`.

---

### ✅ DONE — Performance Timing
**Source**: features/timer.md — Summary

`lurek.time.performanceTiming(fn)` → microseconds.

---

### ✅ DONE — Delta Time Smoothing
**Source**: features/timer.md — Feature Gaps #2 / Suggestions #1

No delta time smoothing. Hitches produce single large `dt` spikes that cause
entities to teleport. Running average over N frames prevents this.

```lua
lurek.time.setSmoothingFactor(5)  -- average over 5 frames
```

---

### ❌ TODO — Coroutine Wait Support
**Source**: features/timer.md — Feature Gaps #1 / Suggestions #2

No `waitSeconds(t)` / `waitFrames(n)` that yields current coroutine.
Without this, all sequential delayed logic requires nested callbacks.

```lua
-- With coroutine wait:
function lurek.ready()
  coroutine.wrap(function()
    lurek.time.waitSeconds(1.0)  -- yields, resumes after 1s
    spawn_enemy()
    lurek.time.waitSeconds(2.0)
    spawn_enemy()
  end)()
end
```

---

### ✅ DONE — Timer Chains (Sequential Delayed Calls)
**Source**: features/timer.md — Feature Gaps #6 / Suggestions #3

No `lurek.time.chain(...)` for sequential timer execution without callback nesting.

```lua
lurek.time.chain(
  {1.0, function() phase1() end},
  {2.0, function() phase2() end},
  {0.5, function() phase3() end}
)
```

---

### ✅ DONE — Pause / Resume Named Events
**Source**: features/timer.md — Feature Gaps #5 / Suggestions #4

Can cancel a named event but not pause/resume it. Game-level pause that suspends
specific timers without canceling them.

---

### ✅ DONE — Unpauseable Wall-Clock Timer (`afterReal`)
**Source**: features/timer.md — Feature Gaps #7 / Suggestions #5

No timer that ignores `timeScale` and runs on real wall-clock time.
Required for UI animations that should continue during game pause.

```lua
lurek.time.afterReal(0.5, function() show_pause_menu() end)
```

---

### 🤔 CONSIDER — Fixed Timestep Accumulator
**Source**: features/timer.md — Feature Gaps #3

No built-in fixed-timestep physics accumulator. Must implement manually in Lua.
Relevant if physics integration frequency need to be decoupled from render rate.
Low priority — rapier2d handles physics internally at a fixed step already.
