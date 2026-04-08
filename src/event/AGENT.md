# `event` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.signal`                                         |
| **Source**     | `src/event/`                                         |
| **Rust Tests** | `tests/rust/unit/event_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_event.lua`                      |
| **Architecture** | —                                                  |

## Purpose

The event module provides two complementary messaging primitives for Luna2D games: a FIFO **EventQueue** for pollable named events, and a handle-based **Signal** pub-sub dispatcher for callback-driven event handling. Together they give game scripts full control over inter-system communication without tight coupling.

**Namespace Note**: `luna.signal` combines two independent primitives: `push/poll/clear/wait` operate on the FIFO `EventQueue`; `newSignal()` creates pub-sub `Signal` dispatchers. These are independent — polling the queue does not affect Signal instances and vice versa. When priority-ordered listeners or one-shot auto-removal are needed, use `luna.patterns.newEventBus()` instead.

## Source Files

| File        | Purpose                                                         |
|-------------|-----------------------------------------------------------------|
| `mod.rs`    | `EventArg` enum, `Event` struct, `EventQueue` FIFO queue       |
| `signal.rs` | `Subscription` struct, `Signal` handle-based pub-sub dispatcher |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/event.md`](../../specs/event.md)

_Update both this file **and** `specs/event.md` whenever source files, public types, or Lua bindings change._
