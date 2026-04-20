# IDEA — `src/timer/`

> **This file is forward-looking.** It records ideas, not commitments.

---

## 1. Header

- **Module**: `timer`
- **Owner module path**: `src/timer/`
- **Last reviewed**: 2026-04-18 (UTC)
- **Reviewer agent**: `developer` · Session: `src-module-review-20260418`
- **Plugin tier candidacy**: `CORE-KEEP`
- **LOC (rust only)**: ~610 · **Public Lua surface**: `lurek.timer` — 22 fns / 0 userdata
- **Inbound non-`lua_api` callers**: `app` (ticks clock), `tween` (reads delta)
- **Heavy dependencies**: `none`

## 2. Mission Summary

The `timer` module owns time measurement (`Clock`) and deferred/repeating event scheduling (`Scheduler`). It serves EngDev (frame timing, average delta), GameDev (after/every callbacks, named timers, time-scale), and GameTest (deterministic dt injection). It is NOT an animation timeline — that belongs to `tween`.

## 3. Existing Strengths

- `Clock` with ring-buffer average delta gives stable FPS readings without allocation.
- `Scheduler` supports one-shot (`after`), repeating (`every`), named timers, pause/resume, time-scale — covers 95% of game-timer use cases.
- Named timer replacement semantics (`after_named` replaces existing) prevent timer stacking bugs.
- Comprehensive Rust test suite (24+ tests covering all scheduler features).

## 4. Gap List

1. ~~**[P3][GAP]** No `after_frames(n)` — scheduling by frame count (useful for VFX sequencing at fixed step).~~ ✅ **DONE** — Added `after_frames(n)`, `every_frames(n, count)`, and `update_frames()` to `Scheduler` + `lurek.time` Lua bindings.
   - ~~Why: GameDev must convert frame count to seconds manually, which breaks if `time_scale` changes.~~

## 5. Feature Ideas

1. ~~**[P3][FEAT]** `after_frames(n)` — fire after N update ticks rather than elapsed seconds.~~ ✅ **DONE** — Implemented as `Scheduler::after_frames`, `every_frames`, `update_frames`; Lua: `scheduler:afterFrames(n, fn)`, `scheduler:everyFrames(n, fn, count?)`, `scheduler:updateFrames()`.
   - ~~Rationale: Deterministic frame-count scheduling is simpler for VFX chains and cutscenes.~~
   - Effort: S · Risk: low.

## 6. Performance / Reliability / Quality Ideas

- **[P3][PERF]** `Scheduler::update` linear scan — O(n) per frame. Fine for ≤100 timers, but SlotMap or sorted-by-remaining list would scale better.
  - Hot path: `scheduler.rs:update`.
  - Verification: benchmark with 1000 active timers.

## 7. Test Coverage Gaps

- ~~**[P2][TEST-LUA]** Add Lua BDD test for `lurek.timer.afterNamed` replacement semantics.~~ ✅ **DONE** — Added `afterNamed replacement` describe block in `tests/lua/unit/test_timer.lua`.
- **[P3][TEST-RUST]** Stress test `Scheduler` with 1000 timers to verify no allocation spike.

## 8. TODO(dedup): Cross-Module Overlap

TODO(dedup): tween::TweenManager — both `Scheduler` and `TweenManager` track "remaining time to fire" lists. Consider whether `TweenManager` should delegate timing to `Scheduler` internally.

## 9. TODO(helper): Engine-Level Helper Candidates

~~TODO(helper): `lurek.timer.delay(seconds)` — coroutine-based yield-for-duration sugar wrapping `after` + resume, for sequential cutscene scripting.~~ ✅ **DONE** — Added `lurek.time.delay(seconds)` as a semantic alias for `waitSeconds` in `src/lua_api/timer_api.rs`.

## 10. TODO(plugin): Plugin Candidacy Proposal

TODO(plugin): CORE-KEEP — every game loop needs a clock and scheduler; extraction would force every game to reinvent frame timing.
- **Extraction blockers**: `Clock` drives `app` frame loop; `Scheduler` in `SharedState`.
- **Heavy dep impact if extracted**: n/a.
- **Lua surface stability**: stable.
- **Migration step**: n/a.

## 11. References

- Module spec: [docs/specs/timer.md](../../docs/specs/timer.md)
- Lua API reference: [docs/API/lua-api.md#timer](../../docs/API/lua-api.md)
- Plugin doc tier table: [plugins.md §5](../../docs/architecture/plugins.md#5-candidate-modules)
- Competitor links cited above: https://docs.godotengine.org/en/stable/classes/class_SceneTreeTimer.html
- Authoring guide: [IDEA_AUTHORING.md](../../work/src-module-review-20260418/reports/IDEA_AUTHORING.md)
