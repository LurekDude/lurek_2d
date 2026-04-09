# `patterns` — Agent Reference

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `lurek.patterns`                                        |
| **Source**       | `src/patterns/`                                        |
| **Rust Tests**   | `tests/rust/unit/patterns_tests.rs`                    |
| **Lua Tests**    | `tests/lua/unit/test_patterns.lua`                     |
| **Architecture** | —                                                      |

## Purpose

The `patterns` module provides pure-Rust implementations of six classic game-programming design patterns for use in Lua scripts via `lurek.patterns.*`. The six patterns are: `EventBus` (observer/publish-subscribe with priority ordering), `ObjectPool` (capacity-bounded value pool), `CommandStack` (undo/redo history with execute/undo function pairs), `ServiceLocator` (named service registry), `Factory` (named constructor registry with aliases), and `SimpleState` (FSM with enter/exit/update callbacks). This module is **pure Rust** with no mlua dependency; all Lua plumbing (registry keys for callbacks) lives in `src/lua_api/patterns_api.rs`. It is gated by `modules.pipeline = true` in `conf.lua`.

**Disambiguation**: Use `lurek.signal.newSignal()` for simple pub-sub with no ordering. Use `lurek.patterns.newEventBus()` when priority ordering is required. Use `lurek.patterns.newServiceLocator()` for runtime service discovery; prefer plain Lua module tables for static registries known at init time. Use `lurek.patterns.newSimpleState()` for game FSMs — not `automation.Simulator`'s internal 4-state playback FSM. The domain `StateMachine` type in `src/patterns/state_machine.rs` provides guard-validated transitions and is available from Rust, but the Lua API exposes `SimpleState` via `lurek.patterns.newSimpleState()` only.

## Source Files

| File                | Purpose                                                                          |
|---------------------|----------------------------------------------------------------------------------|
| `event_bus.rs`      | `EventBus`, `Subscription` — pub/sub event bus with priority and once semantics  |
| `object_pool.rs`    | `ObjectPool` — capacity-bounded ID-based idle/active object pool                |
| `command_stack.rs`  | `CommandStack`, `CommandEntry` — undo/redo stack with batch grouping             |
| `service_locator.rs`| `ServiceLocator` — named string-keyed service registry                           |
| `factory.rs`        | `Factory` — named type registry with alias resolution                            |
| `state_machine.rs`  | `StateMachine`, `TransitionRule`, `StateInfo` — validated FSM with history       |
| `mod.rs`            | Re-exports all public types                                                      |

## Full Specification

See [`docs/specs/patterns.md`](../../../docs/specs/patterns.md) for full architecture, type details, Lua API, examples, and notes.
