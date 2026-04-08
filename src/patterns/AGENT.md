# `patterns` — Agent Reference

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `luna.patterns`                                        |
| **Source**       | `src/patterns/`                                        |
| **Rust Tests**   | `tests/rust/unit/patterns_tests.rs`                    |
| **Lua Tests**    | `tests/lua/unit/test_patterns.lua`                     |
| **Architecture** | —                                                      |

## Purpose

The `patterns` module provides pure-Rust implementations of six classic game-programming design patterns for use in Lua scripts via `luna.patterns.*`. The six patterns are: `EventBus` (observer/publish-subscribe with priorities and one-shot listeners), `ObjectPool` (capacity-bounded ID-based pool with prewarm), `CommandStack` (undo/redo stack with batching), `ServiceLocator` (named service registry), `Factory` (named constructor registry with aliases), and `StateMachine` (FSM with guard-validated transitions and history). This module is **pure Rust** with no mlua dependency; all Lua plumbing (registry keys for callbacks) lives in `src/lua_api/patterns_api.rs`. It is gated by `modules.pipeline = true` in `conf.lua`.

**Disambiguation**: Use `luna.signal.newSignal()` for simple pub-sub with no ordering. Use `luna.patterns.newEventBus()` when priority ordering or one-shot callbacks are required. Use `luna.patterns.newServiceLocator()` for runtime service discovery; prefer plain Lua module tables for static registries known at init time. Use `luna.patterns.newStateMachine()` for game FSMs — not `automation.Simulator`'s internal 4-state playback FSM.

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

See [`specs/patterns.md`](../../../specs/patterns.md) for full architecture, type details, Lua API, examples, and notes.
