# `pipeline` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Engine Extension                            |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.pipeline`                                      |
| **Source**      | `src/pipeline/`                                      |
| **Rust Tests** | `tests/rust/unit/pipeline_tests.rs`                  |
| **Lua Tests**  | `tests/lua/unit/test_pipeline.lua`                   |
| **Architecture** | —                                                  |

## Purpose

The `pipeline` module is a **DAG-based pipeline orchestrator** for composing multi-step
sequential and parallel workflows entirely in Lua. It is a Tier 2 Engine Extension that
depends only on `crate::engine` (for log messages) and the standard library — it does not
import `crate::math`, `mlua`, or any other Tier 1/Tier 2 module.

## Source Files

| File           | Purpose                                                                              |
|----------------|--------------------------------------------------------------------------------------|
| `mod.rs`       | Module root — declares submodules, re-exports `Pipeline`, `PipelineStep`, `PipelineResult`, `PipelineScheduler`, `ErrorMode`, `ErrorPolicy`, `PipelineStatus`, `StepStatus` |
| `dag.rs`       | DAG container (`Pipeline`) — step storage, topological sort (Kahn's algorithm), cycle detection, parallel group levelling, `ErrorMode` enum |
| `step.rs`      | Step definition (`PipelineStep`) — name, deps, delay, retry, optional, tag, metadata, runtime status tracking; `StepStatus` and `ErrorPolicy` enums |
| `result.rs`    | Execution outcome (`PipelineResult`) — aggregated completed/failed/skipped/cancelled lists, wall-clock duration, error pairs; `PipelineStatus` enum |
| `scheduler.rs` | Delay timer manager (`PipelineScheduler`) — per-step countdown, elapsed tracking, ready-step detection on `update(dt)` |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/pipeline.md`](../../docs/specs/pipeline.md)

_Update both this file **and** `docs/specs/pipeline.md` whenever source files, public types, or Lua bindings change._
