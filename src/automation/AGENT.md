# `automation` — Agent Reference

| Property       | Value                                        |
|----------------|----------------------------------------------|
| **Tier**       | Tier 2 — Engine Extensions                   |
| **Status**     | Implemented — Full                           |
| **Lua API**    | `luna.simulator`                             |
| **Source**      | `src/automation/`                            |
| **Rust Tests** | `tests/rust/unit/automation_tests.rs`        |
| **Lua Tests**  | `tests/lua/unit/test_automation.lua`         |
| **Architecture** | —                                          |

## Purpose

The `automation` module provides automated input simulation through timed step scripts. It is a Tier 2 Engine Extension that depends on `crate::engine` (Baseline) and `crate::event` (Tier 1). It does not depend on `crate::math`.

**Scope boundaries**: `automation.Simulator` replays recorded input scripts — it is not a general timed-callback system (use `luna.time.newScheduler()` for that) and not a game FSM (use `luna.patterns.newStateMachine()` for that). The Simulator's internal `PlaybackState` FSM (Idle/Running/Paused/Complete) is private and is not a substitute for `patterns::StateMachine`.

## Source Files

| File           | Purpose                                                                                |
|----------------|----------------------------------------------------------------------------------------|
| `mod.rs`       | Module root — re-exports `Script`, `Simulator`, `Step`, `Action`; module-level docs    |
| `script.rs`    | `Script` struct — named, time-sorted, `MAX_STEPS`-capped container of `Step` objects   |
| `simulator.rs` | `Simulator` struct — playback engine with named script registry and `PlaybackState` FSM |
| `step.rs`      | `Step` struct and `Action` enum — timed action records with 12 optional fields          |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/automation.md`](../../specs/automation.md)

_Update both this file **and** `specs/automation.md` whenever source files, public types, or Lua bindings change._
