# `thread` — Agent Reference

| Property       | Value                                          |
|----------------|------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                |
| **Status**     | Implemented — Full                             |
| **Lua API**    | `luna.thread`                                  |
| **Source**     | `src/thread/`                                  |
| **Rust Tests** | `tests/rust/unit/thread_tests.rs`              |
| **Lua Tests**  | `tests/lua/unit/test_thread.lua`               |
| **Architecture** | —                                            |

## Purpose

The `thread` module provides Luna2D's only concurrency primitive: background Lua worker threads communicating through typed MPMC channels. It directly implements design constraint B-04 — concurrency lives in Rust threads; LuaJIT VMs cannot share state; cross-VM communication uses typed `Channel` objects.

## Source Files

| File         | Purpose                                                         |
|--------------|-----------------------------------------------------------------|
| `mod.rs`     | Module root — re-exports `channel` and `worker` submodules      |
| `channel.rs` | `ChannelValue` enum, `Channel` MPMC queue, `LuaChannel` UserData, conversion functions |
| `worker.rs`  | `ThreadState` enum, `LuaThread` struct, worker VM registration  |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/thread.md`](../../specs/thread.md)

_Update both this file **and** `specs/thread.md` whenever source files, public types, or Lua bindings change._
