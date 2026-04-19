---
description: "Diagnose and fix threading issues in Lurek2D: Channel deadlocks, Worker lifecycle bugs, message delivery failures, or background Lua VM e..."
agent: Debugger
---
# Fix Threading Issue

## Goal

Diagnose and fix threading issues in Lurek2D: Channel deadlocks, Worker lifecycle bugs, message delivery failures, or background Lua VM e... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `SharedState` — value supplied by the user invocation.

## Steps

1. **Reproduce the issue**
2. Identify the symptom: deadlock, crash, missing messages, or unexpected behavior
3. Create a minimal Lua reproduction script
4. Check if the issue is consistent or timing-dependent
5. **Check Channel usage**
6. Channels are FIFO message queues — order must be preserved
7. Verify sender/receiver are not using the same channel in both directions
8. Check for missing `pop()` calls that could cause unbounded queue growth
9. Messages are cloned across thread boundaries — no sharing by reference
10. **Check Worker lifecycle**
11. Workers have **separate Lua VMs** — no SharedState sharing with main thread
12. Workers communicate only through Channels

## Success Criteria

- [ ] Bug is reproducible with a test case
- [ ] Root cause identified and documented
- [ ] Fix applied with 0 clippy warnings
- [ ] Regression test passes
- [ ] No thread safety violations introduced

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/fix-threading-issue <SharedState>`

## CAG Metadata

- **Mode**: agent
- **Inputs required**: SharedState
