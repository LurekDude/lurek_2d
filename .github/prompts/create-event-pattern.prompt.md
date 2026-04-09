---
description: "Create a new event type or signal pattern for decoupled game communication. Use when adding custom events, pub-sub signals, or establishing event-driven architecture. Produces EventQueue and Signal integration with tests."
---

# Create Event Pattern

## Prerequisites

- Read `src/event/mod.rs` and `src/event/signal.rs`
- Read `src/lua_api/event_api.rs` for Lua bindings
- Read `tests/rust/unit/event_tests.rs` for test patterns
- Load the `event-systems` skill

## Steps

1. **Choose the pattern**
   - EventQueue: FIFO polling for deferred processing in `lurek.update()`
   - Signal: Pub-sub for immediate multi-listener broadcast

2. **Define event schema**
   - Event name: lowercase descriptive string (e.g., `"player_died"`)
   - Arguments: EventArg types (Str, Num, Bool, Nil)
   - Document the event contract (what args, when fired)

3. **Implement integration**
   - For engine events: push to EventQueue from `engine/app.rs`
   - For game events: push from Lua via `lurek.signal.push(name, ...args)`
   - For signals: emit from Lua via `lurek.signal.emit(name, ...args)`

4. **Write tests**
   - Add to `tests/rust/unit/event_tests.rs`
   - Test FIFO ordering for EventQueue
   - Test subscription handle uniqueness for Signal
   - Test argument type preservation (Str, Num, Bool, Nil round-trip)

5. **Quality gate**
   - `cargo test event_tests` — all pass
   - `cargo clippy` — 0 warnings
   - `cargo fmt --check` — formatted

## Acceptance Criteria

- [ ] Event fires with correct name and arguments
- [ ] EventQueue maintains FIFO order
- [ ] Signal handles are unique and monotonic
- [ ] All EventArg types preserved through round-trip
