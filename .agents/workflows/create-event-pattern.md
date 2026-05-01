---
description: "Design and implement one event or message pattern in the engine using the existing event system."
---

# Create Event Pattern

## Goal
- Implement one bounded event or message pattern correctly using the existing event system.

## Inputs
- Event name and purpose.
- Publisher and subscriber relationship.
- Expected Lua visibility.
- Acceptance gate.

## Steps
1. Load rust-coding, lua-rust-bridge, and error-handling before acting.
2. Read src/event/, docs/specs/event.md, and the nearest existing event handler before editing.
3. Define the event type, add the publisher side, then wire the subscriber in Lua if visible.
4. Do not fire Lua callbacks from inside event dispatch loops; use deferred queues.
5. Add a test for the event delivery path and run cargo check.

## Success Criteria
- [ ] The event pattern matches the existing event system model.
- [ ] Lua callbacks are not fired during the dispatch loop.
- [ ] A test covers event delivery.
- [ ] cargo check passes.

## Anti-patterns
- Fire Lua callbacks inside an event dispatch loop.
- Use unwrap on event channel sends.
- Mix event and state mutation in the same callback.

## Example Invocation
- /create-event-pattern event=enemy_defeated publisher=physics subscriber=game_score
