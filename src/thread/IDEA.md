# IDEA — `src/thread/`

> **This file is forward-looking.** It records ideas, not commitments.

---

## 1. Header

- **Module**: `thread`
- **Owner module path**: `src/thread/`
- **Last reviewed**: 2026-05-07 (UTC)
- **Reviewer agent**: `developer` · Session: `src-module-review-20260418`
- **Plugin tier candidacy**: `CORE-KEEP`
- **LOC (rust only)**: ~790 · **Public Lua surface**: `lurek.thread` — 12 fns / 3 userdata (Channel, Thread, Promise)
- **Inbound non-`lua_api` callers**: `app` (owns ThreadPool for background work)
- **Heavy dependencies**: `mlua` (spawns independent Lua VMs per worker)

## 2. Mission Summary

The `thread` module provides Lurek2D's background-thread system: `Channel` (MPMC inter-VM messaging), `LuaThread` (worker VM lifecycle), `ThreadPool` (reusable worker group), and `Promise` (one-shot async computation). It serves EngDev (parallel asset loading, compute offload), GameDev (background AI/pathfinding), and GameTest (concurrent test harnesses). It is NOT a coroutine or green-thread system — it spawns real OS threads.

## 3. Existing Strengths

- `Channel` is fully thread-safe (Mutex + Condvar) with blocking `demand()` and non-blocking `pop()`/`peek()`.
- `supply()` provides a lock-free "write only if empty" semantic useful for producer-limited patterns.
- `ChannelValue` covers all Lua primitives + serialized tables + raw bytes — sufficient for most cross-thread payloads.
- `Promise` provides a simple fire-and-forget computation model with error propagation.

## 4. Gap List

1. **[P2][GAP]** No channel backpressure — unbounded VecDeque can grow indefinitely if consumers lag.
   - Why: Memory exhaustion risk in producer-heavy workloads (e.g. AI decision results).
2. **[P3][GAP]** `LuaThread` exposes only a subset of `lurek.*` modules to workers — no discovery mechanism for which modules are available.
   - Why: GameDev must guess which APIs are worker-safe; no error until runtime.

## 5. Feature Ideas

1. **[P2][FEAT]** Bounded channel with optional max capacity — `push()` blocks or returns false when full.
   - Rationale: Prevents OOM in high-throughput producer patterns.
   - Effort: S · Risk: low.
2. **[P3][FEAT]** `Promise:chain(fn)` — pipe the result of one promise into another computation.
   - Rationale: Enables composable async pipelines for GameDev without nested callbacks.
   - Effort: M · Risk: med.
   - Competitor inspiration: [defold: "go.animate completion callbacks enable chaining" — https://defold.com/manuals/animation/]

## 6. Performance / Reliability / Quality Ideas

- **[P2][PERF]** `demand()` uses `Condvar::wait_timeout` per loop iteration — for very short timeouts this is fine, but for long blocking waits a single `wait` without timeout would save the syscall loop.
  - Hot path: `channel.rs:demand`.
- **[P3][QUAL]** `ThreadPool::join` locks each worker mutex sequentially — if one worker hangs, all subsequent joins are blocked.
  - File / type: `pool.rs:ThreadPool::join`.
  - Reason: robustness — a timeout or parallel join would prevent hangs.

## 7. Test Coverage Gaps

- **[P2][TEST-RUST]** Extend stress coverage for `Channel` with high-contention producer/consumer permutations (N producers, M consumers, mixed timeouts).
- **[P3][TEST-LUA]** Add worker-availability contract test that verifies documented worker-safe `lurek.*` subset.
- **[DONE][TEST-RUST]** Core thread behavior is covered in `tests/rust/unit/thread_tests.rs` (channel semantics, pool lifecycle, worker lifecycle, promise states).
- **[DONE][TEST-LUA]** Lua surface is covered in `tests/lua/unit/test_thread_core_unit.lua` (newThread/channel/promise round-trips).

## 8. TODO(dedup): Cross-Module Overlap

TODO(dedup): event::EventQueue — both Channel and EventQueue implement FIFO value queues; Channel is thread-safe, EventQueue is single-threaded. Consider whether EventQueue should wrap a Channel for simplicity.

## 9. TODO(helper): Engine-Level Helper Candidates

TODO(helper): `lurek.thread.async(fn)` — convenience wrapper that creates a Promise from a Lua closure, avoiding boilerplate `newThread` + channel plumbing.

## 10. TODO(plugin): Plugin Candidacy Proposal

TODO(plugin): CORE-KEEP — threading is a foundational service; asset loaders, AI workers, and compute shaders all depend on Channel and ThreadPool.
- **Extraction blockers**: `Channel` used by every cross-thread subsystem; `ThreadPool` in `SharedState`.
- **Heavy dep impact if extracted**: n/a.
- **Lua surface stability**: stable.
- **Migration step**: n/a.

## 11. References

- Module spec: [docs/specs/thread.md](../../docs/specs/thread.md)
- Lua API reference: [docs/api/lurek.md](../../docs/api/lurek.md)
- Plugin doc tier table: [plugins.md §5](../../docs/architecture/plugins.md#5-candidate-modules)
- Competitor links cited above: https://defold.com/manuals/animation/
- Authoring guide: [IDEA_AUTHORING.md](../../work/src-module-review-20260418/reports/IDEA_AUTHORING.md)
