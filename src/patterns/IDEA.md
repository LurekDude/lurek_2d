# IDEA.md — `patterns` module

| Field       | Value           |
| ----------- | --------------- |
| Module      | `patterns`      |
| Path        | `src/patterns/` |
| Date        | 2026-04-18      |
| Plugin Tier | CORE-KEEP       |

---

## Mission Summary

Reusable game-programming pattern implementations shared across engine modules.
All types are pure data structures and algorithms with no render/audio/input
dependencies. Exposed to Lua via `lurek.patterns.*` in `lua_api/patterns_api.rs`.

## Existing Strengths

- 17 concrete pattern implementations covering GoF and game-specific patterns.
- Zero external dependencies — purely `std`.
- Clean single-file-per-pattern layout with comprehensive docstrings.
- `Blackboard` tracks per-key revisions for dirty-check optimization.
- `EventBus` supports wildcard subscribers, one-shot handlers, priority ordering.
- `StateMachine` includes full transition rules, guard conditions, and history.
- `RingBuffer` with numeric sum/average helpers for telemetry/metrics.
- `Funnel` aggregates damage/events with configurable time-window and max-entries.

## Gap List

1. `observer.rs` and `event_bus.rs` both implement pub/sub — consider merging or
   clearly documenting when to use which.
2. `bimap.rs` is a generic bidirectional map but only used for one mapping. May be
   over-abstracted vs. a simple pair of `HashMap`s.
3. `trie.rs` currently stores `(String, u64)` tuples — no generic key type.
4. No `PubSub` pattern with topic filtering (EventBus uses exact string match only).
5. `CommandStack` stores string labels, not closures — undo/redo requires Lua
   callback cooperation.

## Feature Ideas

1. **Behaviour Tree Node** — Add a `behaviour_tree.rs` for AI decision trees
   alongside the existing `state_machine`. Unreal Engine's BT editor is the
   reference model.
2. **Spatial Hash** — 2D spatial hashing for broad-phase collision or area queries.
   Box2D's broad-phase and Godot's `HashGrid` are references.
3. **Weighted Random Selector** — Loot-table / spawn-weight pattern. Diablo-style
   weighted random with depletion. Love2D community `lootTable` lib is a reference.

## Perf/Quality Ideas

- Benchmark `PriorityQueue` against `BinaryHeap` for pop-heavy workloads.
- Profile `EventBus::get_listeners` allocation pattern (returns `Vec<u64>` each call).
- Consider `SmallVec` for `ObserverHub.subscriptions` when typical subscriber count ≤4.

## Test Coverage Gaps

- Tests added this session: blackboard, collections, command_stack, event_bus,
  factory, funnel, mediator, object_pool, observer, priority_queue, ring,
  service_locator, simple_state, state_machine, strategy, throttle.
- Pre-existing: bimap, trie.
- All 17 data-structure files now have inline `#[cfg(test)]` modules.

## TODO(dedup): patterns ↔ ecs overlap

- `EventBus` + `ObserverHub` overlap with `Universe` observer/event capabilities.
  Consider having `Universe` delegate to `EventBus` internally.
- `Blackboard` overlaps with `Universe` component storage for AI state —
  evaluate whether Blackboard should be a component rather than a standalone
  pattern.

## TODO(dedup): patterns ↔ ai overlap

- `StateMachine` and `SimpleState` duplicate the FSM concept in `ai` module's
  FSM implementation. Consider a shared FSM core that both consume.

## TODO(helper):

- `PriorityQueue` sort-on-insert is O(n log n) per push — extract a thin
  `sorted_insert` helper that could be reused by `DepthSorter`.

## TODO(plugin):

- Patterns is CORE-KEEP — not a plugin candidate. All patterns are used
  internally by multiple engine modules.

## References

- `docs/specs/patterns.md`
- `src/lua_api/patterns_api.rs`
- GoF Design Patterns: https://refactoring.guru/design-patterns
- Game Programming Patterns: https://gameprogrammingpatterns.com/
