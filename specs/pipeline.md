# `pipeline` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Engine Extension                            |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.pipeline`                                      |
| **Source**      | `src/pipeline/`                                      |
| **Rust Tests** | `tests/rust/unit/pipeline_tests.rs`                  |
| **Lua Tests**  | `tests/lua/unit/test_pipeline.lua`                   |
| **Architecture** | —                                                  |

## Summary

The `pipeline` module is a **DAG-based pipeline orchestrator** for composing multi-step
sequential and parallel workflows entirely in Lua. It is a Tier 2 Engine Extension that
depends only on `crate::engine` (for log messages) and the standard library — it does not
import `crate::math`, `mlua`, or any other Tier 1/Tier 2 module.

A `Pipeline` owns a directed acyclic graph of `PipelineStep` nodes stored in a `HashMap`
keyed by step name. Each step declares its upstream dependencies as a list of step names,
plus per-step configuration: delay timer, retry count/delay, error policy, optional flag,
tag, and arbitrary string metadata. `Pipeline::validate()` checks that all dependency names
resolve to existing steps and that the graph is cycle-free using Kahn's topological sort
algorithm. `Pipeline::get_parallel_groups()` partitions the sorted steps into parallel
execution levels — all steps at level N depend only on steps at levels 0..N-1 and may
therefore run concurrently.

`PipelineScheduler` tracks per-step delay timers and overall wall-clock elapsed time. It is
initialised by `start()`, advanced each frame by `update(dt)`, and returns the names of
steps whose delays have elapsed and whose dependencies are satisfied.

`PipelineResult` and `PipelineStatus` represent the aggregated outcome of a pipeline run,
tracking which steps completed, failed, were skipped, or were cancelled, plus wall-clock
duration and per-step error messages.

The Lua API (`luna.pipeline.*`) provides two execution modes: **synchronous** (`run()`)
which executes the full DAG in topological order within a single frame, and **asynchronous**
(`runAsync()` + `update(dt)`) which runs one ready step per tick, suitable for spreading
work across frames. Both modes support a shared context table whose `results` sub-table
accumulates return values from each step callback, allowing downstream steps to consume
upstream output. Pipelines support lifecycle callbacks (`setOnComplete`, `setOnStepComplete`,
`setOnStepError`), condition gates that can skip steps, retry-on-failure with configurable
attempt count, and two error modes (`"abort"` — stop on first failure, `"continue"` — skip
failed step and proceed). Serialisation is supported via `toTable()` / `fromTable()` for
declarative pipeline definitions.

**Scope boundary**: `pipeline` is a pure orchestration module. It does not perform I/O,
rendering, physics, or audio. Step callback implementations live in user Lua scripts. The
module has no GPU, window, or audio device requirements and runs fully headless in tests.

## Architecture

```
luna.pipeline (Lua API)
  │
  │  newStep(name, fn?)        → LuaStep  (UserData wrapper)
  │  newPipeline(name?)        → LuaPipeline (UserData wrapper)
  │  fromTable(def)            → LuaPipeline
  │
  ▼
┌─────────────────────────────────────────────────────────────┐
│                  pipeline_api.rs (bridge)                    │
│  LuaStep  ──wraps──▶  PipelineStep (Rc<RefCell<>>)          │
│  LuaPipeline ─wraps─▶ Pipeline + PipelineScheduler          │
│                        + step_wrappers HashMap               │
│  Lua registry keys:  callback, condition, on_error,         │
│                       on_complete, on_step_complete,         │
│                       on_step_error, context                 │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    src/pipeline/ (Rust)                      │
│                                                             │
│  dag.rs ─────── Pipeline { steps: HashMap<String, Step> }   │
│     │            add_step / remove_step / validate           │
│     │            get_execution_order (Kahn's topo sort)      │
│     │            get_parallel_groups (level assignment)       │
│     │            ErrorMode { Abort, Continue }               │
│     │                                                       │
│  step.rs ────── PipelineStep { name, deps, delay, optional, │
│     │            retry_count, retry_delay, on_error, tag,    │
│     │            metadata, status, attempt, duration, ...}   │
│     │            StepStatus { Pending → Waiting → Running    │
│     │                         → Completed | Failed | Skipped │
│     │                         | Cancelled }                  │
│     │            ErrorPolicy { Abort, Continue, Retry }      │
│     │                                                       │
│  scheduler.rs ─ PipelineScheduler { delay_timers, is_running,│
│     │            elapsed }                                   │
│     │            start / update(dt) / mark_step_waiting      │
│     │                                                       │
│  result.rs ──── PipelineResult { status, completed, failed,  │
│                  skipped, cancelled, total_duration, errors } │
│                  PipelineStatus { Pending, Running,           │
│                  Completed, Failed, Cancelled }               │
└─────────────────────────────────────────────────────────────┘
```

## Source Files

| File           | Purpose                                                                              |
|----------------|--------------------------------------------------------------------------------------|
| `mod.rs`       | Module root — declares submodules, re-exports `Pipeline`, `PipelineStep`, `PipelineResult`, `PipelineScheduler`, `ErrorMode`, `ErrorPolicy`, `PipelineStatus`, `StepStatus` |
| `dag.rs`       | DAG container (`Pipeline`) — step storage, topological sort (Kahn's algorithm), cycle detection, parallel group levelling, `ErrorMode` enum |
| `step.rs`      | Step definition (`PipelineStep`) — name, deps, delay, retry, optional, tag, metadata, runtime status tracking; `StepStatus` and `ErrorPolicy` enums |
| `result.rs`    | Execution outcome (`PipelineResult`) — aggregated completed/failed/skipped/cancelled lists, wall-clock duration, error pairs; `PipelineStatus` enum |
| `scheduler.rs` | Delay timer manager (`PipelineScheduler`) — per-step countdown, elapsed tracking, ready-step detection on `update(dt)` |

## Submodules

### `pipeline::dag`

DAG container for pipeline steps. Implements topological sort via Kahn's algorithm for
execution ordering, cycle detection, and parallel group levelling for concurrent execution.

- **`Pipeline`** (struct): Owns a `HashMap<String, PipelineStep>` and a global `ErrorMode`. Provides `add_step`, `remove_step`, `get_step`, `get_step_mut`, `get_steps`, `get_step_count`, `clear`, `validate`, `get_execution_order`, `get_parallel_groups`, and `reset`.
- **`ErrorMode`** (enum): Determines pipeline-wide failure behaviour — `Abort` (stop on first failure) or `Continue` (skip failed step and proceed).

### `pipeline::step`

Defines a single node in the pipeline DAG with full runtime lifecycle tracking.

- **`PipelineStep`** (struct): A named unit of work with dependency list, delay timer, optional flag, retry config, error policy, tag, metadata, and mutable runtime fields (status, attempt, duration, error message).
- **`StepStatus`** (enum): Seven-state lifecycle — `Pending`, `Waiting`, `Running`, `Completed`, `Failed`, `Skipped`, `Cancelled`.
- **`ErrorPolicy`** (enum): Per-step failure behaviour — `Abort`, `Continue`, or `Retry`.

### `pipeline::result`

Aggregated outcome of a complete pipeline execution.

- **`PipelineResult`** (struct): Tracks lists of completed, failed, skipped, and cancelled step names, wall-clock `total_duration`, and `(step_name, error_message)` error pairs. Provides `is_success()` and `summary()`.
- **`PipelineStatus`** (enum): Overall pipeline state — `Pending`, `Running`, `Completed`, `Failed`, `Cancelled`.

### `pipeline::scheduler`

Time-based dispatch that triggers ready steps after their configured delay elapses.

- **`PipelineScheduler`** (struct): Maintains a `HashMap<String, f32>` of remaining delay seconds per step, plus `is_running` and `elapsed` fields. `start()` initialises timers, `update(dt)` ticks them and returns ready step names, `mark_step_waiting()` starts a step's countdown, `reset()` clears all state.

## Key Types

### Structs

#### `pipeline::dag::Pipeline`

A directed acyclic graph container that holds pipeline steps and their dependencies.
`Pipeline` owns step definitions in a `HashMap<String, PipelineStep>` and provides
validation, topological ordering, and parallel group partitioning. A global `error_mode`
(`ErrorMode`) controls pipeline-wide failure handling. Key methods: `new(name)`,
`add_step(step)`, `remove_step(name)`, `get_step(name)`, `get_step_mut(name)`,
`get_steps()`, `get_step_count()`, `clear()`, `validate()`, `get_execution_order()`,
`get_parallel_groups()`, `reset()`.

#### `pipeline::step::PipelineStep`

A single node in a pipeline DAG representing one unit of work. Identified by a unique
`name` within its parent `Pipeline`. Configuration fields: `deps` (dependency names),
`delay` (seconds to wait after deps finish), `optional` (if true, downstream proceeds
on failure), `retry_count`, `retry_delay`, `on_error` (per-step `ErrorPolicy`), `tag`,
`metadata` (arbitrary string key/value pairs). Runtime fields: `status` (`StepStatus`),
`attempt`, `duration`, `error_msg` — all reset by `reset()`.

#### `pipeline::result::PipelineResult`

Aggregated outcome of a complete pipeline run. Fields: `status` (`PipelineStatus`),
`completed` / `failed` / `skipped` / `cancelled` (name lists), `total_duration`
(wall-clock seconds), `errors` (vector of `(step_name, error_message)` tuples).
`is_success()` returns `true` if no steps failed. `summary()` returns a human-readable
one-line status string.

#### `pipeline::scheduler::PipelineScheduler`

Tracks per-step delay timers and overall wall-clock time for a pipeline run. `start()`
populates timers from each step's configured delay. `update(dt)` decrements active
timers and returns the names of steps whose delay has elapsed. `mark_step_waiting()`
starts a newly-eligible step's countdown. `reset()` clears all state.

### Enums

#### `pipeline::dag::ErrorMode`

Pipeline-wide failure handling: `Abort` stops execution on the first failed step;
`Continue` skips the failed step and proceeds with remaining steps. Serialises to
`"abort"` / `"continue"` strings for Lua via `as_str()` / `from_str_lua()`.

#### `pipeline::step::StepStatus`

Seven-state execution lifecycle for a single step: `Pending` → `Waiting` (deps
satisfied, delay counting) → `Running` → `Completed` | `Failed` | `Skipped` |
`Cancelled`. Serialises to lowercase strings via `as_str()`.

#### `pipeline::step::ErrorPolicy`

Per-step failure behaviour: `Abort` (abort the entire pipeline), `Continue` (skip
this step, proceed), `Retry` (retry up to `retry_count` times before falling back).

#### `pipeline::result::PipelineStatus`

Overall pipeline state: `Pending`, `Running`, `Completed`, `Failed`, `Cancelled`.

## Lua API

Exposed under `luna.pipeline.*` by `src/lua_api/pipeline_api.rs`.

The API provides two UserData types — `PipelineStep` and `Pipeline` — plus three
factory functions on the `luna.pipeline` table.

### Factory Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `luna.pipeline.newStep` | `(name: string, fn?: function) → PipelineStep` | Creates a new step; optional callback set immediately |
| `luna.pipeline.newPipeline` | `(name?: string) → Pipeline` | Creates an empty pipeline (defaults to `"pipeline"`) |
| `luna.pipeline.fromTable` | `(def: table) → Pipeline` | Deserialises a pipeline from a declarative definition table |

### PipelineStep Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `getName` | `() → string` | Returns the step's unique name |
| `setCallback` | `(fn: function)` | Sets the execute callback |
| `setCondition` | `(fn?: function)` | Sets a condition gate (return `false` to skip) |
| `setDelay` | `(seconds: number)` | Sets post-dependency delay |
| `getDelay` | `() → number` | Returns configured delay |
| `setTimeout` | `(seconds: number)` | Stores a timeout in metadata |
| `getTimeout` | `() → number` | Returns stored timeout (0 if unset) |
| `setRetryCount` | `(count: integer)` | Sets max retry attempts |
| `getRetryCount` | `() → integer` | Returns retry count |
| `setRetryDelay` | `(seconds: number)` | Sets delay between retries |
| `setOptional` | `(optional: boolean)` | Marks step as optional |
| `isOptional` | `() → boolean` | Returns optional flag |
| `setOnError` | `(fn?: function)` | Sets per-step error callback |
| `setData` | `(key: string, value: string)` | Stores arbitrary metadata |
| `getData` | `(key: string) → string?` | Retrieves metadata by key |
| `setTag` | `(tag: string)` | Sets grouping tag |
| `getTag` | `() → string?` | Returns tag or nil |
| `dependsOn` | `(dep: string\|PipelineStep) → PipelineStep` | Adds a dependency; returns self for chaining |
| `getDependencies` | `() → table` | Returns array of dependency names |
| `getDependencyCount` | `() → integer` | Returns dependency count |
| `getStatus` | `() → string` | Returns current status string |
| `getError` | `() → string?` | Returns last error message or nil |
| `getDuration` | `() → number` | Returns execution duration in seconds |
| `getAttempt` | `() → integer` | Returns number of attempts so far |

### Pipeline Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `addStep` | `(step: PipelineStep) → Pipeline` | Adds a step; returns self for chaining |
| `removeStep` | `(name: string)` | Removes a step by name |
| `getStep` | `(name: string) → PipelineStep?` | Looks up a step by name |
| `getSteps` | `() → table` | Returns array of all steps |
| `getStepCount` | `() → integer` | Returns total step count |
| `getStepsByTag` | `(tag: string) → table` | Returns steps matching the tag |
| `clear` | `()` | Removes all steps |
| `validate` | `() → boolean, table` | Validates DAG; returns ok + error list |
| `getExecutionOrder` | `() → table?, string?` | Returns topological order or error |
| `getParallelGroups` | `() → table?, string?` | Returns nested parallel level arrays |
| `run` | `(context?: table) → table` | Executes synchronously; returns result table |
| `runAsync` | `(context?: table)` | Starts async execution (one step per `update` tick) |
| `update` | `(dt: number) → boolean` | Advances async run; returns true when complete |
| `cancel` | `()` | Cancels all pending/waiting steps |
| `reset` | `()` | Resets all step states and async context |
| `isRunning` | `() → boolean` | Returns true if async run is in progress |
| `isComplete` | `() → boolean` | Returns true if all steps are terminal |
| `setErrorMode` | `(mode: string)` | Sets `"abort"` or `"continue"` |
| `getErrorMode` | `() → string` | Returns current error mode |
| `getResult` | `() → table?` | Returns current result table |
| `getContext` | `() → table?` | Returns stored async context |
| `setOnComplete` | `(fn?: function)` | Sets pipeline-complete callback |
| `setOnStepComplete` | `(fn?: function)` | Sets per-step-complete callback |
| `setOnStepError` | `(fn?: function)` | Sets per-step-error callback |
| `getName` | `() → string` | Returns pipeline name |
| `setName` | `(name: string)` | Sets pipeline name |
| `toTable` | `() → table` | Serialises definition (no callbacks) |

### Result Table (returned by `run()`)

```lua
{
    success = true|false,           -- true if no steps failed
    completed = {"step1", ...},     -- names of completed steps
    failed = {"step3", ...},        -- names of failed steps
    skipped = {"step2", ...},       -- names of skipped steps
    cancelled = {"step4", ...},     -- names of cancelled steps
    totalDuration = 0.003,          -- wall-clock seconds
    errors = {{"step3", "msg"}, ...} -- (name, message) pairs
}
```

## Lua Examples

```lua
-- Synchronous pipeline: multi-stage world generation
function luna.init()
    local terrain = luna.pipeline.newStep("terrain", function(ctx)
        return { heightmap = generate_heightmap(ctx.seed) }
    end)

    local rivers = luna.pipeline.newStep("rivers", function(ctx)
        return place_rivers(ctx.results.terrain.heightmap)
    end)
    rivers:dependsOn(terrain)

    local cities = luna.pipeline.newStep("cities", function(ctx)
        return place_cities(ctx.results.terrain.heightmap, ctx.results.rivers)
    end)
    cities:dependsOn(terrain):dependsOn(rivers)

    local pipe = luna.pipeline.newPipeline("worldgen")
    pipe:addStep(terrain):addStep(rivers):addStep(cities)

    local result = pipe:run({ seed = 42 })
    if result.success then
        print("World generated in " .. result.totalDuration .. "s")
    else
        for _, err in ipairs(result.errors) do
            print("FAILED: " .. err[1] .. " — " .. err[2])
        end
    end
end
```

```lua
-- Async pipeline: spread loading across frames
local loader

function luna.init()
    loader = luna.pipeline.fromTable({
        name = "asset_loader",
        steps = {
            { name = "textures",  fn = function(ctx) return load_textures()  end },
            { name = "sounds",    fn = function(ctx) return load_sounds()    end },
            { name = "combine",   fn = function(ctx) return true end,
              deps = {"textures", "sounds"} },
        }
    })
    loader:setOnComplete(function(result)
        print("Loading done: " .. (result.success and "OK" or "FAIL"))
    end)
    loader:runAsync()
end

function luna.process(dt)
    if loader:isRunning() then
        loader:update(dt)
    end
end
```

```lua
-- Declarative pipeline with error handling and retries
local pipe = luna.pipeline.newPipeline("robust")
pipe:setErrorMode("continue")

local fetch = luna.pipeline.newStep("fetch", function(ctx)
    return download_data(ctx.url)
end)
fetch:setRetryCount(3)
fetch:setRetryDelay(1.0)
fetch:setTimeout(10)

local parse = luna.pipeline.newStep("parse", function(ctx)
    return parse_data(ctx.results.fetch)
end)
parse:dependsOn(fetch)
parse:setOptional(true)

pipe:addStep(fetch):addStep(parse)
local r = pipe:run({ url = "https://example.com/data" })
```

## Item Summary

| Kind      | Count |
|-----------|-------|
| `struct`  | 4     |
| `enum`    | 4     |
| `fn`      | 25    |
| **Total** | **33** |

## References

| Module          | Relationship | Notes                                             |
|-----------------|--------------|----------------------------------------------------|
| `engine`        | Imports from | Uses `log_messages` constants (`PL01_*`, `PL02_*`, `LA02_*`) via `log_msg!` macro |
| `lua_api`       | Imported by  | `pipeline_api.rs` wraps all types as `LuaStep`/`LuaPipeline` UserData |
| `scene`         | Similar      | `scene` manages a stack of game scenes with transitions; `pipeline` orchestrates DAG-ordered step workflows — different abstractions |
| `automation`    | Similar      | `automation` records/replays input sequences; `pipeline` orchestrates arbitrary Lua callbacks in dependency order |

## Notes

- **No external crate dependencies**: The Rust module uses only `std::collections` (`HashMap`, `HashSet`, `VecDeque`). All graph algorithms are hand-written.
- **Execution is single-threaded**: Despite the `get_parallel_groups()` API, the current Lua-side execution in `pipeline_api.rs` runs steps sequentially in topological order (sync) or one-per-tick (async). True parallel execution would require separate Lua VMs per thread.
- **Step callbacks are stored as Lua registry keys**: The `LuaStep` and `LuaPipeline` wrappers use `Rc<RefCell<Option<LuaRegistryKey>>>` for callbacks. This means callbacks cannot be serialised by `toTable()` — only structural data (name, deps, delay, tag, etc.) is preserved.
- **Context table is shared**: Both `run()` and `runAsync()` pass a single Lua table as `ctx` to every step callback. Upstream return values are stored in `ctx.results.<step_name>`. Steps may also read/write arbitrary keys on `ctx`.
- **Retry semantics**: When a step has `retry_count > 0`, the callback is re-invoked up to `retry_count + 1` total times. The retry delay field exists on `PipelineStep` but is not currently enforced as a wall-clock wait in `execute_step_sync` — retries happen immediately in sequence.
- **Condition gates**: A step with a condition function that returns `false` is set to `Skipped` status. If the step is marked `optional`, downstream dependencies proceed normally.
- **Headless safe**: All pipeline types and the Lua API work without a window, GPU, or audio device. Tests run fully headless.
- **Breaking change surface**: Renaming step method names on `LuaPipeline` or `LuaStep` will break any Lua script using `luna.pipeline.*`. The `fromTable()` schema (`name`, `deps`, `fn`, `delay`, `optional`, `retryCount`, `retryDelay`, `tag`, `errorMode`) is a serialisation contract.
