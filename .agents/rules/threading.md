---
description: "Load when using lurek.thread, worker VMs, Channel messaging, or Lua work across threads. Skip for Rust thread internals or general game scripts."
alwaysApply: false
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
- lurek.thread worker VMs are isolated Lua states; shared mutable Lua state is not a valid design.
- src/thread/ already owns channels, promises, pools, and worker lifecycle primitives.
- Use explicit message protocols and serializable payloads across workers.
- Main-thread-only assumptions from render, input, windowing, and audio must not leak into worker flows.
- Avoid blocking waits inside frame callbacks; prefer message polling, explicit completion states, or promise-style handoff.
- Shutdown, quit, cancellation, and backpressure paths should be explicit in both Lua and Rust designs.
- Messages should carry enough type or status information that a receiver can distinguish progress, success, failure, and termination.
- Not every lurek.* surface is valid inside a worker.
- Good thread flows in this repo are headless-friendly, pollable, and easy to reason about.
- If a design wants to pass closures, userdata, or borrowed references across workers, the boundary is probably wrong.

## References
- src/thread/
- src/lua_api/thread_api.rs
- docs/specs/thread.md
