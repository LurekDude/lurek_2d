# `src/thread/` — Thread Infrastructure

## Purpose

Inter-thread communication and background Lua worker threads.
Provides safe data passing between the main Lua VM and background Rust threads.

## Architecture

```
Lua (main thread)
  └── LuaChannel (send/receive)
        └── Worker (background thread, optionally runs Lua)
```

## Files

| File | Purpose |
|------|---------|
| `channel.rs` | `LuaChannel` — MPSC channel exposed to Lua |
| `worker.rs` | `Worker` — background thread that can run Lua scripts |

## Tier

**Tier 2** (generic extension). Must not import from Tier 3 modules.
