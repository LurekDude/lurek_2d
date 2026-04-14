# pipeline

## General Info

- Module group: `Edge/Integration`
- Source path: `src/pipeline/`
- Lua API path(s): `src/lua_api/pipeline_api.rs`
- Primary Lua namespace: `lurek.pipeline`
- Rust test path(s): tests/rust/unit/pipeline_tests.rs
- Lua test path(s): tests/lua/unit/test_pipeline.lua

## Summary

The `pipeline` module provides Lurek2D's DAG-based workflow orchestration system for composing multi-step data processing sequences. It is a Feature Systems tier module designed for analytics pipelines, automated test sequences, boot initialization with dependency ordering, and complex mod-loading or asset-processing workflows.

`Pipeline` stores `PipelineStep` nodes and directed edges in a DAG. Each step has: a unique name, a `StepStatus` tracking its run state, an `ErrorPolicy` (FailFast — abort on first error; Continue — run all steps and collect errors; Retry(n) — retry up to n times before failing), and an optional timeout duration. Steps reference other steps by name to express dependencies; the DAG must be acyclic.

`Pipeline::run()` performs a topological sort, executes independent step groups in dependency order, and returns a `PipelineResult` carrying the final `PipelineStatus` (Success, PartialFailure, or Failed) plus per-step `StepStatus` records. `run_async()` dispatches step groups to a thread pool for parallel execution where dependencies allow.

`PipelineScheduler` wraps one or more pipelines with time-based triggering: an interval-based scheduler fires a pipeline repeatedly on a configurable period, and a delay-based scheduler fires once after a specified delay. `tick(dt)` is called each frame by the engine to advance the scheduler.

Step execution logic is provided by Lua callbacks; the pipeline module manages ordering and error handling only.

**Scope boundary**: Feature Systems tier. Depends on `math`, `runtime`. Lua bridge in `src/lua_api/pipeline_api.rs`.

## Files

- `dag.rs`: Defines Pipeline and the graph-level algorithms such as dependency validation, topological ordering, and parallel-group calculation. This is the core file for execution-order semantics.
- `mod.rs`: Module root that re-exports the pipeline graph, step, scheduler, and result types. It is the stable import surface for the orchestration engine.
- `result.rs`: Defines PipelineResult and the overall PipelineStatus enum. This file turns a run into a structured success or failure record instead of a loose set of side effects.
- `scheduler.rs`: Defines PipelineScheduler, the time-based helper that determines which delayed steps are ready to run. It is the timing primitive for async or multi-frame pipeline execution.
- `step.rs`: Defines PipelineStep plus the step-level enums for status and error policy. It owns what one node in the workflow knows about dependencies, delays, retries, tags, and runtime outcome.

## Types

- `ErrorMode` (`enum`, `dag.rs`): Pipeline-level policy for whether a failing step aborts the whole pipeline or allows execution to continue. It sets the graph-wide failure posture.
- `Pipeline` (`struct`, `dag.rs`): The top-level DAG container keyed by step name. It is the primary object to inspect when workflow validation, dependency ordering, or parallel grouping changes.
- `PipelineStatus` (`enum`, `result.rs`): Overall run-status enum for a full pipeline. It is the coarse-grained answer to whether the workflow is still running, completed, failed, or cancelled.
- `PipelineResult` (`struct`, `result.rs`): Structured summary of completed, failed, skipped, or cancelled work after execution. It is the main post-run artifact for tooling, diagnostics, and Lua-side introspection.
- `PipelineScheduler` (`struct`, `scheduler.rs`): Helper that tracks elapsed time and per-step delays to decide when steps become ready. It exists so delayed async execution does not have to be hand-managed elsewhere.
- `StepStatus` (`enum`, `step.rs`): Enum that represents the lifecycle of one step from pending through running to a terminal state. It is the status vocabulary shared by scheduling, execution, and results.
- `ErrorPolicy` (`enum`, `step.rs`): Step-level failure policy used when a single step needs behavior that differs from the pipeline default. It is the fine-grained override for retry or continue behavior.
- `PipelineStep` (`struct`, `step.rs`): One named node in a workflow with dependency, delay, retry, metadata, and runtime-status fields. It is the most important per-step contract in the module.

## Functions

- `ErrorMode::as_str` (`dag.rs`): Returns the mode as a lowercase string suitable for Lua.
- `ErrorMode::from_str_lua` (`dag.rs`): Parses a mode string.
- `Pipeline::new` (`dag.rs`): Creates a new empty pipeline with the given name.
- `Pipeline::add_step` (`dag.rs`): Adds a step to the pipeline.
- `Pipeline::remove_step` (`dag.rs`): Removes a step by name and strips any dependency references to it from other steps.
- `Pipeline::get_step` (`dag.rs`): Returns a shared reference to the step with the given name, if it exists.
- `Pipeline::get_step_mut` (`dag.rs`): Returns a mutable reference to the step with the given name, if it exists.
- `Pipeline::get_steps` (`dag.rs`): Returns an iterator over all steps in unspecified order.
- `Pipeline::get_step_count` (`dag.rs`): Returns the total number of steps in the pipeline.
- `Pipeline::clear` (`dag.rs`): Removes all steps from the pipeline.
- `Pipeline::validate` (`dag.rs`): Validates the pipeline and returns `(is_valid, list_of_error_messages)`.
- `Pipeline::get_execution_order` (`dag.rs`): Returns a topological ordering of step names using Kahn's algorithm.
- `Pipeline::get_parallel_groups` (`dag.rs`): Groups steps into parallel execution levels.
- `Pipeline::reset` (`dag.rs`): Resets the runtime state of every step in the pipeline.
- `Pipeline::are_deps_satisfied` (`dag.rs`): Checks whether all declared dependencies of `step_name` have reached a terminal-success state.
- `Pipeline::collect_result` (`dag.rs`): Aggregates per-step runtime data into a `PipelineResult` summary.
- `PipelineResult::new` (`result.rs`): Creates a new `PipelineResult` in the `Pending` state with all counters zeroed.
- `PipelineResult::is_success` (`result.rs`): Returns `true` if no steps failed.
- `PipelineResult::summary` (`result.rs`): Returns a human-readable one-line summary of this result.
- `PipelineScheduler::new` (`scheduler.rs`): Creates a new scheduler in a stopped, empty state.
- `PipelineScheduler::start` (`scheduler.rs`): Initialises the scheduler for a new pipeline run.
- `PipelineScheduler::update` (`scheduler.rs`): Advances all Waiting step timers by `dt` seconds and returns the names of steps whose delay has elapsed and that are ready to execute.
- `PipelineScheduler::mark_step_waiting` (`scheduler.rs`): Called when all dependencies of a step are done; starts its delay countdown.
- `PipelineScheduler::reset` (`scheduler.rs`): Stops the scheduler and clears all timers.
- `StepStatus::as_str` (`step.rs`): Returns the status as a lowercase string suitable for Lua.
- `PipelineStep::new` (`step.rs`): Creates a new step with the given name and all default values.
- `PipelineStep::reset` (`step.rs`): Resets all runtime state: status → `Pending`, attempt → 0, duration → 0.0, error_msg → None.

## Lua API Reference

- Binding path(s): `src/lua_api/pipeline_api.rs`
- Namespace: `lurek.pipeline`

### Module Functions
- `lurek.pipeline.newStep`: Creates a new pipeline step with the given name and optional callback.
- `lurek.pipeline.newPipeline`: Creates a new empty pipeline with the given name (defaults to "pipeline").
- `lurek.pipeline.fromTable`: Deserialises a pipeline from a definition table.

### `Pipeline` Methods
- `Pipeline:addStep`: Adds a step to the pipeline. Returns self for chaining.
- `Pipeline:removeStep`: Removes a step from the pipeline by name.
- `Pipeline:getStep`: Returns the LuaStep wrapper for the named step, or nil.
- `Pipeline:getSteps`: Returns a Lua array of all step wrappers in the pipeline.
- `Pipeline:getStepCount`: Returns the total number of steps.
- `Pipeline:getStepsByTag`: Returns a Lua array of all steps whose tag matches the given string.
- `Pipeline:clear`: Clears all steps from the pipeline.
- `Pipeline:validate`: Validates the pipeline DAG. Returns (ok, error_array).
- `Pipeline:getExecutionOrder`: Returns the topological execution order as an array of step names.
- `Pipeline:getParallelGroups`: Returns parallel execution groups as a nested array of step name arrays.
- `Pipeline:run`: Executes the pipeline synchronously in topological order.
- `Pipeline:runAsync`: Starts an async pipeline run. Steps are executed one-per-frame via update(dt).
- `Pipeline:update`: Advances the async pipeline by one tick. Returns true when all steps are done.
- `Pipeline:cancel`: Cancels all pending and waiting steps.
- `Pipeline:reset`: Resets all step states and clears the async context.
- `Pipeline:isRunning`: Returns true if the pipeline is currently running asynchronously.
- `Pipeline:isComplete`: Returns true if all steps have reached a terminal state.
- `Pipeline:setErrorMode`: Sets the pipeline error mode: "abort" or "continue".
- `Pipeline:getErrorMode`: Returns the current error mode as a string.
- `Pipeline:getResult`: Returns the current result table built from step states, or nil.
- `Pipeline:getContext`: Returns the stored async context table, or nil.
- `Pipeline:setOnComplete`: Sets the callback to invoke when the pipeline completes.
- `Pipeline:setOnStepError`: Sets the callback to invoke each time a step fails.
- `Pipeline:getName`: Returns the pipeline's name.
- `Pipeline:setName`: Sets the pipeline's name.
- `Pipeline:toTable`: Serialises the pipeline definition to a Lua table (no callbacks).
- `Pipeline:type`: Returns the type name of this object.
- `Pipeline:typeOf`: Returns true if this object is of the given type.

### `Step` Methods
- `Step:getName`: Returns the unique name of this step.
- `Step:setCallback`: Stores a Lua function as the execute callback for this step.
- `Step:setCondition`: Stores a Lua function (or nil) as the run-condition for this step.
- `Step:setDelay`: Sets the delay in seconds to wait after dependencies finish.
- `Step:getDelay`: Returns the configured delay in seconds.
- `Step:setTimeout`: Stores a timeout in seconds in the step's metadata.
- `Step:getTimeout`: Returns the timeout stored in metadata, or 0.0 if unset.
- `Step:setRetryCount`: Sets the maximum number of retry attempts on failure.
- `Step:getRetryCount`: Returns the configured retry count.
- `Step:setRetryDelay`: Sets the delay in seconds between retry attempts.
- `Step:setOptional`: Marks whether this step is optional (downstream steps continue on failure).
- `Step:isOptional`: Returns whether this step is marked as optional.
- `Step:setOnError`: Stores a Lua function (or nil) to call if this step fails.
- `Step:setData`: Stores an arbitrary string value under the given key in step metadata.
- `Step:getData`: Retrieves a metadata value by key, returning nil if not found.
- `Step:setTag`: Sets the tag on this step for grouping and filtering.
- `Step:getTag`: Returns the tag on this step, or nil if unset.
- `Step:dependsOn`: Adds a dependency on another step by name or PipelineStep. Returns self for chaining.
- `Step:getDependencies`: Returns the list of dependency step names.
- `Step:getDependencyCount`: Returns the number of declared dependencies.
- `Step:getStatus`: Returns the current execution status as a string.
- `Step:getError`: Returns the error message from the last failed attempt, or nil.
- `Step:getDuration`: Returns total seconds spent executing this step.
- `Step:getAttempt`: Returns the number of execution attempts so far.
- `Step:type`: Returns the type name "PipelineStep".
- `Step:typeOf`: Returns true when the given name matches "PipelineStep" or a parent type.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/pipeline/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
