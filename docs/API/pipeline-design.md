# pipeline — DAG-Based Pipeline Orchestrator

> **Lua namespace:** `luna.pipeline`
> **Rust module:** `src/pipeline/` (Tier 2 engine extension)
> **Purpose:** A directed acyclic graph (DAG) pipeline system for composing multi-step workflows with conditions, delays, parallel execution, and result aggregation. Useful for scripted automation, data processing, build-like tasks, quest progression, and cutscene sequencing.

## Architecture Notes

- A `Pipeline` is a DAG of `PipelineStep` nodes; each step has dependencies and an execution callback (`fn(ctx) → result`).
- Steps execute only when all dependencies have completed (or are skipped with `optional = true`).
- Independent steps — those with no mutual dependency — form parallel groups; `getParallelGroups()` exposes these groups. Execution in `run()` is single-threaded and synchronous.
- Topological sort uses Kahn's algorithm, implemented in `src/pipeline/dag.rs`.
- `run(ctx?)` is fully synchronous and blocks until completion.
- `runAsync(ctx?)` + `update(dt)` provides frame-driven async execution suitable for cutscenes and timed sequences.
- All step callbacks are Lua functions stored internally via `LuaRegistryKey`; they are **not** serialized.
- Results flow through a shared context table: `ctx.results[step_name]` holds the return value of each completed step.
- Error modes: `"abort"` (default — stop the pipeline on the first failure) and `"continue"` (run remaining independent steps regardless of failures).
- Optional steps: when skipped, dependents that have no other unmet dependencies proceed normally.
- Circular dependencies and unknown dependency names are rejected at validation time; call `validate()` to check before `run()`.

## Dependencies

- `src/pipeline/dag.rs` (topological sort — internal, no external crate dependencies)
- No inter-Tier-2 imports; this module does not depend on `crate::graph` or any other Tier 2 module.

## Implementation Status

| | |
|---|---|
| **Tier** | Tier 2 — Reusable Engine Extension |
| **Rust** | `src/pipeline/mod.rs` — fully implemented |
| **Lua bindings** | `src/lua_api/pipeline_api.rs` — fully implemented |
| **Example** | See `tests/lua/unit/test_pipeline.lua` for usage examples |

---

## Module Functions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `newPipeline` | `name?: string` | `Pipeline` | Create a new empty pipeline |
| `newStep` | `name: string, fn?: function` | `PipelineStep` | Create a step with a name and optional callback `fn(ctx) → result` |
| `fromTable` | `definition: table` | `Pipeline` | Create a pipeline from a declarative table (see [Declarative Format](#declarative-format)) |

---

## Type: PipelineStep

A single unit of work in the pipeline DAG.

**Created by:** `luna.pipeline.newStep(name, fn?)`

### Configuration

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getName` | — | `string` | Get step name |
| `setCallback` | `fn: function` | — | Set execution function: `fn(ctx) → result` |
| `setCondition` | `fn: function \| nil` | — | Set condition function: `fn(ctx) → boolean`. Step is skipped if it returns false |
| `setDelay` | `seconds: number` | — | Set delay in seconds before execution begins. Default 0 |
| `getDelay` | — | `number` | Get delay value |
| `setTimeout` | `seconds: number` | — | Set maximum execution time in seconds. Step fails on timeout. Default 0 (no timeout) |
| `getTimeout` | — | `number` | Get timeout value |
| `setRetryCount` | `count: number` | — | Set number of retry attempts on failure. Default 0 |
| `getRetryCount` | — | `number` | Get retry count |
| `setRetryDelay` | `seconds: number` | — | Set delay between retries in seconds. Default 1 |
| `setOptional` | `optional: boolean` | — | If true, dependent steps proceed even if this step is skipped. Default false |
| `isOptional` | — | `boolean` | Check if step is optional |
| `setOnError` | `fn: function \| nil` | — | Set error handler: `fn(ctx, error_message)` |
| `setData` | `key: string, value: any` | — | Attach custom metadata to the step |
| `getData` | `key: string` | `any \| nil` | Get custom metadata by key |
| `setTag` | `tag: string` | — | Set a tag for grouping or filtering steps |
| `getTag` | — | `string \| nil` | Get the step tag |

### Dependency Management

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `dependsOn` | `step: PipelineStep \| string` | `PipelineStep` | Add a dependency. Returns self for chaining |
| `getDependencies` | — | `{string, ...}` | Get names of all dependency steps |
| `getDependencyCount` | — | `number` | Get number of direct dependencies |

### State (read-only during execution)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getStatus` | — | `string` | Current status: `"pending"`, `"waiting"`, `"running"`, `"completed"`, `"failed"`, `"skipped"`, or `"cancelled"` |
| `getResult` | — | `any \| nil` | Return value produced by the callback (nil if not completed) |
| `getError` | — | `string \| nil` | Error message if the step failed |
| `getDuration` | — | `number` | Execution duration in seconds (0 if not yet run) |
| `getAttempt` | — | `number` | Current attempt number, 1-based |

---

## Type: Pipeline

The DAG container and execution engine. Manages steps, validates the graph, and runs execution.

**Created by:** `luna.pipeline.newPipeline(name?)`

### Step Management

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addStep` | `step: PipelineStep` | `Pipeline` | Add a step. Returns self for chaining |
| `removeStep` | `name: string` | — | Remove a step and all dependency edges to/from it |
| `getStep` | `name: string` | `PipelineStep \| nil` | Look up a step by name |
| `getSteps` | — | `{PipelineStep, ...}` | Get all steps as an ordered table |
| `getStepCount` | — | `number` | Number of steps in the pipeline |
| `getStepsByTag` | `tag: string` | `{PipelineStep, ...}` | Get all steps with the given tag |
| `clear` | — | — | Remove all steps |

### Validation

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `validate` | — | `boolean, {string, ...}` | Validate the graph: unique names, no cycles, all dependencies exist. Returns `(ok, errors)` |
| `getExecutionOrder` | — | `{string, ...} \| nil, string` | Topologically sorted step names, or `nil, error` if the graph is invalid |
| `getParallelGroups` | — | `{{string,...},...} \| nil, string` | Steps grouped by execution level: all steps in one sub-table are independent and could run in parallel |

### Execution

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `run` | `ctx?: table` | `PipelineResult` | Execute synchronously. `ctx` is the shared context table; `ctx.results` is populated as steps complete |
| `runAsync` | `ctx?: table` | — | Begin frame-driven async execution. Advance with `update(dt)` each frame |
| `update` | `dt: number` | `boolean` | Advance async execution by `dt` seconds. Returns true when the pipeline is complete |
| `cancel` | — | — | Cancel a running pipeline; in-flight steps complete, pending steps become `"cancelled"` |
| `reset` | — | — | Reset all step states to `"pending"` so the pipeline can be re-executed |
| `isRunning` | — | `boolean` | True while the pipeline is executing |
| `isComplete` | — | `boolean` | True after all steps have reached a terminal state |
| `setErrorMode` | `mode: string` | — | Set error handling mode: `"abort"` or `"continue"`. Default `"abort"` |
| `getErrorMode` | — | `string` | Get current error mode |
| `getName` | — | `string` | Get pipeline name |
| `setName` | `name: string` | — | Set pipeline name |

### Callbacks

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setOnComplete` | `fn: function \| nil` | — | Called when the pipeline finishes: `fn(pipeline, result)` |
| `setOnStepComplete` | `fn: function \| nil` | — | Called after each step completes: `fn(pipeline, step)` |
| `setOnStepError` | `fn: function \| nil` | — | Called when a step fails: `fn(pipeline, step, error)` |

### Serialization

Callbacks are **not** serialized — only structure and metadata.

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `toTable` | — | `table` | Serialize pipeline structure to a Lua table: `{name, errorMode, steps=[{name, tag, dependencies, metadata},...]}` |

---

## Type: PipelineResult

Returned by `run()` and accessible via `pipeline:getResult()` after async execution.

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `isSuccess` | — | `boolean` | True if all non-optional steps completed without error |
| `getCompletedCount` | — | `number` | Number of steps that completed successfully |
| `getFailedCount` | — | `number` | Number of steps that failed |
| `getSkippedCount` | — | `number` | Number of steps that were skipped |
| `getCancelledCount` | — | `number` | Number of steps that were cancelled |
| `getTotalDuration` | — | `number` | Total wall-clock execution time in seconds |
| `getStepResults` | — | `table` | Map of `step_name → {status, result, error, duration}` for every step |
| `getErrors` | — | `{...}` | List of `{stepName, error}` pairs for all failed steps |
| `getSummary` | — | `string` | Human-readable summary string |

---

## Pipeline Context Table

The `ctx` table passed to `run(ctx?)` (or `runAsync(ctx?)`) is shared across all step callbacks.

```lua
{
    -- Any fields you provide:
    input = { file = "data.csv" },

    -- Auto-populated by the runtime as steps complete:
    results = {
        step_name = <return value of that step's callback>,
    },

    pipeline  = <Pipeline object>,
    startTime = <timestamp>,
}
```

Step callbacks read upstream results via `ctx.results.step_name`.

---

## Declarative Format

`luna.pipeline.fromTable` accepts a definition table instead of manual `newStep` / `addStep` calls:

```lua
local pipeline = luna.pipeline.fromTable({
    name      = "build",
    errorMode = "abort",
    steps = {
        {
            name = "validate",
            fn   = function(ctx) return validateInput(ctx.input) end,
        },
        {
            name      = "transform",
            dependsOn = { "validate" },
            fn        = function(ctx)
                return transformData(ctx.results.validate)
            end,
        },
        {
            name      = "export",
            dependsOn = { "transform" },
            optional  = true,
            fn        = function(ctx) return "done" end,
        },
    },
})
```

Each step entry may include: `name`, `fn`, `dependsOn` (table of names), `tag`, `optional`, `delay`, `retryCount`, `retryDelay`, `timeout`, `condition`, `onError`, and any extra keys stored as step metadata.

---

## Usage Example

### Sequential pipeline

```lua
local pipeline

function luna.load()
    local step1 = luna.pipeline.newStep("load", function(ctx)
        return luna.filesystem.read(ctx.input.file)
    end)

    local step2 = luna.pipeline.newStep("parse", function(ctx)
        return parseCSV(ctx.results.load)
    end)
    step2:dependsOn(step1)

    local step3 = luna.pipeline.newStep("report", function(ctx)
        return "rows: " .. #ctx.results.parse
    end)
    step3:dependsOn(step2)

    pipeline = luna.pipeline.newPipeline("data-pipeline")
    pipeline:addStep(step1):addStep(step2):addStep(step3)

    local result = pipeline:run({ input = { file = "data.csv" } })
    if result:isSuccess() then
        print(result:getStepResults().report.result)
    else
        for _, err in ipairs(result:getErrors()) do
            print("FAILED: " .. err.stepName .. " — " .. err.error)
        end
    end
end
```

### Parallel steps

```lua
local fetch_a = luna.pipeline.newStep("fetch_a", function(ctx)
    return fetchFromServer("endpoint_a")
end)

local fetch_b = luna.pipeline.newStep("fetch_b", function(ctx)
    return fetchFromServer("endpoint_b")
end)

-- fetch_a and fetch_b have no mutual dependency — they form one parallel group
local merge = luna.pipeline.newStep("merge", function(ctx)
    return mergeResults(ctx.results.fetch_a, ctx.results.fetch_b)
end)
merge:dependsOn(fetch_a):dependsOn(fetch_b)

local p = luna.pipeline.newPipeline("parallel-fetch")
p:addStep(fetch_a):addStep(fetch_b):addStep(merge)
p:setErrorMode("continue")

local result = p:run()
print(result:getSummary())
```

### Async pipeline with delays (cutscene)

```lua
local cutscene

function luna.load()
    cutscene = luna.pipeline.fromTable({
        name  = "intro",
        steps = {
            { name = "fade_out",  fn = function() fadeScreen(0) end },
            { name = "pause",     dependsOn = {"fade_out"},  delay = 1.5, fn = function() end },
            { name = "move_char", dependsOn = {"pause"},     fn = function() moveCharTo(400, 300) end },
            { name = "dialogue",  dependsOn = {"move_char"}, delay = 0.3, fn = function() showDialogue("Hello!") end },
            { name = "fade_in",   dependsOn = {"dialogue"},  delay = 1.0, fn = function() fadeScreen(1) end },
        },
    })
    cutscene:runAsync()
end

function luna.update(dt)
    if not cutscene:isComplete() then
        cutscene:update(dt)
    end
end
```

### Retries and error handling

```lua
local step = luna.pipeline.newStep("network_call", function(ctx)
    local ok, data = pcall(httpGet, "https://api.example.com/data")
    if not ok then error(data) end
    return data
end)
step:setRetryCount(3)
step:setRetryDelay(2.0)
step:setTimeout(10.0)
step:setOnError(function(ctx, err)
    print("Attempt " .. step:getAttempt() .. " failed: " .. err)
end)

local p = luna.pipeline.newPipeline("resilient")
p:addStep(step)
local result = p:run()
```

---

## Module Boundaries

**vs `luna.event`** — The event module handles discrete Lua-side events (pub-sub, polling). Pipelines are for ordered multi-step workflows with dependency tracking, results, and retry logic.

**vs `luna.graph`** — `luna.graph` is a general-purpose directed graph data structure. `luna.pipeline` is an execution engine built on a DAG: it adds scheduling, callbacks, async ticking, and result propagation on top of DAG semantics.

**vs `luna.thread`** — Threads provide OS-level parallelism via `Channel` communication. Pipeline steps run cooperatively on the main Lua thread; use `luna.thread` for CPU-heavy background work, then feed results back to a pipeline step via a channel.
