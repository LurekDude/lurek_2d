# `thread` — Agent Reference

| Property       | Value                                          |
|----------------|------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                |
| **Status**     | Implemented — Full                             |
| **Lua API**    | `lurek.thread`                                  |
| **Source**     | `src/thread/`                                  |
| **Rust Tests** | `tests/rust/unit/thread_tests.rs`              |
| **Lua Tests**  | `tests/lua/unit/test_thread.lua`               |
| **Architecture** | —                                            |

## Purpose

The `thread` module provides Lurek2D's only concurrency primitive: background Lua worker threads communicating through typed MPMC channels. It directly implements design constraint B-04 — concurrency lives in Rust threads; LuaJIT VMs cannot share state; cross-VM communication uses typed `Channel` objects.

## Source Files

| File         | Purpose                                                         |
|--------------|-----------------------------------------------------------------|
| `mod.rs`     | Module root — re-exports `channel` and `worker` submodules      |
| `channel.rs` | `ChannelValue` enum, `Channel` MPMC queue, `LuaChannel` UserData, conversion functions |
| `worker.rs`  | `ThreadState` enum, `LuaThread` struct, worker VM registration  |

## Key Types

| Type | Description |
|------|-------------|
| `ChannelValue` | Principal type for the `thread` module. |
| `Channel` | Principal type for the `thread` module. |
| `LuaChannel` | Principal type for the `thread` module. |
| `ThreadState` | Principal type for the `thread` module. |
| `LuaThread` | Principal type for the `thread` module. |

## Lua API Summary

| Function | Description |
|----------|-------------|
| `lurek.thread.newThread()` | See `docs/specs/thread.md`. |
| `lurek.thread.newChannel()` | See `docs/specs/thread.md`. |
| `lurek.thread.getChannel()` | See `docs/specs/thread.md`. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/thread.md`](../../docs/specs/thread.md)

_Update both this file **and** `docs/specs/thread.md` whenever source files, public types, or Lua bindings change._
