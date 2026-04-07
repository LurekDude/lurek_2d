# event — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/event.md`
**Files**: EventQueue FIFO + Signal pub-sub

## Purpose

Two event systems: `EventQueue` for FIFO event posting/polling, and `Signal` for pub-sub with named listeners. Also handles engine lifecycle events (quit, restart).

## Current Feature Summary

- `EventQueue`: FIFO with `post(name, data)` / `poll()` / `peek()` / `clear()`
- `Signal`: named listeners with `connect(name, fn)` / `emit(name, data)` / `disconnect(name)`
- Engine events: quit and restart lifecycle
- Event data: arbitrary Lua tables attached to events
- Multiple listener support per signal
- Event clearing and introspection

## Feature Gaps

1. **No event filtering**: Can't subscribe to a Signal with a filter predicate ("only Health events where value < 10").
2. **No typed event schemas**: Events are untyped Lua tables. No validation that "damage" events always have `{amount, source, type}` fields.
3. **No priority events**: All listeners fire in registration order. No priority levels.
4. **No deferred events**: Can't post an event to fire "next frame" or "after current event processing finishes." Useful to avoid recursive event chains.
5. **No event history/replay**: Can't record event streams for debugging or replay.
6. **No once-only listeners**: Can't register a listener that auto-disconnects after first invocation. Must manually disconnect in the callback.
7. **No wildcard subscriptions**: Can't subscribe to "all events matching `damage.*`" pattern.

## Structural Issues

- **Two event systems in one module**: EventQueue (queue-based) and Signal (pub-sub) are conceptually different. Having both in one module is fine for size, but the user must know which to use when.
- **Signal vs event callbacks**: Luna2D has `luna.load`, `luna.update`, `luna.draw` as engine callbacks, plus `Signal` for user events. The conceptual distinction could be clearer.

## Suggestions

1. **Add `once` listener**: `signal:once(name, fn)` — fires once, auto-disconnects. Very common pattern.
2. **Add deferred posting**: `queue:postDeferred(name, data)` — processes at start of next frame. Prevents re-entrant event chains.
3. **Add event history** (dev mode): `queue:enableHistory(maxEvents)` — stores last N events for debugging. Disabled in release.
4. **Consider merging into Signal only**: EventQueue is rarely needed when Signal exists. If both must stay, document clear use cases for each.
5. **Add wildcard subscriptions**: `signal:connect("damage.*", fn)` — pattern matching on event names.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| Event queue | ✅ | ❌ | ✅ (Runtime) | ✅ (Events) |
| Pub-sub | ✅ (Signal) | ❌ | ✅ (listeners) | ✅ (EventReader) |
| Once listeners | ❌ | N/A | ❌ | ❌ |
| Typed events | ❌ | N/A | ❌ | ✅ (generics) |
| Event filtering | ❌ | N/A | ❌ | ✅ (queries) |

## Priority

**LOW** — Event system is functional. `once` listeners and deferred posting are quality-of-life. No critical gaps.
