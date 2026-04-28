---
name: threading
description: "Load this skill when using lurek.thread, worker VMs, Channel messaging, or Lua work across threads. Skip it for Rust thread internals or general game scripts."
---
# threading

## Mission
- Own lurek.thread usage patterns, worker VM rules, and Channel-based coordination.

## When To Load
- Use worker VMs.
- Send messages across Channels.
- Design Lua work across threads.
- Review thread lifecycle and blocking behavior.

## When To Skip
- Rust thread internals.
- General game scripting.

## Domain Knowledge
- Treat each worker Lua VM as isolated state.
- Use Channel for cross-VM communication.
- Do not block the main thread with demand-style waits in frame callbacks.
- Keep quit and shutdown paths explicit for workers.
- Know which modules are worker-safe and which are main-thread only.
- Prefer clear message protocols over implicit shared-state assumptions.

## Companion File Index
- None.

## References
- src/thread/
- src/lua_api/thread_api.rs
- docs/specs/thread.md