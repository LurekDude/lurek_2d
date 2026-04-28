---
description: "Fix a threading or Channel issue."
---

# Fix Threading Issue

## Goal
- Diagnose and fix threading issues in Lurek2D: Channel deadlocks, Worker lifecycle bugs, message delivery failures, or background Lua VM e...

## Inputs
- SharedState

## Steps
- **Reproduce the issue**
- Identify the symptom: deadlock, crash, missing messages, or unexpected behavior
- Create a minimal Lua reproduction script
- Check if the issue is consistent or timing-dependent
- **Check Channel usage**
- Channels are FIFO message queues order must be preserved
- Verify sender/receiver are not using the same channel in both directions
- Check for missing pop() calls that could cause unbounded queue growth
- Messages are cloned across thread boundaries no sharing by reference
- **Check Worker lifecycle**
- Workers have **separate Lua VMs** no SharedState sharing with main thread
- Workers communicate only through Channels

## Success Criteria
- [ ] Bug is reproducible with a test case
- [ ] Root cause identified and documented
- [ ] Fix applied with 0 clippy warnings
- [ ] Regression test passes
- [ ] No thread safety violations introduced

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /fix-threading-issue <SharedState>

## CAG Metadata
- **Mode**: agent
- **Inputs required**: SharedState
