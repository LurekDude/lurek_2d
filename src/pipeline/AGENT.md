# pipeline

## Module Info
- Module name: pipeline
- Module group: Edge/Integration
- Spec path: docs/specs/pipeline.md
- Lua API path(s): src/lua_api/pipeline_api.rs
- Rust test path(s): tests/rust/unit/pipeline_tests.rs
- Lua test path(s): tests/lua/unit/test_pipeline.lua

## Module Purpose

The pipeline module provides a DAG-based workflow engine for Lua and Rust callers that need ordered, dependency-aware multi-step execution. It exists to let games and tools describe work as named steps with dependencies, delays, retry policy, and error policy instead of hand-writing orchestration logic in ad hoc callback chains.

The module splits cleanly into data-model and execution-support pieces. Pipeline and PipelineStep describe the graph and per-step state, PipelineScheduler manages time-based readiness for delayed execution, and PipelineResult captures the final outcome of a run. That design keeps validation, scheduling, and result reporting inspectable and testable in isolation.

This module does not own the actual business work performed by each step. Callbacks, I/O, rendering, or gameplay logic belong to the code attached to the pipeline, while pipeline itself only validates the graph, computes execution order, tracks runtime state, and enforces error-handling rules.

## Files
- mod.rs: Module root that re-exports the pipeline graph, step, scheduler, and result types. It is the stable import surface for the orchestration engine.
- dag.rs: Defines Pipeline and the graph-level algorithms such as dependency validation, topological ordering, and parallel-group calculation. This is the core file for execution-order semantics.
- step.rs: Defines PipelineStep plus the step-level enums for status and error policy. It owns what one node in the workflow knows about dependencies, delays, retries, tags, and runtime outcome.
- result.rs: Defines PipelineResult and the overall PipelineStatus enum. This file turns a run into a structured success or failure record instead of a loose set of side effects.
- scheduler.rs: Defines PipelineScheduler, the time-based helper that determines which delayed steps are ready to run. It is the timing primitive for async or multi-frame pipeline execution.

## Key Types
- Pipeline: The top-level DAG container keyed by step name. It is the primary object to inspect when workflow validation, dependency ordering, or parallel grouping changes.
- PipelineStep: One named node in a workflow with dependency, delay, retry, metadata, and runtime-status fields. It is the most important per-step contract in the module.
- PipelineScheduler: Helper that tracks elapsed time and per-step delays to decide when steps become ready. It exists so delayed async execution does not have to be hand-managed elsewhere.
- PipelineResult: Structured summary of completed, failed, skipped, or cancelled work after execution. It is the main post-run artifact for tooling, diagnostics, and Lua-side introspection.
- ErrorMode: Pipeline-level policy for whether a failing step aborts the whole pipeline or allows execution to continue. It sets the graph-wide failure posture.
- ErrorPolicy: Step-level failure policy used when a single step needs behavior that differs from the pipeline default. It is the fine-grained override for retry or continue behavior.
- StepStatus: Enum that represents the lifecycle of one step from pending through running to a terminal state. It is the status vocabulary shared by scheduling, execution, and results.
- PipelineStatus: Overall run-status enum for a full pipeline. It is the coarse-grained answer to whether the workflow is still running, completed, failed, or cancelled.