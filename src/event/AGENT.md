# `event` � Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 � Core Engine Subsystems                      |
| **Status**     | Implemented � Full                                   |
| **Lua API**    | `lurek.signal`                                         |
| **Source**     | `src/event/`                                         |
| **Rust Tests** | `tests/rust/unit/event_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_event.lua`                      |
| **Architecture** | �                                                  |

## Purpose

The event module provides two complementary messaging primitives for Lurek2D games: a FIFO **EventQueue** for pollable named events, and a handle-based **Signal** pub-sub dispatcher for callback-driven event handling. Together they give game scripts full control over inter-system communication without tight coupling.

**Namespace Note**: `lurek.signal` combines two independent primitives: `push/poll/clear/wait` operate on the FIFO `EventQueue`; `newSignal()` creates pub-sub `Signal` dispatchers. These are independent � polling the queue does not affect Signal instances and vice versa. When priority-ordered listeners or one-shot auto-removal are needed, use `lurek.patterns.newEventBus()` instead.

## Source Files

| File              | Purpose                                                         |
|-------------------|-----------------------------------------------------------------|
| `mod.rs`          | `EventArg` enum, `Event` struct — module root and re-exports   |
| `event_queue.rs`  | `EventQueue` FIFO queue — push, drain, and clear operations     |
| `signal.rs`       | `Subscription` struct, `Signal` handle-based pub-sub dispatcher |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

� [`docs/specs/event.md`](../../docs/specs/event.md)

_Update both this file **and** `docs/specs/event.md` whenever source files, public types, or Lua bindings change._
