---
description: ﻿---.
agent: Developer
---
# Create Event Pattern

## Goal

﻿---. The prompt finishes when every Success Criteria item below is checked.

## Inputs

- (none) — this prompt takes no required arguments.

## Steps

1. **Choose the pattern**
2. EventQueue: FIFO polling for deferred processing in `lurek.update()`
3. Signal: Pub-sub for immediate multi-listener broadcast
4. **Define event schema**
5. Event name: lowercase descriptive string (e.g., `"player_died"`)
6. Arguments: EventArg types (Str, Num, Bool, Nil)
7. Document the event contract (what args, when fired)
8. **Implement integration**
9. For engine events: push to EventQueue from `engine/app.rs`
10. For game events: push from Lua via `lurek.signal.push(name, ...args)`
11. For signals: emit from Lua via `lurek.signal.emit(name, ...args)`
12. **Write tests**

## Success Criteria

- [ ] Event fires with correct name and arguments
- [ ] EventQueue maintains FIFO order
- [ ] Signal handles are unique and monotonic
- [ ] All EventArg types preserved through round-trip

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/create-event-pattern`

## CAG Metadata

- **Mode**: agent
