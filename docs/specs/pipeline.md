# `pipeline` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Edge/Integration |
| **Status** | Implemented |
| **Lua API** | `lurek.pipeline` |
| **Source** | `src/pipeline/` |
| **Rust Tests** | tests/rust/unit/pipeline_tests.rs |
| **Lua Tests** | tests/lua/unit/test_pipeline.lua |
| **Architecture** | `docs/architecture/engine-architecture.md § Edge / Integration` |

---

## Summary

The pipeline module provides a DAG-based workflow engine for Lua and Rust callers that need ordered, dependency-aware multi-step execution. It exists to let games and tools describe work as named steps with dependencies, delays, retry policy, and error policy instead of hand-writing orchestration logic in ad hoc callback chains.

The module splits cleanly into data-model and execution-support pieces. Pipeline and PipelineStep describe the graph and per-step state, PipelineScheduler manages time-based readiness for delayed execution, and PipelineResult captures the final outcome of a run. That design keeps validation, scheduling, and result reporting inspectable and testable in isolation.

This module does not own the actual business work performed by each step. Callbacks, I/O, rendering, or gameplay logic belong to the code attached to the pipeline, while pipeline itself only validates the graph, computes execution order, tracks runtime state, and enforces error-handling rules.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Edge/Integration responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.pipeline.* (Lua API — src/lua_api/pipeline_api.rs)
    |
    v
src/pipeline/mod.rs
    |- dag.rs - dag
    |- result.rs - result
    |- scheduler.rs - scheduler
    |- step.rs - step
```

---

## Source Files

| File | Purpose |
|------|---------|
| `dag.rs` | Defines Pipeline and the graph-level algorithms such as dependency validation, topological ordering, and parallel-group calculation. This is the core file for execution-order semantics. |
| `mod.rs` | Module root that re-exports the pipeline graph, step, scheduler, and result types. It is the stable import surface for the orchestration engine. |
| `result.rs` | Defines PipelineResult and the overall PipelineStatus enum. This file turns a run into a structured success or failure record instead of a loose set of side effects. |
| `scheduler.rs` | Defines PipelineScheduler, the time-based helper that determines which delayed steps are ready to run. It is the timing primitive for async or multi-frame pipeline execution. |
| `step.rs` | Defines PipelineStep plus the step-level enums for status and error policy. It owns what one node in the workflow knows about dependencies, delays, retries, tags, and runtime outcome. |

---

## Submodules

### `pipeline::dag`

Defines Pipeline and the graph-level algorithms such as dependency validation, topological ordering, and parallel-group calculation. This is the core file for execution-order semantics.

- **`ErrorMode`** (enum): Determines how the pipeline responds when a step fails.
- **`Pipeline`** (struct): A directed acyclic graph (DAG) container that holds pipeline steps and their dependencies.

### `pipeline::result`

Defines PipelineResult and the overall PipelineStatus enum. This file turns a run into a structured success or failure record instead of a loose set of side effects.

- **`PipelineStatus`** (enum): Overall status of a pipeline execution.
- **`PipelineResult`** (struct): Aggregated outcome of a complete pipeline run.

### `pipeline::scheduler`

Defines PipelineScheduler, the time-based helper that determines which delayed steps are ready to run. It is the timing primitive for async or multi-frame pipeline execution.

- **`PipelineScheduler`** (struct): Tracks per-step delay timers and overall wall-clock time for a pipeline run.

### `pipeline::step`

Defines PipelineStep plus the step-level enums for status and error policy. It owns what one node in the workflow knows about dependencies, delays, retries, tags, and runtime outcome.

- **`StepStatus`** (enum): Execution status of a single pipeline step.
- **`ErrorPolicy`** (enum): Determines how the pipeline reacts when this step fails.
- **`PipelineStep`** (struct): A single node in a pipeline DAG representing one unit of work.

---

## Key Types

### Public Types

#### `Pipeline`

The top-level DAG container keyed by step name.

#### `PipelineStep`

One named node in a workflow with dependency, delay, retry, metadata, and runtime-status fields.

#### `PipelineScheduler`

Helper that tracks elapsed time and per-step delays to decide when steps become ready.

#### `PipelineResult`

Structured summary of completed, failed, skipped, or cancelled work after execution.

#### `ErrorMode`

Pipeline-level policy for whether a failing step aborts the whole pipeline or allows execution to continue.

#### `ErrorPolicy`

Step-level failure policy used when a single step needs behavior that differs from the pipeline default.

#### `StepStatus`

Enum that represents the lifecycle of one step from pending through running to a terminal state.

#### `PipelineStatus`

Overall run-status enum for a full pipeline.

---

## Lua API

Exposed under `lurek.pipeline.*` by `src/lua_api/pipeline_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.pipeline.newStep` | Creates a new pipeline step with the given name and optional callback. |
| `lurek.pipeline.newPipeline` | Creates a new empty pipeline with the given name (defaults to "pipeline"). |
| `lurek.pipeline.fromTable` | Deserialises a pipeline from a definition table. |

### `Pipeline` Methods

| Method | Description |
|--------|-------------|
| `pipeline:addStep(...)` | Adds a step to the pipeline. Returns self for chaining. |
| `pipeline:removeStep(...)` | Removes a step from the pipeline by name. |
| `pipeline:getStep(...)` | Returns the LuaStep wrapper for the named step, or nil. |
| `pipeline:getSteps(...)` | Returns a Lua array of all step wrappers in the pipeline. |
| `pipeline:getStepCount(...)` | Returns the total number of steps. |
| `pipeline:getStepsByTag(...)` | Returns a Lua array of all steps whose tag matches the given string. |
| `pipeline:clear(...)` | Clears all steps from the pipeline. |
| `pipeline:validate(...)` | Validates the pipeline DAG. Returns (ok, error_array). |
| `pipeline:getExecutionOrder(...)` | Returns the topological execution order as an array of step names. |
| `pipeline:getParallelGroups(...)` | Returns parallel execution groups as a nested array of step name arrays. |
| `pipeline:run(...)` | Executes the pipeline synchronously in topological order. |
| `pipeline:runAsync(...)` | Starts an async pipeline run. Steps are executed one-per-frame via update(dt). |
| `pipeline:update(...)` | Advances the async pipeline by one tick. Returns true when all steps are done. |
| `pipeline:cancel(...)` | Cancels all pending and waiting steps. |
| `pipeline:reset(...)` | Resets all step states and clears the async context. |
| `pipeline:isRunning(...)` | Returns true if the pipeline is currently running asynchronously. |
| `pipeline:isComplete(...)` | Returns true if all steps have reached a terminal state. |
| `pipeline:setErrorMode(...)` | Sets the pipeline error mode: "abort" or "continue". |
| `pipeline:getErrorMode(...)` | Returns the current error mode as a string. |
| `pipeline:getResult(...)` | Returns the current result table built from step states, or nil. |
| `pipeline:getContext(...)` | Returns the stored async context table, or nil. |
| `pipeline:setOnComplete(...)` | Sets the callback to invoke when the pipeline completes. |
| `pipeline:setOnStepError(...)` | Sets the callback to invoke each time a step fails. |
| `pipeline:getName(...)` | Returns the pipeline's name. |
| `pipeline:setName(...)` | Sets the pipeline's name. |
| `pipeline:toTable(...)` | Serialises the pipeline definition to a Lua table (no callbacks). |
| `pipeline:type(...)` | Returns the type name of this object. |
| `pipeline:typeOf(...)` | Returns true if this object is of the given type. |

### `Step` Methods

| Method | Description |
|--------|-------------|
| `step:getName(...)` | Returns the unique name of this step. |
| `step:setCallback(...)` | Stores a Lua function as the execute callback for this step. |
| `step:setCondition(...)` | Stores a Lua function (or nil) as the run-condition for this step. |
| `step:setDelay(...)` | Sets the delay in seconds to wait after dependencies finish. |
| `step:getDelay(...)` | Returns the configured delay in seconds. |
| `step:setTimeout(...)` | Stores a timeout in seconds in the step's metadata. |
| `step:getTimeout(...)` | Returns the timeout stored in metadata, or 0.0 if unset. |
| `step:setRetryCount(...)` | Sets the maximum number of retry attempts on failure. |
| `step:getRetryCount(...)` | Returns the configured retry count. |
| `step:setRetryDelay(...)` | Sets the delay in seconds between retry attempts. |
| `step:setOptional(...)` | Marks whether this step is optional (downstream steps continue on failure). |
| `step:isOptional(...)` | Returns whether this step is marked as optional. |
| `step:setOnError(...)` | Stores a Lua function (or nil) to call if this step fails. |
| `step:setData(...)` | Stores an arbitrary string value under the given key in step metadata. |
| `step:getData(...)` | Retrieves a metadata value by key, returning nil if not found. |
| `step:setTag(...)` | Sets the tag on this step for grouping and filtering. |
| `step:getTag(...)` | Returns the tag on this step, or nil if unset. |
| `step:dependsOn(...)` | Adds a dependency on another step by name or PipelineStep. Returns self for chaining. |
| `step:getDependencies(...)` | Returns the list of dependency step names. |
| `step:getDependencyCount(...)` | Returns the number of declared dependencies. |
| `step:getStatus(...)` | Returns the current execution status as a string. |
| `step:getError(...)` | Returns the error message from the last failed attempt, or nil. |
| `step:getDuration(...)` | Returns total seconds spent executing this step. |
| `step:getAttempt(...)` | Returns the number of execution attempts so far. |
| `step:type(...)` | Returns the type name "PipelineStep". |
| `step:typeOf(...)` | Returns true when the given name matches "PipelineStep" or a parent type. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.pipeline.
if lurek.pipeline then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 4 |
| `enum` | 4 |
| `fn` (Lua API) | 57 |
| **Total** | **65** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Edge/Integration to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/pipeline/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
