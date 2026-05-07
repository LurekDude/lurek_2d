# pipeline

## General Info

- Module group: `Edge/Integration`
- Source path: `src/pipeline/`
- Lua API path(s): `src/lua_api/pipeline_api.rs`
- Primary Lua namespace: `lurek.pipeline`
- Rust test path(s): tests/rust/unit/pipeline_tests.rs
- Lua test path(s): tests/lua/unit/test_pipeline.lua

## Summary

The `pipeline` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `runtime`. Its responsibility should stay inside the Edge/Integration group rather than absorb behavior owned by those neighbors.

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
- `Pipeline::to_ascii_diagram` (`dag.rs`): Returns a multi-line ASCII string that visualises the pipeline DAG.
- `Pipeline::add_sub_pipeline` (`dag.rs`): Merges all steps from a sub-pipeline into this pipeline with a name prefix.
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
- `lurek.pipeline.newStep`: Creates a new pipeline step.
- `lurek.pipeline.newPipeline`: Creates a new empty pipeline.
- `lurek.pipeline.fromTable`: Deserialises a pipeline from a definition table.

### `LPipeline` Methods
- `LPipeline:addStep`: Adds a step to the pipeline.
- `LPipeline:removeStep`: Removes a step from the pipeline by name.
- `LPipeline:getStep`: Returns the step wrapper for the named step.
- `LPipeline:getSteps`: Returns all step wrappers in the pipeline.
- `LPipeline:getStepCount`: Returns the total number of steps.
- `LPipeline:getStepsByTag`: Returns all steps with a matching tag.
- `LPipeline:clear`: Clears all steps from the pipeline.
- `LPipeline:validate`: Validates the pipeline dependency graph.
- `LPipeline:getExecutionOrder`: Returns the topological execution order.
- `LPipeline:getParallelGroups`: Returns the pipeline's parallel execution groups.
- `LPipeline:run`: Executes the pipeline synchronously in topological order.
- `LPipeline:runAsync`: Starts an asynchronous pipeline run.
- `LPipeline:update`: Advances the asynchronous pipeline by one tick.
- `LPipeline:cancel`: Cancels all pending and waiting steps.
- `LPipeline:reset`: Resets all step states and clears async pipeline state.
- `LPipeline:isRunning`: Returns whether the pipeline is running asynchronously.
- `LPipeline:isComplete`: Returns whether all steps have reached a terminal state.
- `LPipeline:setErrorMode`: Sets the pipeline error mode.
- `LPipeline:getErrorMode`: Returns the current error mode.
- `LPipeline:getResult`: Returns the current result table.
- `LPipeline:getContext`: Returns the stored asynchronous context table.
- `LPipeline:setOnComplete`: Sets the callback invoked when the pipeline completes.
- `LPipeline:setOnStepComplete`: Sets the callback invoked when a step completes successfully.
- `LPipeline:setOnStepError`: Sets the callback invoked when a step fails.
- `LPipeline:getName`: Returns the pipeline name.
- `LPipeline:setName`: Renames the pipeline without changing its steps, dependencies, or current runtime state.
- `LPipeline:toTable`: Serialises the pipeline definition to a Lua table.
- `LPipeline:type`: Returns the Lua-visible type name for this pipeline.
- `LPipeline:addConditional`: Adds a conditional step to the pipeline.
- `LPipeline:onProgress`: Registers a callback invoked after every step.
- `LPipeline:toAscii`: Returns an ASCII diagram of the pipeline DAG.
- `LPipeline:addSubPipeline`: Inlines all steps from a sub-pipeline into this pipeline.
- `LPipeline:typeOf`: Returns whether the given type name matches this pipeline.

### `LPipelineStep` Methods
- `LPipelineStep:getName`: Returns the unique name of this step.
- `LPipelineStep:setCallback`: Stores the execute callback for this step.
- `LPipelineStep:setCondition`: Stores the run condition callback for this step.
- `LPipelineStep:setDelay`: Sets the delay to wait after dependencies finish.
- `LPipelineStep:getDelay`: Returns the configured delay in seconds.
- `LPipelineStep:setTimeout`: Stores a timeout value in this step's metadata.
- `LPipelineStep:getTimeout`: Returns the timeout stored in metadata.
- `LPipelineStep:setRetryCount`: Sets the maximum number of retry attempts after failure.
- `LPipelineStep:getRetryCount`: Returns the configured retry count.
- `LPipelineStep:setRetryDelay`: Sets the delay between retry attempts.
- `LPipelineStep:setOptional`: Sets whether this step is optional.
- `LPipelineStep:isOptional`: Returns whether this step is marked as optional.
- `LPipelineStep:setOnError`: Stores the error callback for this step.
- `LPipelineStep:setData`: Stores a metadata string value on this step.
- `LPipelineStep:getData`: Returns a metadata value by key.
- `LPipelineStep:setTag`: Sets the tag on this step.
- `LPipelineStep:getTag`: Returns the tag on this step.
- `LPipelineStep:dependsOn`: Adds a dependency on another step.
- `LPipelineStep:getDependencies`: Returns the dependency step names.
- `LPipelineStep:getDependencyCount`: Returns the number of declared dependencies.
- `LPipelineStep:getStatus`: Returns the current execution status.
- `LPipelineStep:getError`: Returns the error message from the last failed attempt.
- `LPipelineStep:getDuration`: Returns the total time spent executing this step.
- `LPipelineStep:getAttempt`: Returns the number of execution attempts so far.
- `LPipelineStep:type`: Returns the Lua-visible type name for this step.
- `LPipelineStep:typeOf`: Returns whether the given type name matches this step.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/pipeline/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
