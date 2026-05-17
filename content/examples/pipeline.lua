-- content/examples/pipeline.lua
-- lurek.pipeline API examples: declarative task pipelines with dependency ordering, retry, branching, and async execution.
-- Run: cargo run -- content/examples/pipeline.lua

--@api-stub: lurek.pipeline.newStep
-- Creates a new pipeline step with the given name and an optional callback function
do
  -- newStep(name, callback?) creates an LPipelineStep.
  -- The callback receives a shared context table that all steps in the pipeline can read/write.
  -- Use steps to represent discrete units of work: loading assets, initializing systems, etc.
  local step = lurek.pipeline.newStep("load_audio", function(ctx)
    -- ctx is the shared pipeline context — store results here for downstream steps
    ctx.audio_loaded = true
    ctx.audio_sources = 32
  end)
  -- Tags help filter and group steps later (e.g., "skip all 'net' steps in offline mode")
  step:setTag("boot")
end

--@api-stub: lurek.pipeline.newPipeline
-- Creates a new empty pipeline with an optional name
do
  -- newPipeline(name?) creates an LPipeline that orchestrates multiple steps.
  -- Steps are added via addStep() and executed in dependency order via run() or runAsync().
  local boot = lurek.pipeline.newPipeline("boot_sequence")

  -- Build a multi-step boot pipeline for a typical game
  boot:addStep(lurek.pipeline.newStep("init_window", function(ctx)
    ctx.window_ready = true
  end))
  boot:addStep(lurek.pipeline.newStep("load_config", function(ctx)
    ctx.config = { vsync = true, volume = 0.8 }
  end))

  -- getName() returns the pipeline's identifier for logging/debugging
  lurek.log.info("pipeline '" .. boot:getName() .. "' ready with "
    .. boot:getStepCount() .. " steps", "boot")
end

--@api-stub: lurek.pipeline.fromTable
-- Creates a pipeline pre-populated with steps from a declarative table definition
do
  -- fromTable() lets you define an entire pipeline declaratively in one table.
  -- Each step entry can specify: name, deps, delay, optional, retryCount, retryDelay, async, tag, fn.
  -- This is ideal for data-driven pipelines loaded from config files.
  local def = {
    name = "save_game",
    errorMode = "abort",  -- stop on first failure ("abort" or "continue")
    steps = {
      { name = "snapshot_state", deps = {},                 fn = function(ctx) ctx.snapshot = "ok" end },
      { name = "serialize",      deps = { "snapshot_state" }, fn = function(ctx) ctx.data = "..." end },
      { name = "write_disk",     deps = { "serialize" },    tag = "io", retryCount = 2, retryDelay = 0.1,
        fn = function(ctx) ctx.saved = true end },
    },
  }
  local pl = lurek.pipeline.fromTable(def)

  -- You can still modify steps after construction
  pl:getStep("snapshot_state"):setCallback(function(ctx)
    ctx.snapshot = { player_hp = 100, gold = 42 }
  end)

  local result = pl:run()
  lurek.log.info("save pipeline success=" .. tostring(result.success), "save")
end

-- Step methods

--@api-stub: LPipeline:getName
-- Returns the name of this step.
do
  -- getName() is useful for logging which step is currently executing,
  -- especially in generic progress callbacks that handle many steps.
  local step = lurek.pipeline.newStep("hydrate_world")
  lurek.log.info("registering step: " .. step:getName(), "boot")
end

--@api-stub: LPipelineStep:setCallback
-- Sets the callback of this step.
do
  -- setCallback() replaces the step's execution function.
  -- Useful when fromTable() defines the pipeline structure but callbacks are set later,
  -- or when you want to swap behavior at runtime (e.g., mock for testing).
  local step = lurek.pipeline.newStep("warm_caches")
  step:setCallback(function(ctx)
    -- The context table is shared across all steps in the pipeline
    ctx.sprite_cache_size = 64
    ctx.audio_buffer_count = 16
    -- Return values are stored in ctx.results[step_name] automatically
    return "caches_ready"
  end)
end

--@api-stub: LPipelineStep:setCondition
-- Sets the condition of this step.
do
  -- setCondition() takes a predicate function receiving the context.
  -- If it returns false, the step is skipped (status = "skipped").
  -- Use this for conditional execution: debug-only steps, platform checks, feature flags.
  local step = lurek.pipeline.newStep("seed_demo_data", function(ctx)
    ctx.demo_entities = 50
  end)
  -- Only seed demo data when running in debug mode
  step:setCondition(function(ctx)
    return ctx.debug_mode == true
  end)
end

--@api-stub: LPipelineStep:setDelay
-- Sets the delay of this step.
do
  -- setDelay(seconds) adds a wait before the step executes (after deps are met).
  -- In async mode, this translates to yielded frames. In sync mode, it's tracked but instant.
  -- Use case: splash screen display, cooldown between network requests.
  local step = lurek.pipeline.newStep("show_logo")
  step:setDelay(2.0)  -- Wait 2 seconds before running (e.g., show splash screen)
end

--@api-stub: LPipelineStep:getDelay
-- Returns the delay of this step.
do
  local step = lurek.pipeline.newStep("fade_in")
  step:setDelay(1.25)
  -- getDelay() returns the configured delay in seconds
  lurek.log.debug("fade_in waits " .. step:getDelay() .. "s before executing", "boot")
end

--@api-stub: LPipelineStep:setTimeout
-- Sets the timeout of this step.
do
  -- setTimeout(seconds) sets a maximum wall-clock time for this step.
  -- If exceeded in async mode, the step may be marked as failed.
  -- Use for network requests or any operation that might hang.
  local step = lurek.pipeline.newStep("fetch_remote_config")
  step:setTimeout(5.0)  -- Fail if config fetch takes more than 5 seconds
  step:setRetryCount(2) -- Retry up to 2 times on timeout
end

--@api-stub: LPipelineStep:getTimeout
-- Returns the timeout of this step.
do
  local step = lurek.pipeline.newStep("download_dlc")
  step:setTimeout(30.0)
  -- getTimeout() returns 0 if no timeout is set, otherwise the seconds value
  if step:getTimeout() > 0 then
    lurek.log.info("download bounded to " .. step:getTimeout() .. "s", "net")
  end
end

--@api-stub: LPipelineStep:setRetryCount
-- Sets the retry count of this step.
do
  -- setRetryCount(n) means the step will attempt execution up to n+1 times total.
  -- Combine with setRetryDelay() for exponential-backoff-like patterns.
  -- Great for flaky network calls or file system operations.
  local step = lurek.pipeline.newStep("connect_server", function(ctx)
    ctx.online = true
  end)
  step:setRetryCount(3)    -- Retry 3 times (4 total attempts)
  step:setRetryDelay(0.5)  -- Wait 0.5s between each retry
end

--@api-stub: LPipelineStep:getRetryCount
-- Returns the number of retry items in this step.
do
  local step = lurek.pipeline.newStep("publish_score")
  step:setRetryCount(2)
  -- getRetryCount() returns the number of retries (not total attempts)
  lurek.log.info("publish_score will retry " .. step:getRetryCount() .. " times on failure", "net")
end

--@api-stub: LPipelineStep:setRetryDelay
-- Sets the retry delay of this step.
do
  -- setRetryDelay(seconds) sets the pause between retry attempts.
  -- This gives transient failures time to resolve (e.g., network congestion).
  local step = lurek.pipeline.newStep("login")
  step:setRetryCount(4)
  step:setRetryDelay(2.0)  -- 2 seconds between each login attempt
end

--@api-stub: LPipelineStep:setAsync
-- Sets the async of this step.
do
  -- setAsync(true) marks the step for coroutine-based execution.
  -- Async steps can yield between frames, allowing long operations
  -- to spread over multiple frames without blocking the game loop.
  local step = lurek.pipeline.newStep("stream_chunks", function(ctx)
    -- In async mode, the callback runs as a coroutine.
    -- Use coroutine.yield() to pause until the next update() tick.
    for i = 1, 10 do
      ctx.chunks_loaded = i
      coroutine.yield()  -- Resume next frame
    end
    return "all_chunks_loaded"
  end)
  step:setAsync(true)
end

--@api-stub: LPipelineStep:isAsync
-- Returns true if this step async.
do
  local step = lurek.pipeline.newStep("stream_chunks")
  step:setAsync(true)
  -- isAsync() checks the flag — useful when building generic pipeline runners
  lurek.log.info("async=" .. tostring(step:isAsync()), "pipeline")
end

--@api-stub: LPipelineStep:setOptional
-- Sets the optional of this step.
do
  -- setOptional(true) means this step's failure will NOT abort the pipeline.
  -- The step status will be "failed" but the pipeline continues.
  -- Use for non-critical tasks: analytics, telemetry, achievement sync.
  local step = lurek.pipeline.newStep("preload_credits", function()
    -- Even if this fails, the game can still run
  end)
  step:setOptional(true)
end

--@api-stub: LPipelineStep:isOptional
-- Returns true if this step optional.
do
  local step = lurek.pipeline.newStep("achievements_sync")
  step:setOptional(true)
  -- isOptional() lets generic handlers treat failures differently
  if step:isOptional() then
    lurek.log.debug(step:getName() .. " failure will not abort pipeline", "boot")
  end
end

--@api-stub: LPipelineStep:setOnError
-- Sets the on error of this step.
do
  -- setOnError() registers a handler called after all retries are exhausted.
  -- Receives (stepName, errorMessage). Use for logging, alerting, or fallback logic.
  local step = lurek.pipeline.newStep("load_save", function()
    error("missing save slot")
  end)
  step:setOnError(function(name, err)
    -- Custom error handling: log to file, show UI notification, trigger fallback
    lurek.log.warn("save load failed (" .. name .. "): " .. err, "save")
  end)
end

--@api-stub: LPipelineStep:setData
-- Sets the data of this step.
do
  -- setData(key, value) stores metadata on the step itself (separate from the pipeline context).
  -- Use for configuration that the step reads during execution,
  -- or for tagging steps with extra info for pipeline inspection tools.
  local step = lurek.pipeline.newStep("load_level")
  step:setData("scene", "forest_01")
  step:setData("difficulty", "normal")
  step:setData("checkpoint", "bridge_crossing")
end

--@api-stub: LPipelineStep:getData
-- Returns the data of this step.
do
  local step = lurek.pipeline.newStep("load_level")
  step:setData("scene", "forest_01")
  -- getData(key) retrieves step-level metadata; returns nil if key not found
  local scene = step:getData("scene") or "title_screen"
  lurek.log.info("loading scene: " .. scene, "scene")
end

--@api-stub: LPipelineStep:setTag
-- Sets the tag of this step.
do
  -- setTag(tag) assigns a category to the step for grouping.
  -- Combined with Pipeline:getStepsByTag(), you can manage groups of related steps.
  -- Common tags: "gpu", "audio", "net", "io", "boot", "optional"
  local step = lurek.pipeline.newStep("compile_shaders")
  step:setTag("gpu")
end

--@api-stub: LPipelineStep:getTag
-- Returns the tag of this step.
do
  local step = lurek.pipeline.newStep("warm_audio")
  step:setTag("audio")
  -- getTag() returns nil if no tag is set
  local tag = step:getTag() or "untagged"
  lurek.log.debug(step:getName() .. " tag=" .. tag, "boot")
end

--@api-stub: LPipelineStep:dependsOn
-- Performs the depends on operation on this step.
do
  -- dependsOn() declares that this step must wait for another step to complete.
  -- Accepts either a step object or a step name string.
  -- The pipeline uses these to compute topological execution order.
  local boot = lurek.pipeline.newStep("boot_system")
  local load = lurek.pipeline.newStep("load_assets")
  local render = lurek.pipeline.newStep("init_renderer")

  -- load_assets depends on boot_system (by reference)
  load:dependsOn(boot)
  -- init_renderer depends on both (by name string)
  render:dependsOn("boot_system")
  render:dependsOn("load_assets")
end

--@api-stub: LPipelineStep:getDependencies
-- Returns the dependencies of this step.
do
  local step = lurek.pipeline.newStep("present_frame")
  step:dependsOn("draw_world")
  step:dependsOn("draw_ui")
  step:dependsOn("draw_debug")
  -- getDependencies() returns an array of step name strings
  for _, dep_name in ipairs(step:getDependencies()) do
    lurek.log.debug("present_frame depends on: " .. dep_name, "render")
  end
end

--@api-stub: LPipelineStep:getDependencyCount
-- Returns the number of dependency items in this step.
do
  local step = lurek.pipeline.newStep("commit_save")
  step:dependsOn("snapshot_state")
  step:dependsOn("validate_data")
  -- getDependencyCount() is useful for quick sanity checks
  if step:getDependencyCount() == 0 then
    lurek.log.warn("commit_save has no deps — will run immediately", "save")
  else
    lurek.log.info("commit_save blocked by " .. step:getDependencyCount() .. " deps", "save")
  end
end

--@api-stub: LPipelineStep:getStatus
-- Returns the status of this step.
do
  -- getStatus() returns one of: "pending", "waiting", "running", "completed", "failed", "skipped", "cancelled"
  -- Before run(), steps are "pending". During async execution, steps transition through states.
  local pl = lurek.pipeline.newPipeline("audit")
  local s = lurek.pipeline.newStep("check_integrity", function() end)
  pl:addStep(s)
  lurek.log.info("before run: " .. s:getStatus(), "boot")  -- "pending"
  pl:run()
  lurek.log.info("after run: " .. s:getStatus(), "boot")   -- "completed"
end

--@api-stub: LPipelineStep:getError
-- Returns the error of this step.
do
  -- getError() returns nil if the step has not failed, or the error message string.
  -- Check this after pipeline execution to understand why a step failed.
  local step = lurek.pipeline.newStep("write_file", function()
    error("disk full")
  end)
  local pl = lurek.pipeline.newPipeline("io")
  pl:addStep(step)
  pl:run()
  if step:getError() then
    lurek.log.error(step:getName() .. " failed: " .. step:getError(), "io")
  end
end

--@api-stub: LPipelineStep:getDuration
-- Returns the duration of this step.
do
  -- getDuration() returns wall-clock execution time in seconds.
  -- Useful for profiling which steps are slow in your boot pipeline.
  local step = lurek.pipeline.newStep("generate_navmesh", function()
    -- Simulate work
    local sum = 0
    for i = 1, 10000 do sum = sum + i end
  end)
  local pl = lurek.pipeline.newPipeline("bench")
  pl:addStep(step)
  pl:run()
  lurek.log.info(string.format("navmesh generation took %.4fs", step:getDuration()), "perf")
end

--@api-stub: LPipelineStep:getAttempt
-- Returns the attempt of this step.
do
  -- getAttempt() returns the 1-based attempt number.
  -- After successful execution with no retries, this is 1.
  -- If retries were needed, it shows how many attempts were made.
  local step = lurek.pipeline.newStep("flaky_network", function() end)
  step:setRetryCount(2)
  local pl = lurek.pipeline.newPipeline("net")
  pl:addStep(step)
  pl:run()
  lurek.log.debug("flaky_network completed on attempt " .. step:getAttempt(), "net")
end

--@api-stub: LPipeline:type
-- Returns the Lua-visible type name string for this step handle.
do
  -- type() returns "LPipelineStep" — useful for type-checking userdata
  local step = lurek.pipeline.newStep("init")
  assert(step:type() == "LPipelineStep", "unexpected type")
end

--@api-stub: LPipeline:typeOf
-- Returns true if this step handle matches the given type name string.
do
  -- typeOf() accepts "LPipelineStep", "PipelineStep", or "Object"
  -- Useful for polymorphic code that accepts different userdata types
  local step = lurek.pipeline.newStep("init")
  assert(step:typeOf("PipelineStep") == true)
  assert(step:typeOf("Object") == true)
  assert(step:typeOf("LPipeline") == false)
end

-- Pipeline methods

--@api-stub: LPipeline:addStep
-- Adds a step to this pipeline.
do
  -- addStep() returns self, so you can chain calls for concise pipeline construction.
  -- Steps are identified by name — duplicates will overwrite.
  local pl = lurek.pipeline.newPipeline("boot")
  pl:addStep(lurek.pipeline.newStep("read_config", function(ctx)
    ctx.cfg = { resolution = "1080p" }
  end))
    :addStep(lurek.pipeline.newStep("init_audio", function(ctx)
      ctx.audio_ready = true
    end))
    :addStep(lurek.pipeline.newStep("load_fonts", function(ctx)
      ctx.fonts_loaded = true
    end))
end

--@api-stub: LPipeline:removeStep
-- Removes a step from this pipeline.
do
  -- removeStep(name) removes a step by name.
  -- WARNING: other steps depending on the removed step will fail or be skipped at run time.
  -- Use validate() after removal to catch broken dependencies.
  local pl = lurek.pipeline.newPipeline("boot")
  pl:addStep(lurek.pipeline.newStep("legacy_drm_check", function() end))
  pl:addStep(lurek.pipeline.newStep("init_game", function() end))
  -- Remove the obsolete DRM step
  pl:removeStep("legacy_drm_check")
end

--@api-stub: LPipeline:getStep
-- Returns the step of this pipeline.
do
  -- getStep(name) retrieves an LPipelineStep by name, or nil if not found.
  -- Use this to modify steps after constructing a pipeline from a table definition.
  local pl = lurek.pipeline.fromTable({ steps = {
    { name = "load_textures", deps = {} },
    { name = "build_atlas",   deps = { "load_textures" } },
  } })
  local atlas_step = pl:getStep("build_atlas")
  if atlas_step then
    atlas_step:setCallback(function(ctx)
      ctx.atlas = { width = 2048, height = 2048, sprites = 128 }
    end)
  end
end

--@api-stub: LPipeline:getSteps
-- Returns the steps of this pipeline.
do
  -- getSteps() returns an array of all LPipelineStep objects in the pipeline.
  -- Useful for iteration, debugging, or building custom progress displays.
  local pl = lurek.pipeline.newPipeline("loader")
  pl:addStep(lurek.pipeline.newStep("textures", function() end))
  pl:addStep(lurek.pipeline.newStep("sounds", function() end))
  pl:addStep(lurek.pipeline.newStep("scripts", function() end))
  for i, step in ipairs(pl:getSteps()) do
    lurek.log.debug(i .. ": " .. step:getName(), "loader")
  end
end

--@api-stub: LPipeline:getStepCount
-- Returns the number of step items in this pipeline.
do
  -- getStepCount() returns how many steps are in the pipeline.
  -- Use as a guard before run() to avoid running empty pipelines.
  local pl = lurek.pipeline.newPipeline("dynamic")
  if pl:getStepCount() == 0 then
    lurek.log.warn("empty pipeline — nothing to execute", "boot")
  end
end

--@api-stub: LPipeline:getStepsByTag
-- Returns the steps by tag of this pipeline.
do
  -- getStepsByTag(tag) filters steps by their assigned tag.
  -- Use to selectively disable, inspect, or report on groups of steps.
  local pl = lurek.pipeline.newPipeline("boot")
  local s1 = lurek.pipeline.newStep("connect_lobby"); s1:setTag("net"); pl:addStep(s1)
  local s2 = lurek.pipeline.newStep("upload_stats");  s2:setTag("net"); pl:addStep(s2)
  local s3 = lurek.pipeline.newStep("load_shaders");  s3:setTag("gpu"); pl:addStep(s3)

  -- Get all network steps to mark them optional in offline mode
  for _, net_step in ipairs(pl:getStepsByTag("net")) do
    net_step:setOptional(true)
  end
end

--@api-stub: LPipeline:clear
-- Clears all items from this pipeline.
do
  -- clear() removes all steps, resetting the pipeline to empty.
  -- Use when you want to rebuild a pipeline dynamically each level.
  local pl = lurek.pipeline.newPipeline("level_loader")
  pl:addStep(lurek.pipeline.newStep("old_level", function() end))
  pl:clear()
  -- Now add steps for the new level
  pl:addStep(lurek.pipeline.newStep("new_level", function() end))
end

--@api-stub: LPipeline:validate
-- Performs the validate operation on this pipeline.
do
  -- validate() checks for missing dependencies and circular references.
  -- Returns (ok, errors): ok is true if valid, errors is an array of strings.
  -- Always validate after dynamic construction before calling run().
  local pl = lurek.pipeline.newPipeline("check")
  local orphan = lurek.pipeline.newStep("render")
  orphan:dependsOn("missing_step")  -- This dependency does not exist
  pl:addStep(orphan)

  local ok, errs = pl:validate()
  if not ok then
    for _, e in ipairs(errs or {}) do
      lurek.log.error("validation: " .. e, "pipeline")
    end
  end
end

--@api-stub: LPipeline:getExecutionOrder
-- Returns the execution order of this pipeline.
do
  -- getExecutionOrder() computes topological sort of all steps.
  -- Returns (order, err): order is an array of step name strings, err is nil on success.
  -- Useful for previewing what will run and in what sequence.
  local pl = lurek.pipeline.newPipeline("render_frame")
  local clear = lurek.pipeline.newStep("clear_buffers"); pl:addStep(clear)
  local draw  = lurek.pipeline.newStep("draw_sprites");  draw:dependsOn("clear_buffers"); pl:addStep(draw)
  local post  = lurek.pipeline.newStep("post_process");  post:dependsOn("draw_sprites"); pl:addStep(post)
  local present = lurek.pipeline.newStep("present");     present:dependsOn("post_process"); pl:addStep(present)

  local order, err = pl:getExecutionOrder()
  if err then
    lurek.log.error("cycle detected: " .. err, "pipeline")
  else
    lurek.log.info("execution order: " .. table.concat(order, " -> "), "pipeline")
  end
end

--@api-stub: LPipeline:getParallelGroups
-- Returns the parallel groups of this pipeline.
do
  -- getParallelGroups() groups steps into tiers that can run concurrently.
  -- Steps within the same tier have no mutual dependencies.
  -- Useful for visualizing pipeline parallelism or building progress bars.
  local pl = lurek.pipeline.newPipeline("asset_load")
  pl:addStep(lurek.pipeline.newStep("textures", function() end))
  pl:addStep(lurek.pipeline.newStep("sounds", function() end))
  pl:addStep(lurek.pipeline.newStep("scripts", function() end))
  -- All three have no deps, so they form one parallel group
  local groups, err = pl:getParallelGroups()
  if not err then
    lurek.log.info("parallel tiers: " .. #groups .. ", first tier has " .. #groups[1] .. " steps", "pipeline")
  end
end

--@api-stub: LPipeline:run
-- Starts the operation managed by this pipeline.
do
  -- run(context?) executes all steps synchronously in dependency order.
  -- Blocks until all steps complete, fail, or are cancelled.
  -- The optional context table is shared across all step callbacks.
  -- Returns a result table with: success, completed, failed, skipped, cancelled, totalDuration, errors.
  local pl = lurek.pipeline.newPipeline("game_boot")
  pl:addStep(lurek.pipeline.newStep("init", function(ctx) ctx.initialized = true end))
  pl:addStep(lurek.pipeline.newStep("load", function(ctx) ctx.assets = 42 end))

  -- Pass initial context with user info
  local result = pl:run({ user = "player1", debug_mode = false })
  lurek.log.info("boot success=" .. tostring(result.success)
    .. " duration=" .. string.format("%.3fs", result.totalDuration), "boot")
end

--@api-stub: LPipeline:runAsync
-- Performs the run async operation on this pipeline.
do
  -- runAsync(context?) starts coroutine-based execution.
  -- You must call pipeline:update(dt) each frame to advance steps.
  -- Async steps can yield between frames using coroutine.yield().
  -- Use for loading screens where you want to show progress per frame.
  local pl = lurek.pipeline.newPipeline("loading_screen")
  pl:addStep(lurek.pipeline.newStep("load_world", function(ctx)
    ctx.world_ready = true
  end))
  pl:runAsync({ progress = 0 })
  -- In a real game, update() would be called from lurek.process(dt)
end

--@api-stub: LPipeline:update
-- Advances this pipeline by the given delta time.
do
  -- update(dt) advances the async pipeline by one frame.
  -- Returns true when ALL steps have finished (pipeline is complete).
  -- Call this every frame from lurek.process(dt) after runAsync().
  local pl = lurek.pipeline.newPipeline("loader")
  pl:addStep(lurek.pipeline.newStep("scan_files", function() end))
  pl:runAsync()

  -- Typical game loop integration:
  local done = false
  function lurek.process(dt)
    if not done and pl:update(dt) then
      done = true
      lurek.log.info("loading complete — transitioning to gameplay", "boot")
    end
  end
end

--@api-stub: LPipeline:cancel
-- Cancels the current operation of this pipeline.
do
  -- cancel() stops all pending/waiting steps. Already-running or completed steps are unaffected.
  -- Use when the player cancels a loading screen or disconnects.
  local pl = lurek.pipeline.newPipeline("multiplayer_join")
  pl:addStep(lurek.pipeline.newStep("handshake", function() end))
  pl:addStep(lurek.pipeline.newStep("sync_state", function() end))
  pl:runAsync()
  -- Player pressed Escape — cancel remaining work
  pl:cancel()
end

--@api-stub: LPipeline:reset
-- Resets this pipeline to its default state.
do
  -- reset() clears all step statuses back to "pending" and removes context.
  -- Lets you re-run the same pipeline (e.g., retry a failed boot, reload a level).
  local pl = lurek.pipeline.newPipeline("level_pipeline")
  pl:addStep(lurek.pipeline.newStep("load_map", function(ctx) ctx.map = "level_1" end))
  pl:run()
  -- Player finished the level — reset and run again for level 2
  pl:reset()
  pl:run({ level = 2 })
end

--@api-stub: LPipeline:isRunning
-- Returns true if this pipeline is currently running.
do
  -- isRunning() returns true between runAsync() and completion.
  -- Use to guard against double-starting or to show loading indicators.
  local pl = lurek.pipeline.newPipeline("loader")
  pl:addStep(lurek.pipeline.newStep("work", function() end))
  pl:runAsync()
  if pl:isRunning() then
    lurek.log.debug("loader is in progress — showing spinner", "ui")
  end
end

--@api-stub: LPipeline:isComplete
-- Returns true if this pipeline complete.
do
  -- isComplete() returns true when all steps are in a terminal state
  -- (completed, failed, skipped, or cancelled).
  local pl = lurek.pipeline.newPipeline("boot")
  pl:addStep(lurek.pipeline.newStep("init", function() end))
  pl:run()
  assert(pl:isComplete(), "pipeline should be done after synchronous run()")
end

--@api-stub: LPipeline:setErrorMode
-- Sets the error mode of this pipeline.
do
  -- setErrorMode("abort"|"continue") controls failure behavior.
  -- "abort" (default): stop the pipeline on the first step failure.
  -- "continue": keep running remaining steps even if some fail.
  -- Use "continue" when steps are independent (e.g., loading optional assets).
  local pl = lurek.pipeline.newPipeline("asset_loader")
  pl:setErrorMode("continue")  -- Keep loading even if one asset fails
  pl:addStep(lurek.pipeline.newStep("load_music", function() end))
  pl:addStep(lurek.pipeline.newStep("load_sfx", function() end))
end

--@api-stub: LPipeline:getErrorMode
-- Returns the error mode of this pipeline.
do
  local pl = lurek.pipeline.newPipeline("boot")
  pl:setErrorMode("continue")
  -- getErrorMode() returns "abort" or "continue"
  lurek.log.info("error mode: " .. pl:getErrorMode(), "boot")
end

--@api-stub: LPipeline:getResult
-- Returns the result of this pipeline.
do
  -- getResult() returns the result summary table after (or during async) execution.
  -- Fields: success (bool), completed/failed/skipped/cancelled (arrays), totalDuration, errors.
  local pl = lurek.pipeline.newPipeline("boot")
  pl:addStep(lurek.pipeline.newStep("step_a", function() end))
  pl:addStep(lurek.pipeline.newStep("step_b", function() error("oops") end))
  pl:setErrorMode("continue")
  pl:run()
  local r = pl:getResult()
  if r then
    lurek.log.info("completed: " .. #r.completed .. ", failed: " .. #r.failed, "boot")
  end
end

--@api-stub: LPipeline:getContext
-- Returns the context of this pipeline.
do
  -- getContext() returns the shared table used by the current/most recent run.
  -- Useful in callbacks or external code that needs to read pipeline state.
  local pl = lurek.pipeline.newPipeline("loader")
  pl:addStep(lurek.pipeline.newStep("init", function(ctx)
    ctx.progress = 0.5
  end))
  pl:runAsync({ player_name = "hero" })
  local ctx = pl:getContext()
  if ctx then
    lurek.log.debug("player=" .. tostring(ctx.player_name), "boot")
  end
end

--@api-stub: LPipeline:setOnComplete
-- Sets the on complete of this pipeline.
do
  -- setOnComplete(callback) registers a handler called when the entire pipeline finishes.
  -- The callback receives the result table. Pass nil to remove.
  -- Use for scene transitions, cleanup, or final state setup.
  local pl = lurek.pipeline.newPipeline("boot")
  pl:setOnComplete(function(result)
    if result.success then
      lurek.log.info("boot complete in " .. string.format("%.2fs", result.totalDuration), "boot")
    else
      lurek.log.error("boot failed with " .. #result.errors .. " errors", "boot")
    end
  end)
  pl:addStep(lurek.pipeline.newStep("init", function() end))
  pl:run()
end

--@api-stub: LPipeline:setOnStepComplete
-- Sets the on step complete of this pipeline.
do
  -- setOnStepComplete(callback) fires after each step succeeds.
  -- Receives (stepName, context). Use for progress bars or incremental UI updates.
  local pl = lurek.pipeline.newPipeline("loader")
  local total_steps = 3
  local completed = 0
  pl:setOnStepComplete(function(name, ctx)
    completed = completed + 1
    ctx.progress = completed / total_steps
    lurek.log.info(string.format("progress: %d%% (%s done)", ctx.progress * 100, name), "loader")
  end)
  pl:addStep(lurek.pipeline.newStep("textures", function() end))
  pl:addStep(lurek.pipeline.newStep("audio",    function() end))
  pl:addStep(lurek.pipeline.newStep("scripts",  function() end))
  pl:run()
end

--@api-stub: LPipeline:setOnStepError
-- Sets the on step error of this pipeline.
do
  -- setOnStepError(callback) fires when any step fails.
  -- Receives (stepName, errorMessage). Use for centralized error reporting.
  local pl = lurek.pipeline.newPipeline("net")
  pl:setErrorMode("continue")
  pl:setOnStepError(function(name, err)
    lurek.log.warn("[" .. name .. "] failed: " .. err, "net")
  end)
  pl:addStep(lurek.pipeline.newStep("connect", function() error("timeout") end))
  pl:addStep(lurek.pipeline.newStep("fetch_data", function() end))
  pl:run()
end

--@api-stub: LPipeline:getName
-- Returns the name of this pipeline.
do
  local pl = lurek.pipeline.newPipeline("save_routine")
  -- getName() returns the pipeline identifier string
  lurek.log.info("executing pipeline: " .. pl:getName(), "save")
end

--@api-stub: LPipeline:setName
-- Sets the name of this pipeline.
do
  -- setName() changes the pipeline's name at runtime.
  -- Useful when reusing a generic pipeline for different contexts.
  local pl = lurek.pipeline.newPipeline("temp")
  pl:setName("scene_forest_01")
  lurek.log.debug("pipeline renamed to: " .. pl:getName(), "scene")
end

--@api-stub: LPipeline:toTable
-- Performs the to table operation on this pipeline.
do
  -- toTable() serializes the pipeline configuration for inspection or persistence.
  -- Returns a table with: name, errorMode, and steps array.
  -- Use for saving pipeline definitions, debugging, or generating documentation.
  local pl = lurek.pipeline.newPipeline("boot")
  pl:addStep(lurek.pipeline.newStep("init"))
  pl:addStep(lurek.pipeline.newStep("load"))
  local t = pl:toTable()
  lurek.log.info("serialized: name=" .. t.name .. ", steps=" .. #t.steps, "debug")
end

--@api-stub: LPipeline:type
-- Returns the Lua-visible type name string for this pipeline handle.
do
  local pl = lurek.pipeline.newPipeline("boot")
  -- type() returns "LPipeline" for pipeline userdata
  assert(pl:type() == "LPipeline")
end

--@api-stub: LPipeline:onProgress
-- Fires the callback registered for the progress event on this pipeline.
do
  -- onProgress(callback) fires after each step finishes (any outcome).
  -- Receives (stepName, statusString). Use for generic progress tracking.
  local pl = lurek.pipeline.newPipeline("loader")
  pl:onProgress(function(name, status)
    -- status is "completed", "failed", "skipped", etc.
    lurek.log.debug(name .. " -> " .. status, "loader")
  end)
  pl:addStep(lurek.pipeline.newStep("scan", function() end))
  pl:addStep(lurek.pipeline.newStep("parse", function() end))
  pl:run()
end

--@api-stub: LPipeline:onEvent
-- Fires the callback registered for the event event on this pipeline.
do
  -- onEvent(callback) is a low-level lifecycle hook for all pipeline events.
  -- Receives (eventName, stepName, status, detail).
  -- Use for detailed logging, telemetry, or custom pipeline visualization.
  local pl = lurek.pipeline.newPipeline("instrumented")
  pl:onEvent(function(event_name, step_name, status, detail)
    lurek.log.debug(string.format("[%s] %s: %s (%s)",
      event_name, step_name, status, tostring(detail)), "trace")
  end)
  pl:addStep(lurek.pipeline.newStep("work", function() end))
  pl:run()
end

--@api-stub: LPipeline:toAscii
-- Performs the to ascii operation on this pipeline.
do
  -- toAscii() returns an ASCII-art diagram of the pipeline's dependency graph.
  -- Useful for debugging complex pipelines in the console.
  local pl = lurek.pipeline.newPipeline("render")
  local clear = lurek.pipeline.newStep("clear"); pl:addStep(clear)
  local draw  = lurek.pipeline.newStep("draw"); draw:dependsOn("clear"); pl:addStep(draw)
  local post  = lurek.pipeline.newStep("post"); post:dependsOn("draw"); pl:addStep(post)
  -- Print the dependency graph visualization
  lurek.log.info("\n" .. pl:toAscii(), "pipeline")
end

--@api-stub: LPipeline:typeOf
-- Returns true if this pipeline handle matches the given type name string.
do
  -- typeOf() accepts "LPipeline", "Pipeline", or "Object"
  local pl = lurek.pipeline.newPipeline("boot")
  assert(pl:typeOf("Pipeline") == true)
  assert(pl:typeOf("Object") == true)
  assert(pl:typeOf("LPipelineStep") == false)
end


--@api-stub: LPipeline:addConditional
-- Adds a conditional to this pipeline.
do
  -- addConditional(name, deps, callback, condition) is a convenience for:
  --   creating a step, setting its dependencies, callback, AND condition in one call.
  -- The step only runs if condition(ctx) returns true.
  local pipe = lurek.pipeline.newPipeline("build")
  pipe:addConditional(
    "embed_debug_symbols",
    { },  -- no dependencies
    function(ctx)
      -- This callback only runs if the condition below returns true
      ctx.symbols_embedded = true
    end,
    function(ctx)
      -- Condition: only embed symbols in debug builds
      return ctx.debug_build == true
    end
  )
  pipe:run({ debug_build = true })
end

--@api-stub: LPipeline:addBranch
-- Adds a branch to this pipeline.
do
  -- addBranch(name, deps, when, thenFn, elseFn?) creates an if/else branch in the pipeline.
  -- Internally generates guard/then/else sub-steps with proper dependency wiring.
  -- Use for build-mode selection, platform-specific paths, or difficulty scaling.
  local pipe = lurek.pipeline.newPipeline("build_system")
  local mode_selected = "release"  -- capture inside callbacks since getContext() is nil after sync run()
  pipe:addBranch(
    "build_mode",          -- branch name
    {},                    -- dependencies (none here)
    function(ctx)          -- predicate: true = then, false = else
      return ctx.debug_build == true
    end,
    function(ctx)          -- then: debug path
      ctx.mode = "debug"
      ctx.optimizations = false
      mode_selected = "debug"
    end,
    function(ctx)          -- else: release path
      ctx.mode = "release"
      ctx.optimizations = true
      mode_selected = "release"
    end
  )
  pipe:run({ debug_build = false })
  lurek.log.info("build mode selected: " .. mode_selected, "build")
end

--@api-stub: LPipeline:addSubPipeline
-- Adds a sub pipeline to this pipeline.
do
  -- addSubPipeline(subPipeline, alias, deps?) embeds another pipeline's steps.
  -- Steps are prefixed with the alias to avoid name collisions.
  -- Use for composing complex pipelines from reusable sub-pipelines.
  local test_suite = lurek.pipeline.newPipeline("tests")
  test_suite:addStep(lurek.pipeline.newStep("unit_tests", function(ctx) ctx.unit_ok = true end))
  test_suite:addStep(lurek.pipeline.newStep("integration", function(ctx) ctx.int_ok = true end))

  local full_build = lurek.pipeline.newPipeline("full_build")
  full_build:addStep(lurek.pipeline.newStep("compile", function(ctx) ctx.compiled = true end))
  -- Embed test_suite under "tests" prefix, depending on "compile"
  full_build:addSubPipeline(test_suite, "tests", { "compile" })

  local result = full_build:run()
  lurek.log.info("full build success=" .. tostring(result.success), "build")
end

-- -----------------------------------------------------------------------------
-- LPipelineStep methods
-- -----------------------------------------------------------------------------

--@api-stub: LPipeline:getName
-- Returns the unique name of this pipeline step
do
  -- Identical to Step:getName — included here for the LPipelineStep class reference.
  local step = lurek.pipeline.newStep("load_assets", function() end)
  lurek.log.info("step name=" .. step:getName(), "pipeline")
end
--@api-stub: LPipelineStep:setCallback
-- Sets the main execution function for this step
do
  -- The callback receives the shared context table and may return a value
  -- stored in ctx.results[step_name].
  local step = lurek.pipeline.newStep("process")
  step:setCallback(function(ctx)
    ctx.processed = true
    return "done"  -- Stored in ctx.results["process"]
  end)
end
--@api-stub: LPipelineStep:setCondition
-- Sets a predicate function that determines whether this step should execute
do
  -- If the condition returns false, the step is skipped with status "skipped".
  local step = lurek.pipeline.newStep("optional_analytics", function(ctx)
    ctx.analytics_sent = true
  end)
  step:setCondition(function(ctx)
    return ctx.online == true  -- Only run when online
  end)
end
--@api-stub: LPipelineStep:setDelay
-- Sets a delay in seconds before this step begins execution after its dependencies are satisfied
do
  -- Delay is honored in async mode (frames are skipped until delay elapses).
  local step = lurek.pipeline.newStep("delayed_transition", function() end)
  step:setDelay(0.5)  -- Half-second pause before executing
end
--@api-stub: LPipelineStep:getDelay
-- Returns the configured delay for this step
do
  local step = lurek.pipeline.newStep("fetch_data", function() end)
  step:setDelay(1.0)
  lurek.log.info("configured delay: " .. step:getDelay() .. "s", "pipeline")
end
--@api-stub: LPipelineStep:setTimeout
-- Sets a maximum execution time for this step
do
  -- If the step exceeds this time in async mode, it may be failed.
  local step = lurek.pipeline.newStep("network_call", function() end)
  step:setTimeout(5.0)
end
--@api-stub: LPipelineStep:getTimeout
-- Returns the configured timeout for this step, or 0 if none is set
do
  local step = lurek.pipeline.newStep("upload_replay", function() end)
  step:setTimeout(10.0)
  lurek.log.info("timeout=" .. step:getTimeout() .. "s", "pipeline")
end
--@api-stub: LPipelineStep:setRetryCount
-- Sets how many times this step should be retried after a failure before being marked as failed
do
  -- retryCount=3 means up to 4 total attempts (1 initial + 3 retries).
  local step = lurek.pipeline.newStep("fetch_leaderboard", function() end)
  step:setRetryCount(3)
end
--@api-stub: LPipelineStep:getRetryCount
-- Returns the configured retry count for this step
do
  local step = lurek.pipeline.newStep("save_progress", function() end)
  step:setRetryCount(2)
  lurek.log.info("retry_count=" .. step:getRetryCount(), "pipeline")
end
--@api-stub: LPipelineStep:setRetryDelay
-- Sets the delay in seconds between retry attempts for this step
do
  -- Combine with setRetryCount for controlled retry spacing.
  local step = lurek.pipeline.newStep("send_score", function() end)
  step:setRetryCount(3)
  step:setRetryDelay(1.0)  -- 1 second between each retry
end
--@api-stub: LPipelineStep:setOptional
-- Marks this step as optional
do
  -- Optional steps do not abort the pipeline on failure.
  local step = lurek.pipeline.newStep("telemetry", function() end)
  step:setOptional(true)
end
--@api-stub: LPipelineStep:isOptional
-- Returns whether this step is marked as optional
do
  local step = lurek.pipeline.newStep("analytics", function() end)
  step:setOptional(true)
  lurek.log.info("optional=" .. tostring(step:isOptional()), "pipeline")
end
--@api-stub: LPipelineStep:setOnError
-- Sets an error handler callback invoked when this step fails after all retries are exhausted
do
  -- The error handler receives (stepName, errorMessage).
  local step = lurek.pipeline.newStep("critical_save", function()
    error("write failed")
  end)
  step:setOnError(function(name, err)
    lurek.log.error(name .. " error: " .. tostring(err), "save")
  end)
end
--@api-stub: LPipelineStep:setData
-- Stores a key-value metadata pair on this step
do
  -- Step-level metadata is separate from the pipeline context.
  -- Use for static config the step reads, or for external tooling.
  local step = lurek.pipeline.newStep("load_level", function() end)
  step:setData("level_id", "dungeon_3")
  step:setData("biome", "volcanic")
end
--@api-stub: LPipelineStep:getData
-- Retrieves a metadata value previously stored with setData
do
  local step = lurek.pipeline.newStep("init_renderer", function() end)
  step:setData("backend", "wgpu")
  local backend = step:getData("backend")
  lurek.log.info("renderer backend: " .. tostring(backend), "pipeline")
end
--@api-stub: LPipelineStep:setTag
-- Assigns a tag string to this step for grouping and filtering purposes
do
  -- Tags enable Pipeline:getStepsByTag() filtering.
  local step = lurek.pipeline.newStep("warmup_shader", function() end)
  step:setTag("gpu")
end
--@api-stub: LPipelineStep:getTag
-- Returns the tag assigned to this step, or nil if none is set
do
  local step = lurek.pipeline.newStep("decode_audio", function() end)
  step:setTag("audio")
  lurek.log.info("tag=" .. tostring(step:getTag()), "pipeline")
end
--@api-stub: LPipelineStep:dependsOn
-- Declares that this step depends on another step (by name or reference)
do
  -- dependsOn() returns self for chaining multiple dependencies.
  local a = lurek.pipeline.newStep("load_textures", function() end)
  local b = lurek.pipeline.newStep("build_atlas", function() end)
  b:dependsOn(a)  -- build_atlas waits for load_textures
end
--@api-stub: LPipelineStep:getDependencies
-- Returns a list of step names that this step depends on
do
  local step = lurek.pipeline.newStep("final_render", function() end)
  step:dependsOn("draw_world")
  step:dependsOn("draw_particles")
  local deps = step:getDependencies()
  lurek.log.info("deps: " .. table.concat(deps, ", "), "pipeline")
end
--@api-stub: LPipelineStep:getDependencyCount
-- Returns the number of dependencies this step has
do
  local a = lurek.pipeline.newStep("step_a", function() end)
  local b = lurek.pipeline.newStep("step_b", function() end)
  local c = lurek.pipeline.newStep("step_c", function() end)
  c:dependsOn(a):dependsOn(b)
  lurek.log.info("step_c has " .. c:getDependencyCount() .. " dependencies", "pipeline")
end
--@api-stub: LPipelineStep:getStatus
-- Returns the current execution status of this step as a string ("pending", "waiting", "running", "completed", "failed", "skipped", "cancelled")
do
  -- Before pipeline execution, all steps are "pending".
  local step = lurek.pipeline.newStep("build_nav", function() end)
  lurek.log.info("initial status: " .. step:getStatus(), "pipeline")
end
--@api-stub: LPipelineStep:getError
-- Returns the error message if this step failed, or nil if it has not failed
do
  local step = lurek.pipeline.newStep("connect", function() end)
  -- nil when not failed
  local err = step:getError()
  lurek.log.info("error=" .. tostring(err), "pipeline")
end
--@api-stub: LPipelineStep:getDuration
-- Returns how long this step took to execute in seconds (measured from start to completion or failure)
do
  -- Duration is 0 before execution.
  local step = lurek.pipeline.newStep("gen_terrain", function() end)
  lurek.log.info("duration before run: " .. step:getDuration() .. "s", "pipeline")
end
--@api-stub: LPipelineStep:getAttempt
-- Returns the current attempt number (1-based)
do
  -- Attempt is 0 before execution, then 1+ during/after.
  local step = lurek.pipeline.newStep("login", function() end)
  lurek.log.info("attempt=" .. step:getAttempt(), "pipeline")
end
--@api-stub: LPipeline:type
-- Returns the type name of this object ("LPipelineStep")
do
  local step = lurek.pipeline.newStep("test_step", function() end)
  assert(step:type() == "LPipelineStep")
end
--@api-stub: LPipeline:typeOf
-- Checks whether this object is of a given type name
do
  -- Accepts "LPipelineStep", "PipelineStep", or "Object"
  local step = lurek.pipeline.newStep("check_step", function() end)
  assert(step:typeOf("PipelineStep") == true)
  assert(step:typeOf("Object") == true)
  assert(step:typeOf("Unknown") == false)
end

--@api-stub: LPipelineStep:setAsync
-- Marks this step as asynchronous
do
  -- Async steps run as coroutines and can yield() between frames.
  local step = lurek.pipeline.newStep("stream_data", function(ctx)
    for i = 1, 5 do
      ctx.chunks = i
      coroutine.yield()
    end
  end)
  step:setAsync(true)
end

--@api-stub: LPipelineStep:isAsync
-- Returns whether this step is configured for asynchronous coroutine execution
do
  local step = lurek.pipeline.newStep("transform", function(ctx) return ctx end)
  step:setAsync(true)
  assert(step:isAsync() == true)
end

print("content/examples/pipeline.lua")

-- =============================================================================
-- STUBS: 35 uncovered lurek.pipeline API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LPipeline methods
-- -----------------------------------------------------------------------------
