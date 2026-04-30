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
- lurek.thread worker VMs are isolated Lua states, so shared mutable Lua state is not a valid design and any coordination must happen through explicit messages.
- src/thread/ already owns channels, promises, pools, and worker lifecycle primitives, so thread design should start from those building blocks before inventing new patterns.
- Use explicit message protocols and serializable payloads across workers; hidden conventions or ad hoc table shapes become hard to debug once several workers interact.
- Main-thread-only assumptions from render, input, windowing, and audio must not leak into worker flows; background tasks should focus on worker-safe computation or IO.
- Avoid blocking waits inside frame callbacks; prefer message polling, explicit completion states, or promise-style handoff so the main loop stays responsive.
- Shutdown, quit, cancellation, and backpressure paths should be explicit in both Lua and Rust designs because thread bugs often appear when the happy path ends.
- Messages should carry enough type or status information that a receiver can distinguish progress, success, failure, and termination without guessing from payload shape.
- Worker-safe module limits matter here: not every lurek.* surface is valid inside a worker, and designs should make that restriction obvious instead of relying on accidental success.
- Good thread flows in this repo are headless-friendly, pollable, and easy to reason about from content scripts without sharing hidden state.
- If a design wants to pass closures, userdata, or borrowed references across workers, the boundary is probably wrong.
## Companion File Index
- None.

## References
- src/thread/
- src/lua_api/thread_api.rs
- docs/specs/thread.md
