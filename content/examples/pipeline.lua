-- examples/pipeline.lua
-- lurek.pipeline — Dependency-aware task runner with retry, delay, and condition gates.
-- Build DAGs of steps, run synchronously or spread across frames (async mode).

-- ── Creating Steps ────────────────────────────────────────────────────────────

-- newStep(name) → PipelineStep  — each step is a named unit of work
local load_config = lurek.pipeline.newStep("load_config")
local load_assets = lurek.pipeline.newStep("load_assets")
local init_world  = lurek.pipeline.newStep("init_world")
local spawn_npc   = lurek.pipeline.newStep("spawn_npc")

-- ── Step Configuration ────────────────────────────────────────────────────────

-- setCallback(fn) — the function this step executes; receives the shared context table
load_config:setCallback(function(ctx)
    ctx.config = { max_enemies = 10, difficulty = "normal" }
end)

load_assets:setCallback(function(ctx)
    ctx.hero_img = lurek.gfx.newImage("hero.png")
end)

init_world:setCallback(function(ctx)
    ctx.world = { entities = {}, ticks = 0 }
end)

spawn_npc:setCallback(function(ctx)
    table.insert(ctx.world.entities, { name="guard", hp=100 })
end)

-- ── Step Properties ───────────────────────────────────────────────────────────

-- getName() → string
local name = load_config:getName()         -- "load_config"

-- setCondition(fn?) — skip this step entirely if condition returns false
spawn_npc:setCondition(function(ctx)
    return ctx.config and ctx.config.max_enemies > 0
end)

-- setDelay(sec) / getDelay() → sec  — wait before executing
load_assets:setDelay(0.0)

-- setTimeout(sec) / getTimeout() → sec  — abort if step takes longer (async mode)
load_assets:setTimeout(5.0)

-- setRetryCount(n) — retry up to N times on error
load_assets:setRetryCount(2)

-- getRetryCount() → integer
local retries = load_assets:getRetryCount()

-- setRetryDelay(sec) — pause between retry attempts
load_assets:setRetryDelay(0.25)

-- setOptional(bool) / isOptional() → bool  — continue pipeline if this step fails
spawn_npc:setOptional(true)

-- setOnError(fn?) — per-step error handler
load_assets:setOnError(function(name, msg)
    print("Step failed: " .. name .. " — " .. msg)
end)

-- setData(key, value) / getData(key) → string  — attach metadata string to step
load_config:setData("category", "init")
local cat = load_config:getData("category")     -- "init"

-- setTag(str) / getTag() → str  — tag for batch filtering
load_assets:setTag("assets")
spawn_npc:setTag("gameplay")
local tag = load_assets:getTag()

-- Status / progress queries (valid after run)
-- getStatus() → string  — "pending"|"waiting"|"running"|"completed"|"failed"|"skipped"|"cancelled"
-- getError()  → string?  — error message from last failed attempt
-- getDuration() → number  — seconds spent executing
-- getAttempt()  → integer — number of attempts made

-- ── Declaring Dependencies ────────────────────────────────────────────────────

-- dependsOn(step | stepName)  — this step waits until the named steps complete
load_assets:dependsOn(load_config)
init_world:dependsOn(load_config)
spawn_npc:dependsOn(load_assets)
spawn_npc:dependsOn(init_world)

-- getDependencies() → table  — list of declared dependency names
local deps = spawn_npc:getDependencies()   -- { "load_assets", "init_world" }

-- getDependencyCount() → integer
local ndeps = spawn_npc:getDependencyCount()

-- ── Creating a Pipeline ───────────────────────────────────────────────────────

-- newPipeline(name?) → Pipeline
local pipeline = lurek.pipeline.newPipeline("game_init")

-- addStep(step) → Pipeline  — returns self for chaining
pipeline:addStep(load_config)
        :addStep(load_assets)
        :addStep(init_world)
        :addStep(spawn_npc)

-- ── Pipeline Introspection ────────────────────────────────────────────────────

-- getStepCount() → integer
local n = pipeline:getStepCount()          -- 4

-- getStep(name) → PipelineStep?
local step = pipeline:getStep("load_config")

-- getSteps() → table  — all step wrappers
local all_steps = pipeline:getSteps()

-- getStepsByTag(tag) → table  — filter by tag
local asset_steps = pipeline:getStepsByTag("assets")

-- ── Validation ────────────────────────────────────────────────────────────────

-- validate() → boolean, table  — checks for missing deps, cycles
local ok, errors = pipeline:validate()
if not ok then
    for _, err in ipairs(errors) do
        print("Validation error: " .. err)
    end
end

-- getExecutionOrder() → table?, string?  — topological sort
local order, err = pipeline:getExecutionOrder()

-- getParallelGroups() → table?, string?  — steps safe to run in parallel per level
local groups, gerr = pipeline:getParallelGroups()

-- ── Synchronous Run ───────────────────────────────────────────────────────────

-- run(context?) → result table
-- result = { success, completed, failed, skipped, cancelled, totalDuration, errors }
local ctx = {}   -- shared context passed to all step callbacks
local result = pipeline:run(ctx)

if result.success then
    print("Pipeline done in " .. result.totalDuration .. "s")
else
    for _, e in ipairs(result.errors) do
        print("Error in step '" .. e[1] .. "': " .. e[2])
    end
end

-- ── Error Mode ────────────────────────────────────────────────────────────────

-- setErrorMode("abort"|"continue") — "abort" stops on first failure; "continue" skips and carries on
pipeline:setErrorMode("continue")
local mode = pipeline:getErrorMode()

-- ── Async Run (spread across frames) ─────────────────────────────────────────

-- runAsync(context?) — starts execution; advance with update(dt) each frame
-- update(dt) → boolean  — returns true when all steps are done

--[[
local async_ctx = {}
pipeline:runAsync(async_ctx)

function lurek.process(dt)
    local done = pipeline:update(dt)
    if done then
        local res = pipeline:getResult()  -- full result table
        if res.success then print("done!") end
    end
end
]]

-- setOnComplete(fn?)     — fired once when pipeline finishes
-- setOnStepComplete(fn?) — fired after each successful step: fn(step_name, ctx)
-- setOnStepError(fn?)    — fired after each failed step: fn(step_name, error_msg)

pipeline:setOnComplete(function(result)
    print("All done — " .. #result.completed .. " steps completed")
end)

pipeline:setOnStepComplete(function(step_name, ctx)
    print("Step complete: " .. step_name)
end)

-- ── Cancel / Reset ────────────────────────────────────────────────────────────

-- cancel()  — mark all pending/waiting steps as cancelled
-- reset()   — reset all states to pending, clear async context
-- clear()   — remove all steps from the pipeline

-- ── Serialisation ────────────────────────────────────────────────────────────

-- toTable() → table  — pipeline spec without callbacks (for debug/save)
local spec = pipeline:toTable()

-- getName() / setName(str)
local pname = pipeline:getName()
pipeline:setName("game_init_v2")

-- ── isRunning / isComplete ────────────────────────────────────────────────────

local running  = pipeline:isRunning()     -- true during async execution
local complete = pipeline:isComplete()    -- true when all steps are terminal

-- ─── Pipeline ──────────────────────────────────────────────────────────────────

pipeline:cancel()  -- Cancels all pending and waiting steps
pipeline:clear()  -- Clears all steps from the pipeline
local context = pipeline:getContext()  -- Returns the stored async context table, or nil
pipeline:removeStep("name")  -- Removes a step from the pipeline by name
pipeline:reset()  -- Resets all step states and clears the async context
pipeline:setOnStepError()  -- Sets the callback to invoke each time a step fails
local pipeline_type = pipeline:type()  -- "Pipeline"
local pipeline_is_type = pipeline:typeOf("Pipeline")  -- Returns true if this object is of the given type

-- ─── Step ──────────────────────────────────────────────────────────────────────

local attempt = step:getAttempt()  -- Returns the number of execution attempts so far
local delay = step:getDelay()  -- Returns the configured delay in seconds
local duration = step:getDuration()  -- Returns total seconds spent executing this step
local error = step:getError()  -- Returns the error message from the last failed attempt, or nil
local status = step:getStatus()  -- Returns the current execution status as a string
local timeout = step:getTimeout()  -- Returns the timeout stored in metadata, or 0.0 if unset
local is_optional = step:isOptional()  -- Returns whether this step is marked as optional
step:type()
step:typeOf("myName")

-- ─── lurek.pipeline ─────────────────────────────────────────────────────────────
local from_table = lurek.pipeline.fromTable({})  -- Deserialises a pipeline from a definition table
-- ─── Conditional Stages ───────────────────────────────────────────────────────
-- addConditional(name, deps, fn, when_fn) → Pipeline
--   Adds a step that is skipped at runtime when when_fn() returns false.
--   Equivalent to addStep + :setCondition chained, but in one call.

local debug_mode = true
local p = lurek.pipeline.newPipeline("game_init")
p:addStep("load_assets", function(ctx)
    print("assets loaded")
end)
p:addConditional("debug_overlay", {"load_assets"},
    function(ctx) print("debug overlay enabled") end,
    function()    return debug_mode end   -- skipped when debug_mode == false
)

-- ─── Progress Callbacks ───────────────────────────────────────────────────────
-- onProgress(fn)  — registers fn(step_name, status) called after every step
--   status is a lowercase string: "completed", "failed", or "skipped"

p:onProgress(function(step_name, status)
    print(("  [%s] → %s"):format(step_name, status))
end)

p:run()   -- fires progress callback for each step

-- ─── ASCII DAG Visualization ──────────────────────────────────────────────────
-- toAscii() → string  — multi-line diagram of the pipeline dependency graph

local p2 = lurek.pipeline.newPipeline("example")
p2:addStep("init")
p2:addStep("load",     function() end)
p2:addStep("validate", function() end)
p2:addStep("start",    function() end)

local s  = p2:getStep("load")     ; if s then s:dependsOn("init")     end
local s2 = p2:getStep("validate") ; if s2 then s2:dependsOn("init")   end
local s3 = p2:getStep("start")    ; if s3 then s3:dependsOn("load") ; s3:dependsOn("validate") end

print(p2:toAscii())
-- L0: [init]
-- L1: [load <-- init] || [validate <-- init]
-- L2: [start <-- load,validate]

-- ─── Sub-Pipeline Composition (addSubPipeline) ────────────────────────────────
-- addSubPipeline(sub_pipeline, alias, outer_deps?) → nil
--   Inlines every step from sub_pipeline into this pipeline, prefix-naming them
--   as "alias/step_name".  Entry-point steps of the sub-pipeline depend on any
--   names listed in outer_deps (which must already exist in this pipeline).

local main = lurek.pipeline.newPipeline("main")
main:addStep("boot")
main:addStep("load_config", { deps = {"boot"} })

-- Build a sub-pipeline for audio loading.
local audio_sub = lurek.pipeline.newPipeline("audio")
local a1 = lurek.pipeline.newStep("init_mixer",   function() print("mixer up") end)
local a2 = lurek.pipeline.newStep("load_banks",   function() print("banks loaded") end)
a2:dependsOn("init_mixer")
audio_sub:addStep(a1):addStep(a2)

-- Inline into main: entry-point "init_mixer" depends on "load_config"
-- Resulting names: "audio/init_mixer", "audio/load_banks"
main:addSubPipeline(audio_sub, "audio", { "load_config" })

print("Main + audio sub-pipeline:")
print(main:toAscii())

-- Run it all at once
local ok2, err2 = main:run()
print("Compose run:", ok2, err2)
