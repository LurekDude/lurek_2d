---
description: "Create a new engine event pattern."
---

# Create Event Pattern

## Goal
- ---.

## Inputs
- None.

## Steps
- **Choose the pattern**
- EventQueue: FIFO polling for deferred processing in lurek.update()
- Signal: Pub-sub for immediate multi-listener broadcast
- **Define event schema**
- Event name: lowercase descriptive string (e.g., "player_died")
- Arguments: EventArg types (Str, Num, Bool, Nil)
- Document the event contract (what args, when fired)
- **Implement integration**
- For engine events: push to EventQueue from engine/app.rs
- For game events: push from Lua via lurek.event.push(name, ...args)
- For signals: emit from Lua via lurek.event.emit(name, ...args)
- **Write tests**

## Success Criteria
- [ ] Event fires with correct name and arguments
- [ ] EventQueue maintains FIFO order
- [ ] Signal handles are unique and monotonic
- [ ] All EventArg types preserved through round-trip

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /create-event-pattern

## CAG Metadata
- **Mode**: agent
