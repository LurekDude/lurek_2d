# `automation` — Agent Reference

| Property       | Value                                        |
|----------------|----------------------------------------------|
| **Tier**       | Tier 1 — Core Subsystems                     |
| **Status**     | Implemented — Full                           |
| **Lua API**    | `lurek.simulator`                             |
| **Source**      | `src/automation/`                            |
| **Rust Tests** | `tests/rust/unit/automation_tests.rs`        |
| **Lua Tests**  | `tests/lua/unit/test_automation.lua`         |
| **Architecture** | —                                          |

## Purpose

The `automation` module provides automated input simulation through timed step scripts. It is a Tier 2 Engine Extension that depends on `crate::engine` (Baseline) and `crate::event` (Tier 1). It does not depend on `crate::math`.

**Scope boundaries**: `automation.Simulator` replays recorded input scripts — it is not a general timed-callback system (use `lurek.time.newScheduler()` for that) and not a game FSM (use `lurek.patterns.newStateMachine()` for that). The Simulator's internal `PlaybackState` FSM (Idle/Running/Paused/Complete) is private and is not a substitute for `patterns::StateMachine`.

## Source Files

| File           | Purpose                                                                                |
|----------------|----------------------------------------------------------------------------------------|
| `mod.rs`       | Module root — re-exports `Script`, `Simulator`, `Step`, `Action`; module-level docs    |
| `script.rs`    | `Script` struct — named, time-sorted, `MAX_STEPS`-capped container of `Step` objects   |
| `simulator.rs` | `Simulator` struct — playback engine with named script registry and `PlaybackState` FSM |
| `step.rs`      | `Step` struct and `Action` enum — timed action records with 12 optional fields          |

## Key Types
| Type | Location | Purpose |
|------|----------|---------|
| \Simulator\ | \src/automation/mod.rs\ | Root simulation player managing script playback |
| \Script\ | \src/automation/mod.rs\ | Ordered sequence of automation steps |
| \Step\ | \src/automation/mod.rs\ | Single automation instruction |
| \Action\ | \src/automation/mod.rs\ | Low-level action variant executed by the simulator |

## Lua API Summary
| Function | Signature | Purpose |
|----------|-----------|---------|
| \lurek.simulator.load\ | \(path: string) → nil\ | Load a TOML automation script |
| \lurek.simulator.loadFromToml\ | \(name: string, toml: string) → nil\ | Parse and register a TOML script |
| \lurek.simulator.play\ | \(name: string) → nil\ | Start script playback |
| \lurek.simulator.stop\ | \() → nil\ | Halt playback |
| \lurek.simulator.isPlaying\ | \() → boolean\ | Check if a script is active |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/automation.md`](../../docs/specs/automation.md)

_Update both this file **and** `docs/specs/automation.md` whenever source files, public types, or Lua bindings change._
