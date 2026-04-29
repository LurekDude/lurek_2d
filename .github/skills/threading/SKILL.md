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
- lurek.thread worker VMs are isolated Lua states; shared mutable Lua state is not a valid design.
- src/thread/ owns channels, promises, pools, and worker lifecycle primitives.
- Use explicit message protocols and serializable payloads across workers.
- Main-thread-only assumptions from render, input, and audio must not leak into worker flows.
- Avoid blocking waits inside frame callbacks; prefer message polling or explicit completion states.
- Shutdown, quit, and backpressure paths should be explicit in both Lua and Rust designs.
- src/thread/ already exposes channels, promises, pools, and workers, so thread design should use existing primitives before inventing new message patterns.
- Worker-safe module limits and shutdown behavior are central because this repo treats Lua VMs as isolated units.
- The skill owns Lua-facing concurrency patterns, not raw Rust threading internals.
## Companion File Index
- None.

## References
- src/thread/
- src/lua_api/thread_api.rs
- docs/specs/thread.md
