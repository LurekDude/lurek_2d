-- content/examples/pipeline.lua
-- Hand-written coverage of the lurek.pipeline API (60 items).
--
-- Pipelines are dependency-ordered DAGs of named steps with sync and
-- async runners, retries, conditions, tags, and per-step callbacks for
-- structuring boot sequences, save/load flows, and asset loaders.
--
-- Run: cargo run -- content/examples/pipeline.lua

-- ── lurek.pipeline.* functions ──

--@api-stub: lurek.pipeline.newStep
-- Creates a new pipeline step with the given name and optional callback.
-- Pass the callback inline for one-shot tasks; configure delay/retry/tag on the returned step.
do  -- lurek.pipeline.newStep
  local step = lurek.pipeline.newStep("load_audio", function(ctx)
    ctx.audio_loaded = true
  end)
  step:setTag("boot")
end

--@api-stub: lurek.pipeline.newPipeline
-- Creates a new empty pipeline with the given name (defaults to "pipeline").
-- Call once at boot to declare the top-level run; the name surfaces in toAscii output and progress callbacks.
do  -- lurek.pipeline.newPipeline
  local boot = lurek.pipeline.newPipeline("boot")
  boot:addStep(lurek.pipeline.newStep("init", function() end))
  lurek.log.info("pipeline '" .. boot:getName() .. "' built", "boot")
end

--@api-stub: lurek.pipeline.fromTable
-- Deserialises a pipeline from a definition table.
-- Use when the DAG is data-driven (TOML/JSON); wire callbacks afterwards via getStep + setCallback.
do  -- lurek.pipeline.fromTable
  local def = { name = "save", steps = {
    { name = "snapshot",   deps = {} },
    { name = "write_disk", deps = { "snapshot" } },
  } }
  local pl = lurek.pipeline.fromTable(def)
  pl:getStep("snapshot"):setCallback(function(ctx) ctx.snap = "ok" end)
end

-- ── Step methods ──

--@api-stub: Step:getName
-- Returns the unique name of this step.
-- Read when iterating Pipeline:getSteps to log per-step diagnostics or build a UI label.
do  -- Step:getName
  local step = lurek.pipeline.newStep("hydrate_world")
  lurek.log.info("registering step: " .. step:getName(), "boot")
end

--@api-stub: Step:setCallback
-- Stores a Lua function as the execute callback for this step.
-- Attach or replace the executor body after construction; required when wiring a fromTable pipeline.
do  -- Step:setCallback
  local step = lurek.pipeline.newStep("warm_caches")
  step:setCallback(function(ctx)
    ctx.caches = { sprites = 64, audio = 16 }
  end)
end

--@api-stub: Step:setCondition
-- Stores a Lua function (or nil) as the run-condition for this step.
-- Pass nil to clear; skipped steps don't fail their dependents — useful for debug-only or DLC-gated steps.
do  -- Step:setCondition
  local step = lurek.pipeline.newStep("seed_demo_data", function(ctx) ctx.seeded = true end)
  step:setCondition(function() return lurek.log.getLevel() == "debug" end)
end

--@api-stub: Step:setDelay
-- Sets the delay in seconds to wait after dependencies finish.
-- Use to stagger intros or pace splash animations; honoured by both sync and async runners.
do  -- Step:setDelay
  local step = lurek.pipeline.newStep("show_logo")
  step:setDelay(0.5)
end

--@api-stub: Step:getDelay
-- Returns the configured delay in seconds.
-- Read when displaying loading-progress estimates or unit-testing scheduling.
do  -- Step:getDelay
  local step = lurek.pipeline.newStep("fade_in")
  step:setDelay(1.25)
  lurek.log.debug("fade_in waits " .. step:getDelay() .. "s", "boot")
end

--@api-stub: Step:setTimeout
-- Stores a timeout in seconds in the step's metadata.
-- Cap the per-attempt runtime so the scheduler can abort long-running async steps cleanly.
do  -- Step:setTimeout
  local step = lurek.pipeline.newStep("fetch_remote_config")
  step:setTimeout(5.0)
end

--@api-stub: Step:getTimeout
-- Returns the timeout stored in metadata, or 0.0 if unset.
-- Branch on the value (0 means no deadline) when surfacing time budgets in dev tooling.
do  -- Step:getTimeout
  local step = lurek.pipeline.newStep("download_dlc")
  step:setTimeout(30.0)
  if step:getTimeout() > 0 then
    lurek.log.info("download bounded to " .. step:getTimeout() .. "s", "net")
  end
end

--@api-stub: Step:setRetryCount
-- Sets the maximum number of retry attempts on failure.
-- Combine with setRetryDelay for back-off; total attempts equals 1 + retry_count.
do  -- Step:setRetryCount
  local step = lurek.pipeline.newStep("connect_server", function(ctx) ctx.online = true end)
  step:setRetryCount(3)
  step:setRetryDelay(0.5)
end

--@api-stub: Step:getRetryCount
-- Returns the configured retry count.
-- Read back when building a settings UI or when validating a deserialised pipeline.
do  -- Step:getRetryCount
  local step = lurek.pipeline.newStep("publish_score")
  step:setRetryCount(2)
  lurek.log.info("retries=" .. step:getRetryCount(), "net")
end

--@api-stub: Step:setRetryDelay
-- Sets the delay in seconds between retry attempts.
-- Use 1-2s for flaky network calls so transient errors clear before the next attempt.
do  -- Step:setRetryDelay
  local step = lurek.pipeline.newStep("login")
  step:setRetryCount(4)
  step:setRetryDelay(2.0)
end

--@api-stub: Step:setOptional
-- Marks whether this step is optional (downstream steps continue on failure).
-- Use for nice-to-have boot work (achievements, telemetry) so a failure doesn't block gameplay.
do  -- Step:setOptional
  local step = lurek.pipeline.newStep("preload_credits", function() end)
  step:setOptional(true)
end

--@api-stub: Step:isOptional
-- Returns whether this step is marked as optional.
-- Branch visualisation/UI on whether a step is required vs nice-to-have.
do  -- Step:isOptional
  local step = lurek.pipeline.newStep("achievements_sync")
  step:setOptional(true)
  if step:isOptional() then
    lurek.log.debug(step:getName() .. " will not abort the pipeline", "boot")
  end
end

--@api-stub: Step:setOnError
-- Stores a Lua function (or nil) to call if this step fails.
-- Receives the error message; pass nil to clear. Use for per-step recovery or logging.
do  -- Step:setOnError
  local step = lurek.pipeline.newStep("load_save", function() error("missing slot") end)
  step:setOnError(function(err)
    lurek.log.warn("save load failed: " .. err, "save")
  end)
end

--@api-stub: Step:setData
-- Stores an arbitrary string value under the given key in step metadata.
-- Strings only — use to template per-step config (scene name, asset path) read inside the callback.
do  -- Step:setData
  local step = lurek.pipeline.newStep("load_level")
  step:setData("scene", "forest_01")
  step:setData("difficulty", "normal")
end

--@api-stub: Step:getData
-- Retrieves a metadata value by key, returning nil if not found.
-- Always default with `or` since unknown keys return nil rather than raising.
do  -- Step:getData
  local step = lurek.pipeline.newStep("load_level")
  step:setData("scene", "forest_01")
  local scene = step:getData("scene") or "title"
  lurek.log.info("loading scene: " .. scene, "scene")
end

--@api-stub: Step:setTag
-- Sets the tag on this step for grouping and filtering.
-- Pair with Pipeline:getStepsByTag to operate on a logical subset ("gpu", "net", "audio").
do  -- Step:setTag
  local step = lurek.pipeline.newStep("compile_shaders")
  step:setTag("gpu")
end

--@api-stub: Step:getTag
-- Returns the tag on this step, or nil if unset.
-- Use to colour-code or group steps in a debug overlay; default with `or` for untagged steps.
do  -- Step:getTag
  local step = lurek.pipeline.newStep("warm_audio")
  step:setTag("audio")
  local tag = step:getTag() or "untagged"
  lurek.log.debug(step:getName() .. " tag=" .. tag, "boot")
end

--@api-stub: Step:dependsOn
-- Adds a dependency on another step by name or PipelineStep.
-- Pass a Step userdata or a name string; multiple calls accumulate, so chain them for fan-in nodes.
do  -- Step:dependsOn
  local boot = lurek.pipeline.newStep("boot")
  local load = lurek.pipeline.newStep("load_assets")
  load:dependsOn(boot)
  load:dependsOn("network_ready")
end

--@api-stub: Step:getDependencies
-- Returns the list of dependency step names.
-- Iterate to render a DAG visualiser; the array is empty for entry-point steps.
do  -- Step:getDependencies
  local step = lurek.pipeline.newStep("present")
  step:dependsOn("draw_world")
  step:dependsOn("draw_ui")
  for _, name in ipairs(step:getDependencies()) do
    lurek.log.debug("present depends on " .. name, "boot")
  end
end

--@api-stub: Step:getDependencyCount
-- Returns the number of declared dependencies.
-- Use as a cheap O(1) guard before walking getDependencies; zero means an entry-point step.
do  -- Step:getDependencyCount
  local step = lurek.pipeline.newStep("commit_save")
  step:dependsOn("snapshot_state")
  if step:getDependencyCount() == 0 then
    lurek.log.warn("commit_save has no deps; will run immediately", "save")
  end
end

--@api-stub: Step:getStatus
-- Returns the current execution status as a string.
-- One of "pending", "waiting", "running", "completed", "failed", "skipped", "cancelled".
do  -- Step:getStatus
  local pl = lurek.pipeline.newPipeline("audit")
  local s = lurek.pipeline.newStep("noop", function() end)
  pl:addStep(s); pl:run()
  lurek.log.info("noop status: " .. s:getStatus(), "boot")
end

--@api-stub: Step:getError
-- Returns the error message from the last failed attempt, or nil.
-- Check after a failed run before retrying; nil means the step succeeded or hasn't run yet.
do  -- Step:getError
  local step = lurek.pipeline.newStep("touchy", function() error("disk full") end)
  local pl = lurek.pipeline.newPipeline("io"); pl:addStep(step); pl:run()
  if step:getError() then
    lurek.log.error(step:getName() .. ": " .. step:getError(), "io")
  end
end

--@api-stub: Step:getDuration
-- Returns total seconds spent executing this step.
-- Sums all attempts; combine with onProgress to build a per-step profiler view.
do  -- Step:getDuration
  local step = lurek.pipeline.newStep("compute", function() end)
  local pl = lurek.pipeline.newPipeline("bench"); pl:addStep(step); pl:run()
  lurek.log.info(string.format("compute took %.3fs", step:getDuration()), "perf")
end

--@api-stub: Step:getAttempt
-- Returns the number of execution attempts so far.
-- Equals 1 for steps that succeeded first try; inspect to detect flaky steps after retries.
do  -- Step:getAttempt
  local step = lurek.pipeline.newStep("flaky", function() end)
  step:setRetryCount(2)
  local pl = lurek.pipeline.newPipeline("net"); pl:addStep(step); pl:run()
  lurek.log.debug("flaky attempts: " .. step:getAttempt(), "net")
end

--@api-stub: Step:type
-- Returns the type name "PipelineStep".
-- Useful for runtime introspection alongside duck-typed values pulled from a generic container.
do  -- Step:type
  local step = lurek.pipeline.newStep("init")
  if step:type() == "PipelineStep" then
    lurek.log.debug("got a real step", "boot")
  end
end

--@api-stub: Step:typeOf
-- Returns true when the given name matches "PipelineStep" or a parent type.
-- Pass "Object" to test for any pipeline-namespace value when bridging from generic code.
do  -- Step:typeOf
  local step = lurek.pipeline.newStep("init")
  if step:typeOf("Object") then
    lurek.log.debug("step inherits from Object", "boot")
  end
end

-- ── Pipeline methods ──

--@api-stub: Pipeline:addStep
-- Adds a step to the pipeline.
-- Returns the pipeline for chaining; step names must be unique within a single pipeline.
do  -- Pipeline:addStep
  local pl = lurek.pipeline.newPipeline("boot")
  pl:addStep(lurek.pipeline.newStep("read_config", function(ctx) ctx.cfg = {} end))
    :addStep(lurek.pipeline.newStep("warm_cache",  function() end))
end

--@api-stub: Pipeline:removeStep
-- Removes a step from the pipeline by name.
-- Safe before run() begins; existing dependents on the removed name will fail validate().
do  -- Pipeline:removeStep
  local pl = lurek.pipeline.newPipeline("boot")
  pl:addStep(lurek.pipeline.newStep("legacy_check", function() end))
  pl:removeStep("legacy_check")
end

--@api-stub: Pipeline:getStep
-- Returns the LuaStep wrapper for the named step, or nil.
-- Required to attach callbacks after fromTable, since serialised pipelines lack callback closures.
do  -- Pipeline:getStep
  local pl = lurek.pipeline.fromTable({ steps = { { name = "boot", deps = {} } } })
  local boot = pl:getStep("boot")
  if boot then boot:setCallback(function(ctx) ctx.booted = true end) end
end

--@api-stub: Pipeline:getSteps
-- Returns a Lua array of all step wrappers in the pipeline.
-- Returns registration order, not execution order — use getExecutionOrder for the topological view.
do  -- Pipeline:getSteps
  local pl = lurek.pipeline.newPipeline("scan")
  pl:addStep(lurek.pipeline.newStep("a"))
  pl:addStep(lurek.pipeline.newStep("b"))
  for _, s in ipairs(pl:getSteps()) do
    lurek.log.debug("found step " .. s:getName(), "boot")
  end
end

--@api-stub: Pipeline:getStepCount
-- Returns the total number of steps.
-- O(1) size check; use to short-circuit empty pipelines before incurring run setup cost.
do  -- Pipeline:getStepCount
  local pl = lurek.pipeline.newPipeline("dynamic")
  if pl:getStepCount() == 0 then
    lurek.log.warn("nothing to do; skipping run", "boot")
  end
end

--@api-stub: Pipeline:getStepsByTag
-- Returns a Lua array of all steps whose tag matches the given string.
-- Returns an empty table when no steps match — safe to ipairs without a nil check.
do  -- Pipeline:getStepsByTag
  local pl = lurek.pipeline.newPipeline("boot")
  local s = lurek.pipeline.newStep("upload_metric"); s:setTag("net"); pl:addStep(s)
  for _, n in ipairs(pl:getStepsByTag("net")) do
    lurek.log.info("net step: " .. n:getName(), "net")
  end
end

--@api-stub: Pipeline:clear
-- Clears all steps from the pipeline.
-- Useful when rebuilding the pipeline from a hot-reloaded definition without allocating a new one.
do  -- Pipeline:clear
  local pl = lurek.pipeline.newPipeline("hot")
  pl:addStep(lurek.pipeline.newStep("old"))
  pl:clear()
end

--@api-stub: Pipeline:validate
-- Validates the pipeline DAG.
-- Returns (ok, errors_array); call before run() to surface missing deps and cycles up front.
do  -- Pipeline:validate
  local pl = lurek.pipeline.newPipeline("check")
  local s = lurek.pipeline.newStep("orphan"); s:dependsOn("missing"); pl:addStep(s)
  local ok, errs = pl:validate()
  if not ok then
    for _, e in ipairs(errs or {}) do lurek.log.error(e, "pipeline") end
  end
end

--@api-stub: Pipeline:getExecutionOrder
-- Returns the topological execution order as an array of step names.
-- Returns (order, nil) on success or (nil, err) on cycle; check the second return before reading the first.
do  -- Pipeline:getExecutionOrder
  local pl = lurek.pipeline.newPipeline("plan")
  pl:addStep(lurek.pipeline.newStep("a"))
  local order, err = pl:getExecutionOrder()
  if err then lurek.log.error(err, "pipeline")
  else lurek.log.info("first step: " .. ((order and order[1]) or "?"), "pipeline") end
end

--@api-stub: Pipeline:getParallelGroups
-- Returns parallel execution groups as a nested array of step name arrays.
-- Each inner table holds steps with no inter-dependencies; safe to dispatch concurrently.
do  -- Pipeline:getParallelGroups
  local pl = lurek.pipeline.newPipeline("parallel")
  pl:addStep(lurek.pipeline.newStep("a"))
  pl:addStep(lurek.pipeline.newStep("b"))
  local groups = pl:getParallelGroups()
  lurek.log.info("group count: " .. #groups, "pipeline")
end

--@api-stub: Pipeline:run
-- Executes the pipeline synchronously in topological order.
-- Pass an optional context table to share state between steps via ctx.results.
do  -- Pipeline:run
  local pl = lurek.pipeline.newPipeline("boot")
  pl:addStep(lurek.pipeline.newStep("load", function(ctx) ctx.assets = 12 end))
  local result = pl:run({ user = "p1" })
  lurek.log.info("ok=" .. tostring(result.success), "boot")
end

--@api-stub: Pipeline:runAsync
-- Starts an async pipeline run.
-- Steps execute one-per-frame via update(dt); call from inside lurek.process to advance.
do  -- Pipeline:runAsync
  local pl = lurek.pipeline.newPipeline("loading")
  pl:addStep(lurek.pipeline.newStep("a", function() end))
  pl:runAsync({ progress = 0 })
  function lurek.process(dt) pl:update(dt) end
end

--@api-stub: Pipeline:update
-- Advances the async pipeline by one tick.
-- Returns true on the tick the pipeline finishes; pair with runAsync inside lurek.process.
do  -- Pipeline:update
  local pl = lurek.pipeline.newPipeline("loader")
  pl:addStep(lurek.pipeline.newStep("scan", function() end))
  pl:runAsync()
  function lurek.process(dt)
    if pl:update(dt) then lurek.log.info("loader done", "boot") end
  end
end

--@api-stub: Pipeline:cancel
-- Cancels all pending and waiting steps.
-- In-flight steps continue to completion; safe to call from a UI button or timeout handler.
do  -- Pipeline:cancel
  local pl = lurek.pipeline.newPipeline("net")
  pl:addStep(lurek.pipeline.newStep("ping", function() end))
  pl:runAsync()
  pl:cancel()
end

--@api-stub: Pipeline:reset
-- Resets all step states and clears the async context.
-- Call between runs to reuse the same pipeline definition without re-adding steps.
do  -- Pipeline:reset
  local pl = lurek.pipeline.newPipeline("retry")
  pl:addStep(lurek.pipeline.newStep("once", function() end))
  pl:run(); pl:reset(); pl:run()
end

--@api-stub: Pipeline:isRunning
-- Returns true if the pipeline is currently running asynchronously.
-- True only between runAsync and the tick where update returns true; false for sync runs.
do  -- Pipeline:isRunning
  local pl = lurek.pipeline.newPipeline("loader")
  pl:addStep(lurek.pipeline.newStep("a", function() end))
  pl:runAsync()
  if pl:isRunning() then lurek.log.debug("loader in flight", "boot") end
end

--@api-stub: Pipeline:isComplete
-- Returns true if all steps have reached a terminal state.
-- Check before reading getResult; terminal states are completed/failed/skipped/cancelled.
do  -- Pipeline:isComplete
  local pl = lurek.pipeline.newPipeline("boot")
  pl:addStep(lurek.pipeline.newStep("noop", function() end))
  pl:run()
  if pl:isComplete() then lurek.log.info("boot finished", "boot") end
end

--@api-stub: Pipeline:setErrorMode
-- Sets the pipeline error mode: "abort" or "continue".
-- "abort" (default) stops the run on first failure; "continue" keeps going and skips dependents.
do  -- Pipeline:setErrorMode
  local pl = lurek.pipeline.newPipeline("scan")
  pl:setErrorMode("continue")
  pl:addStep(lurek.pipeline.newStep("a", function() end))
end

--@api-stub: Pipeline:getErrorMode
-- Returns the current error mode as a string.
-- Use when serialising config back out, or to assert in tests that mode propagated correctly.
do  -- Pipeline:getErrorMode
  local pl = lurek.pipeline.newPipeline("boot")
  pl:setErrorMode("continue")
  lurek.log.info("error mode: " .. pl:getErrorMode(), "boot")
end

--@api-stub: Pipeline:getResult
-- Returns the current result table built from step states, or nil.
-- Returns nil for empty pipelines; the table mirrors the run() return value (success, completed, errors).
do  -- Pipeline:getResult
  local pl = lurek.pipeline.newPipeline("boot")
  pl:addStep(lurek.pipeline.newStep("noop", function() end))
  pl:run()
  local r = pl:getResult()
  if r then lurek.log.info("completed=" .. #r.completed, "boot") end
end

--@api-stub: Pipeline:getContext
-- Returns the stored async context table, or nil.
-- The context is the table you passed to runAsync; nil means no async run is active.
do  -- Pipeline:getContext
  local pl = lurek.pipeline.newPipeline("loader")
  pl:addStep(lurek.pipeline.newStep("a", function() end))
  pl:runAsync({ progress = 0 })
  local ctx = pl:getContext()
  if ctx then lurek.log.debug("progress=" .. tostring(ctx.progress), "boot") end
end

--@api-stub: Pipeline:setOnComplete
-- Sets the callback to invoke when the pipeline completes.
-- Receives the result table; pass nil to clear. Fires once per run regardless of sync or async.
do  -- Pipeline:setOnComplete
  local pl = lurek.pipeline.newPipeline("boot")
  pl:setOnComplete(function(r)
    lurek.log.info("pipeline done: success=" .. tostring(r.success), "boot")
  end)
  pl:addStep(lurek.pipeline.newStep("noop", function() end)); pl:run()
end

--@api-stub: Pipeline:setOnStepComplete
-- Sets the callback to invoke each time a step completes successfully.
-- Receives (step_name, ctx); ideal for driving a progress bar or per-step log line.
do  -- Pipeline:setOnStepComplete
  local pl = lurek.pipeline.newPipeline("loader")
  pl:setOnStepComplete(function(name, _ctx)
    lurek.log.info("loaded: " .. name, "loader")
  end)
  pl:addStep(lurek.pipeline.newStep("textures", function() end)); pl:run()
end

--@api-stub: Pipeline:setOnStepError
-- Sets the callback to invoke each time a step fails.
-- Receives (step_name, err_msg); combine with continue mode for tolerant pipelines that log and skip.
do  -- Pipeline:setOnStepError
  local pl = lurek.pipeline.newPipeline("net")
  pl:setOnStepError(function(name, err)
    lurek.log.warn(name .. " failed: " .. err, "net")
  end)
  pl:addStep(lurek.pipeline.newStep("ping", function() error("timeout") end)); pl:run()
end

--@api-stub: Pipeline:getName
-- Returns the pipeline's name.
-- Surfaces in toAscii output and __tostring; use as a tag when emitting cross-pipeline logs.
do  -- Pipeline:getName
  local pl = lurek.pipeline.newPipeline("save_routine")
  lurek.log.info("running pipeline " .. pl:getName(), "save")
end

--@api-stub: Pipeline:setName
-- Sets the pipeline's name.
-- Useful when several pipelines share a templated builder; suffix with a scene id for clarity.
do  -- Pipeline:setName
  local pl = lurek.pipeline.newPipeline("temp")
  pl:setName("scene_" .. "forest_01")
  lurek.log.debug("pipeline renamed to " .. pl:getName(), "scene")
end

--@api-stub: Pipeline:toTable
-- Serialises the pipeline definition to a Lua table (no callbacks).
-- Pair with lurek.pipeline.fromTable for round-tripping; reattach callbacks via getStep:setCallback.
do  -- Pipeline:toTable
  local pl = lurek.pipeline.newPipeline("dump")
  pl:addStep(lurek.pipeline.newStep("a"))
  local t = pl:toTable()
  lurek.log.info("serialised name=" .. t.name .. " steps=" .. #t.steps, "boot")
end

--@api-stub: Pipeline:type
-- Returns the type name of this object.
-- Always returns "Pipeline"; cheap runtime guard before invoking pipeline-only methods on unknown values.
do  -- Pipeline:type
  local pl = lurek.pipeline.newPipeline("boot")
  if pl:type() == "Pipeline" then
    lurek.log.debug("got a pipeline userdata", "boot")
  end
end

--@api-stub: Pipeline:onProgress
-- Registers a callback invoked after every step with `(step_name, status)`.
-- Lightweight per-step hook that fires regardless of success or failure; status is a lowercase string.
do  -- Pipeline:onProgress
  local pl = lurek.pipeline.newPipeline("loader")
  pl:onProgress(function(name, status)
    lurek.log.debug(name .. " -> " .. status, "loader")
  end)
  pl:addStep(lurek.pipeline.newStep("a", function() end)); pl:run()
end

--@api-stub: Pipeline:toAscii
-- Returns a multi-line ASCII string visualising the pipeline DAG.
-- Splat into a debug overlay or build log; each row groups steps that may run in parallel.
do  -- Pipeline:toAscii
  local pl = lurek.pipeline.newPipeline("plan")
  pl:addStep(lurek.pipeline.newStep("a"))
  pl:addStep(lurek.pipeline.newStep("b"))
  lurek.log.info("\n" .. pl:toAscii(), "pipeline")
end

--@api-stub: Pipeline:typeOf
-- Returns the type identifier string of this pipeline stage object.
-- Pass "Object" to test for any pipeline-namespace value; returns true for "Pipeline" or its parents.
do  -- Pipeline:typeOf
  local pl = lurek.pipeline.newPipeline("boot")
  if pl:typeOf("Object") then
    lurek.log.debug("pipeline inherits from Object", "boot")
  end
end


--@api-stub: Pipeline:addConditional
-- Adds a step that runs only when a predicate function returns true at execution time.
-- The predicate receives the pipeline context; skip the step by returning false.
do  -- Pipeline:addConditional
  local pipe = lurek.pipeline.newPipeline("build")
  pipe:addConditional(
    "embed_symbols",
    {},
    function(ctx) end,
    function(ctx) return ctx.debugBuild == true end
  )
  lurek.log.info("conditional step added", "pipeline")
end

--@api-stub: Pipeline:addSubPipeline
-- Embeds another Pipeline as a single logical step inside this pipeline.
-- The sub-pipeline runs atomically; its error mode inherits from the parent.
do  -- Pipeline:addSubPipeline
  local parent = lurek.pipeline.newPipeline("full_build")
  local tests  = lurek.pipeline.newPipeline("test_suite")
  tests:addStep(lurek.pipeline.newStep("unit_tests", function() end))
  parent:addSubPipeline(tests, "tests", {})
  lurek.log.info("sub-pipeline embedded", "pipeline")
end

-- =============================================================================
-- STUBS: 59 uncovered lurek.pipeline API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LPipeline methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LPipeline:addStep ---------------------------------------------
--@api-stub: LPipeline:addStep
-- Adds a step to the pipeline. Returns self for chaining.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:addStep(step_ud)  -- -> Pipeline
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:removeStep ------------------------------------------
--@api-stub: LPipeline:removeStep
-- Removes a step from the pipeline by name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:removeStep("hero")
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:getStep ---------------------------------------------
--@api-stub: LPipeline:getStep
-- Returns the LuaStep wrapper for the named step, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:getStep("hero")  -- -> Step?
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:getSteps --------------------------------------------
--@api-stub: LPipeline:getSteps
-- Returns a Lua array of all step wrappers in the pipeline.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:getSteps()  -- -> table
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:getStepCount ----------------------------------------
--@api-stub: LPipeline:getStepCount
-- Returns the total number of steps.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:getStepCount()  -- -> integer
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:getStepsByTag ---------------------------------------
--@api-stub: LPipeline:getStepsByTag
-- Returns a Lua array of all steps whose tag matches the given string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:getStepsByTag("enemy")  -- -> table
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:clear -----------------------------------------------
--@api-stub: LPipeline:clear
-- Clears all steps from the pipeline.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:clear()
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:validate --------------------------------------------
--@api-stub: LPipeline:validate
-- Validates the pipeline DAG. Returns (ok, error_array).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:validate()
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:getExecutionOrder -----------------------------------
--@api-stub: LPipeline:getExecutionOrder
-- Returns the topological execution order as an array of step names.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:getExecutionOrder()
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:getParallelGroups -----------------------------------
--@api-stub: LPipeline:getParallelGroups
-- Returns parallel execution groups as a nested array of step name arrays.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:getParallelGroups()
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:run -------------------------------------------------
--@api-stub: LPipeline:run
-- Executes the pipeline synchronously in topological order.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:run([context])  -- -> table
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:runAsync --------------------------------------------
--@api-stub: LPipeline:runAsync
-- Starts an async pipeline run. Steps are executed one-per-frame via update(dt).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:runAsync([context])
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:update ----------------------------------------------
--@api-stub: LPipeline:update
-- Advances the async pipeline by one tick. Returns true when all steps are done.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:update(0.016)  -- -> boolean
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:cancel ----------------------------------------------
--@api-stub: LPipeline:cancel
-- Cancels all pending and waiting steps.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:cancel()
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:reset -----------------------------------------------
--@api-stub: LPipeline:reset
-- Resets all step states and clears the async context.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:reset()
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:isRunning -------------------------------------------
--@api-stub: LPipeline:isRunning
-- Returns true if the pipeline is currently running asynchronously.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:isRunning()  -- -> boolean
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:isComplete ------------------------------------------
--@api-stub: LPipeline:isComplete
-- Returns true if all steps have reached a terminal state.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:isComplete()  -- -> boolean
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:setErrorMode ----------------------------------------
--@api-stub: LPipeline:setErrorMode
-- Sets the pipeline error mode: "abort" or "continue".
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:setErrorMode(mode)
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:getErrorMode ----------------------------------------
--@api-stub: LPipeline:getErrorMode
-- Returns the current error mode as a string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:getErrorMode()  -- -> string
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:getResult -------------------------------------------
--@api-stub: LPipeline:getResult
-- Returns the current result table built from step states, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:getResult()  -- -> table?
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:getContext ------------------------------------------
--@api-stub: LPipeline:getContext
-- Returns the stored async context table, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:getContext()  -- -> table?
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:setOnComplete ---------------------------------------
--@api-stub: LPipeline:setOnComplete
-- Sets the callback to invoke when the pipeline completes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:setOnComplete([cb])
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:setOnStepComplete -----------------------------------
--@api-stub: LPipeline:setOnStepComplete
-- Sets the callback to invoke each time a step completes successfully.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:setOnStepComplete([cb])
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:setOnStepError --------------------------------------
--@api-stub: LPipeline:setOnStepError
-- Sets the callback to invoke each time a step fails.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:setOnStepError([cb])
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:getName ---------------------------------------------
--@api-stub: LPipeline:getName
-- Returns the pipeline's name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:getName()  -- -> string
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:setName ---------------------------------------------
--@api-stub: LPipeline:setName
-- Sets the pipeline's name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:setName("hero")
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:toTable ---------------------------------------------
--@api-stub: LPipeline:toTable
-- Serialises the pipeline definition to a Lua table (no callbacks).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:toTable()  -- -> table
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:type ------------------------------------------------
--@api-stub: LPipeline:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:type()  -- -> string
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:addConditional --------------------------------------
--@api-stub: LPipeline:addConditional
-- Adds a step with a runtime condition guard: the step is skipped when `when_fn()` returns false.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:addConditional("hero", deps_tbl, cb, cond)  -- -> Pipeline
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:onProgress ------------------------------------------
--@api-stub: LPipeline:onProgress
-- Registers a callback invoked after every step with `(step_name, status)`.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:onProgress(cb)
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:toAscii ---------------------------------------------
--@api-stub: LPipeline:toAscii
-- Returns a multi-line ASCII string visualising the pipeline DAG.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:toAscii()  -- -> string
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:addSubPipeline --------------------------------------
--@api-stub: LPipeline:addSubPipeline
-- Inlines all steps from `sub_pipeline` into this pipeline, prefixing
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:addSubPipeline(sub_ud, alias, [deps_tbl])
-- (replace lPipeline_stub with your real LPipeline instance above)

-- ---- Stub: LPipeline:typeOf ----------------------------------------------
--@api-stub: LPipeline:typeOf
-- Returns the type identifier string of this pipeline stage object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipeline_stub:typeOf("hero")  -- -> boolean
-- (replace lPipeline_stub with your real LPipeline instance above)

-- -----------------------------------------------------------------------------
-- LPipelineStep methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LPipelineStep:getName -----------------------------------------
--@api-stub: LPipelineStep:getName
-- Returns the unique name of this step
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:getName()  -- -> string
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:setCallback -------------------------------------
--@api-stub: LPipelineStep:setCallback
-- Stores a Lua function as the execute callback for this step
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:setCallback(cb)
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:setCondition ------------------------------------
--@api-stub: LPipelineStep:setCondition
-- Stores a Lua function (or nil) as the run-condition for this step
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:setCondition([cond])
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:setDelay ----------------------------------------
--@api-stub: LPipelineStep:setDelay
-- Sets the delay in seconds to wait after dependencies finish
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:setDelay(seconds)
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:getDelay ----------------------------------------
--@api-stub: LPipelineStep:getDelay
-- Returns the configured delay in seconds
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:getDelay()  -- -> number
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:setTimeout --------------------------------------
--@api-stub: LPipelineStep:setTimeout
-- Stores a timeout in seconds in the step's metadata
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:setTimeout(seconds)
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:getTimeout --------------------------------------
--@api-stub: LPipelineStep:getTimeout
-- Returns the timeout stored in metadata, or 0.0 if unset
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:getTimeout()  -- -> number
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:setRetryCount -----------------------------------
--@api-stub: LPipelineStep:setRetryCount
-- Sets the maximum number of retry attempts on failure
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:setRetryCount(10)
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:getRetryCount -----------------------------------
--@api-stub: LPipelineStep:getRetryCount
-- Returns the configured retry count
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:getRetryCount()  -- -> integer
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:setRetryDelay -----------------------------------
--@api-stub: LPipelineStep:setRetryDelay
-- Sets the delay in seconds between retry attempts
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:setRetryDelay(seconds)
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:setOptional -------------------------------------
--@api-stub: LPipelineStep:setOptional
-- Marks whether this step is optional (downstream steps continue on failure)
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:setOptional(optional)
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:isOptional --------------------------------------
--@api-stub: LPipelineStep:isOptional
-- Returns whether this step is marked as optional
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:isOptional()  -- -> boolean
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:setOnError --------------------------------------
--@api-stub: LPipelineStep:setOnError
-- Stores a Lua function (or nil) to call if this step fails
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:setOnError([cb])
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:setData -----------------------------------------
--@api-stub: LPipelineStep:setData
-- Stores an arbitrary string value under the given key in step metadata
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:setData("player_score", 42)
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:getData -----------------------------------------
--@api-stub: LPipelineStep:getData
-- Retrieves a metadata value by key, returning nil if not found
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:getData("player_score")  -- -> string?
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:setTag ------------------------------------------
--@api-stub: LPipelineStep:setTag
-- Sets the tag on this step for grouping and filtering
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:setTag("enemy")
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:getTag ------------------------------------------
--@api-stub: LPipelineStep:getTag
-- Returns the tag on this step, or nil if unset
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:getTag()  -- -> string?
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:dependsOn ---------------------------------------
--@api-stub: LPipelineStep:dependsOn
-- Adds a dependency on another step by name or PipelineStep. Returns self for chaining
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:dependsOn(dep)  -- -> Step
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:getDependencies ---------------------------------
--@api-stub: LPipelineStep:getDependencies
-- Returns the list of dependency step names
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:getDependencies()  -- -> table
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:getDependencyCount ------------------------------
--@api-stub: LPipelineStep:getDependencyCount
-- Returns the number of declared dependencies
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:getDependencyCount()  -- -> integer
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:getStatus ---------------------------------------
--@api-stub: LPipelineStep:getStatus
-- Returns the current execution status as a string
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:getStatus()  -- -> string
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:getError ----------------------------------------
--@api-stub: LPipelineStep:getError
-- Returns the error message from the last failed attempt, or nil
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:getError()  -- -> string?
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:getDuration -------------------------------------
--@api-stub: LPipelineStep:getDuration
-- Returns total seconds spent executing this step
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:getDuration()  -- -> number
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:getAttempt --------------------------------------
--@api-stub: LPipelineStep:getAttempt
-- Returns the number of execution attempts so far
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:getAttempt()  -- -> integer
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:type --------------------------------------------
--@api-stub: LPipelineStep:type
-- Returns the type name "PipelineStep"
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:type()  -- -> string
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)

-- ---- Stub: LPipelineStep:typeOf ------------------------------------------
--@api-stub: LPipelineStep:typeOf
-- Returns true when the given name matches "PipelineStep" or a parent type
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPipelineStep_stub:typeOf("hero")  -- -> boolean
-- (replace lPipelineStep_stub with your real LPipelineStep instance above)
