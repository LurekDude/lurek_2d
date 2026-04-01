# luna.pipeline — DAG-Based Pipeline Orchestrator

> **Lua namespace:** `luna.pipeline`
> **C++ module:** `src/modules/pipeline/`
> **Purpose:** A directed acyclic graph (DAG) pipeline system for composing multi-step workflows with conditions, delays, parallel execution, Lua code execution, and result aggregation. Useful for scripted automation, data processing pipelines, build systems, quest progression, and cutscene sequencing.

## Reimplementation Notes

- **Recommended strategy**: **Hybrid C++/Lua** — DAG scheduling and topological sort in C++, step execution callbacks in Lua
- A Pipeline is a DAG of PipelineStep nodes. Each step has inputs (dependencies) and an execution callback (Lua function).
- Steps execute only when all dependencies have completed successfully (or when their condition evaluates to true).
- Steps can run in parallel when they have no mutual dependencies. The runtime dispatches independent steps concurrently using coroutines (single-threaded cooperative concurrency, not OS threads).
- Each step produces a result (any Lua value) that downstream steps can read.
- **Conditions**: Steps can have a `condition` function that receives the pipeline context and returns a boolean. If false, the step is skipped (and dependents that require it are either skipped or proceed based on `optional` flag).
- **Delays**: Steps can specify a `delay` in seconds before execution begins (useful for sequencing, cutscenes, real-time pipelines).
- **Error handling**: Steps can have an `onError` callback. If a step fails, the pipeline either aborts (`"abort"` mode), continues (`"continue"` mode), or retries (`"retry"` mode with configurable attempts).
- **Serialization**: Pipelines can be serialized to/from JSON for storing workflows externally.
- All step names must be unique within a pipeline.
- Circular dependencies are rejected at construction time.

## Dependencies

- `luna.data` — for JSON serialization (optional)
- No external library dependencies

---

## Module Functions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `newPipeline` | `name?: string` | `Pipeline` | Create a new empty pipeline. |
| `newStep` | `name: string, fn: function` | `PipelineStep` | Create a pipeline step with a name and execution function `fn(context) → result`. |
| `fromJSON` | `json: string` | `Pipeline` | Deserialize a pipeline from JSON. Execution callbacks must be re-registered via `setCallback`. |
| `fromTable` | `definition: table` | `Pipeline` | Create a pipeline from a declarative table (see Declarative Format below). |

---

## Type: PipelineStep

A single unit of work in the pipeline DAG.

**Created by:** `luna.pipeline.newStep(name, fn)`

### Configuration

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getName` | — | `string` | Get step name. |
| `setCallback` | `fn: function` | — | Set execution function: `fn(context) → result`. |
| `setCondition` | `fn: function \| nil` | — | Set a condition function: `fn(context) → boolean`. Step is skipped if returns false. |
| `setDelay` | `seconds: number` | — | Set delay before execution (in seconds). Default 0. |
| `getDelay` | — | `number` | Get delay value. |
| `setTimeout` | `seconds: number` | — | Set maximum execution time. Step fails on timeout. Default 0 (no timeout). |
| `getTimeout` | — | `number` | Get timeout value. |
| `setRetryCount` | `count: number` | — | Set number of retry attempts on failure. Default 0 (no retry). |
| `getRetryCount` | — | `number` | Get retry count. |
| `setRetryDelay` | `seconds: number` | — | Set delay between retries (in seconds). Default 1. |
| `setOptional` | `optional: boolean` | — | If true, dependents proceed even if this step is skipped. Default false. |
| `isOptional` | — | `boolean` | Check if step is optional. |
| `setOnError` | `fn: function \| nil` | — | Set error handler: `fn(context, error_message)`. |
| `setData` | `key: string, value: any` | — | Set custom metadata on the step. |
| `getData` | `key: string` | `any \| nil` | Get custom metadata. |
| `setTag` | `tag: string` | — | Set a tag for grouping/filtering steps. |
| `getTag` | — | `string \| nil` | Get the step tag. |

### Dependency Management

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `dependsOn` | `step: PipelineStep \| string` | `PipelineStep` | Add a dependency. Returns self for chaining. |
| `getDependencies` | — | `{string, ...}` | Get names of all dependency steps. |
| `getDependencyCount` | — | `number` | Get number of dependencies. |

### State (read-only during execution)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getStatus` | — | `string` | Get current status: `"pending"`, `"waiting"`, `"running"`, `"completed"`, `"failed"`, `"skipped"`, `"cancelled"`. |
| `getResult` | — | `any \| nil` | Get the result value (set by callback return). |
| `getError` | — | `string \| nil` | Get the error message if failed. |
| `getDuration` | — | `number` | Get execution duration in seconds (0 if not run). |
| `getAttempt` | — | `number` | Get current attempt number (1-based). |

---

## Type: Pipeline

The DAG container and execution engine. Manages steps, validates the graph, and runs execution.

**Created by:** `luna.pipeline.newPipeline(name?)`

### Step Management

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addStep` | `step: PipelineStep` | `Pipeline` | Add a step to the pipeline. Returns self for chaining. |
| `removeStep` | `name: string` | — | Remove a step and all connections to/from it. |
| `getStep` | `name: string` | `PipelineStep \| nil` | Get a step by name. |
| `getSteps` | — | `{PipelineStep, ...}` | Get all steps. |
| `getStepCount` | — | `number` | Get number of steps. |
| `getStepsByTag` | `tag: string` | `{PipelineStep, ...}` | Get all steps with a given tag. |
| `clear` | — | — | Remove all steps. |

### Validation

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `validate` | — | `boolean, table<string>` | Validate the pipeline (unique names, no cycles, all dependencies exist). Returns `(ok, errors)`. |
| `getExecutionOrder` | — | `{string, ...}` | Get topologically sorted step names (execution order). |
| `getParallelGroups` | — | `table` | Get steps grouped by execution level: `{{step1, step2}, {step3}, ...}` where each group can run in parallel. |

### Execution

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `run` | `context?: table` | `PipelineResult` | Execute the pipeline synchronously. `context` is a shared table accessible by all steps. |
| `runAsync` | `context?: table` | — | Start asynchronous execution (uses `update(dt)` to advance). |
| `update` | `dt: number` | `boolean` | Advance async execution by `dt` seconds. Returns true when complete. |
| `cancel` | — | — | Cancel a running pipeline. Running steps complete; pending steps become `"cancelled"`. |
| `reset` | — | — | Reset all step states to `"pending"` for re-execution. |
| `isRunning` | — | `boolean` | Check if pipeline is currently executing. |
| `isComplete` | — | `boolean` | Check if pipeline has finished (all steps completed, failed, or skipped). |
| `setErrorMode` | `mode: string` | — | Set error handling mode: `"abort"` (stop on first failure), `"continue"` (run remaining steps). Default: `"abort"`. |
| `getErrorMode` | — | `string` | Get error handling mode. |

### Context & Results

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getResult` | — | `PipelineResult \| nil` | Get the result object after execution. |
| `getContext` | — | `table` | Get the shared context table. |
| `setOnComplete` | `fn: function \| nil` | — | Set completion callback: `fn(pipeline, result)`. |
| `setOnStepComplete` | `fn: function \| nil` | — | Set per-step completion callback: `fn(pipeline, step)`. |
| `setOnStepError` | `fn: function \| nil` | — | Set per-step error callback: `fn(pipeline, step, error)`. |

### Serialization

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `toJSON` | — | `string` | Serialize pipeline structure to JSON (step names, dependencies, metadata — not callbacks). |
| `toTable` | — | `table` | Serialize pipeline structure to a Lua table. |
| `getName` | — | `string` | Get pipeline name. |
| `setName` | `name: string` | — | Set pipeline name. |

---

## Type: PipelineResult

Summary of a pipeline execution.

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `isSuccess` | — | `boolean` | True if all non-optional steps completed without error. |
| `getCompletedCount` | — | `number` | Number of steps that completed successfully. |
| `getFailedCount` | — | `number` | Number of steps that failed. |
| `getSkippedCount` | — | `number` | Number of steps that were skipped. |
| `getCancelledCount` | — | `number` | Number of steps that were cancelled. |
| `getTotalDuration` | — | `number` | Total wall-clock execution time in seconds. |
| `getStepResults` | — | `table` | Map of step name → `{status, result, error, duration}`. |
| `getErrors` | — | `table` | List of `{stepName, error}` for all failed steps. |
| `getSummary` | — | `string` | Human-readable summary string. |

---

## Declarative Pipeline Format

Pipelines can be defined declaratively via a table:

```lua
local pipeline = luna.pipeline.fromTable({
    name = "build-pipeline",
    errorMode = "abort",
    steps = {
        {
            name = "validate",
            tag = "pre",
            fn = function(ctx) return validateInput(ctx.input) end,
        },
        {
            name = "transform",
            dependsOn = { "validate" },
            fn = function(ctx)
                return transformData(ctx.results.validate)
            end,
        },
        {
            name = "export_json",
            dependsOn = { "transform" },
            tag = "export",
            fn = function(ctx)
                return exportJSON(ctx.results.transform)
            end,
        },
        {
            name = "export_csv",
            dependsOn = { "transform" },
            tag = "export",
            optional = true,
            fn = function(ctx)
                return exportCSV(ctx.results.transform)
            end,
        },
    },
})
```

---

## Pipeline Context Table

The `context` table is shared across all steps and contains:

```lua
{
    -- User-provided data (anything you pass to run())
    input = { ... },

    -- Auto-populated by the runtime:
    results = {
        step_name = <return value of step callback>,
        ...
    },
    pipeline = <Pipeline object>,
    startTime = <timestamp>,
}
```

---

## Usage Example

### Basic Sequential Pipeline

```lua
local step1 = luna.pipeline.newStep("load", function(ctx)
    return luna.filesystem.read(ctx.input.file)
end)

local step2 = luna.pipeline.newStep("parse", function(ctx)
    return parseCSV(ctx.results.load)
end)
step2:dependsOn(step1)

local step3 = luna.pipeline.newStep("analyze", function(ctx)
    return analyzeData(ctx.results.parse)
end)
step3:dependsOn(step2)

local pipeline = luna.pipeline.newPipeline("data-pipeline")
pipeline:addStep(step1):addStep(step2):addStep(step3)

local result = pipeline:run({ input = { file = "data.csv" } })
if result:isSuccess() then
    print("Analysis complete: " .. tostring(result:getStepResults().analyze.result))
else
    for _, err in ipairs(result:getErrors()) do
        print("FAILED: " .. err.stepName .. " — " .. err.error)
    end
end
```

### Parallel Steps with Conditions

```lua
local fetch_a = luna.pipeline.newStep("fetch_a", function(ctx)
    return fetchFromServer("endpoint_a")
end)

local fetch_b = luna.pipeline.newStep("fetch_b", function(ctx)
    return fetchFromServer("endpoint_b")
end)

-- These run in parallel (no mutual dependency)
local merge = luna.pipeline.newStep("merge", function(ctx)
    return mergeResults(ctx.results.fetch_a, ctx.results.fetch_b)
end)
merge:dependsOn(fetch_a)
merge:dependsOn(fetch_b)

local export = luna.pipeline.newStep("export", function(ctx)
    return save(ctx.results.merge)
end)
export:dependsOn(merge)
export:setCondition(function(ctx)
    return ctx.results.merge ~= nil
end)

local pipeline = luna.pipeline.newPipeline("parallel-fetch")
pipeline:addStep(fetch_a):addStep(fetch_b):addStep(merge):addStep(export)
pipeline:setErrorMode("continue")

local result = pipeline:run()
print(result:getSummary())
```

### Async Pipeline with Delays

```lua
local pipeline = luna.pipeline.fromTable({
    name = "cutscene",
    steps = {
        { name = "fade_out",  fn = function() fadeScreen(0) end },
        { name = "wait",      dependsOn = {"fade_out"}, delay = 2.0, fn = function() end },
        { name = "move_char", dependsOn = {"wait"}, fn = function() moveCharTo(100, 200) end },
        { name = "dialogue",  dependsOn = {"move_char"}, delay = 0.5, fn = function() showDialogue("Hello!") end },
        { name = "fade_in",   dependsOn = {"dialogue"}, delay = 1.0, fn = function() fadeScreen(1) end },
    },
})

pipeline:runAsync()

function luna.update(dt)
    if not pipeline:isComplete() then
        pipeline:update(dt)
    end
end
```

### Error Handling with Retries

```lua
local unreliable = luna.pipeline.newStep("network_call", function(ctx)
    local ok, data = pcall(httpGet, "https://api.example.com/data")
    if not ok then error(data) end
    return data
end)
unreliable:setRetryCount(3)
unreliable:setRetryDelay(2.0)
unreliable:setTimeout(10.0)
unreliable:setOnError(function(ctx, err)
    print("Attempt " .. unreliable:getAttempt() .. " failed: " .. err)
end)

local pipeline = luna.pipeline.newPipeline()
pipeline:addStep(unreliable)
local result = pipeline:run()
```
