---
description: "Diagnose and fix threading issues in Lurek2D: Channel deadlocks, Worker lifecycle bugs, message delivery failures, or background Lua VM errors. Use when debugging thread-related bugs."
---

# Fix Threading Issue

## Prerequisites

- Read `src/thread/mod.rs` for Channel and Worker types
- Read `src/lua_api/thread_api.rs` for Lua bindings
- Read `tests/rust/unit/thread_tests.rs` for test patterns
- Read `src/thread/AGENT.md` for Channel/Worker patterns

## Steps

1. **Reproduce the issue**
   - Identify the symptom: deadlock, crash, missing messages, or unexpected behavior
   - Create a minimal Lua reproduction script
   - Check if the issue is consistent or timing-dependent

2. **Check Channel usage**
   - Channels are FIFO message queues — order must be preserved
   - Verify sender/receiver are not using the same channel in both directions
   - Check for missing `pop()` calls that could cause unbounded queue growth
   - Messages are cloned across thread boundaries — no sharing by reference

3. **Check Worker lifecycle**
   - Workers have **separate Lua VMs** — no SharedState sharing with main thread
   - Workers communicate only through Channels
   - Verify worker is started before sending messages to it
   - Check for panics in worker Lua code that silently kill the worker

4. **Verify thread safety**
   - No `unsafe` for thread state sharing — use Channels only
   - `Rc<RefCell<SharedState>>` is NOT thread-safe — never share across workers
   - Workers must not touch main-thread state (textures, renderer, audio)
   - Appropriate work for workers: pathfinding, AI computation, data processing

5. **Write regression test**
   - Add test to `tests/rust/unit/thread_tests.rs`
   - Test message round-trip: main → worker → main
   - Test worker completion/termination
   - Test edge cases: empty channels, multiple workers

## Acceptance Criteria

- [ ] Bug is reproducible with a test case
- [ ] Root cause identified and documented
- [ ] Fix applied with 0 clippy warnings
- [ ] Regression test passes
- [ ] No thread safety violations introduced
