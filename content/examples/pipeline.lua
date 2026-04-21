-- content/examples/pipeline.lua
-- Lurek2D lurek.pipeline API Reference
-- Run with: cargo run -- content/examples/pipeline

-- Create a load_assets step that reads texture atlases from disk so
-- the level pipeline can depend on it before spawning entities.
local step_load = lurek.pipeline.newStep("load_assets", function(ctx)
    print("  [load_assets] loading textures...")
    ctx.textures_ready = true
end)
print("step created:", step_load:getName())

-- Create a level-load pipeline that sequences asset loading, entity
-- spawning, and AI initialisation in dependency order.
local pipe = lurek.pipeline.newPipeline("level_load")
print("pipeline:", pipe:getName())

-- Restore a saved pipeline definition from a TOML-decoded table so
-- the same asset pipeline can be re-run across multiple levels.
local def = {
    name  = "asset_pipeline",
    steps = {
        { name = "load_sprites",  deps = {},               tag = "assets" },
        { name = "load_audio",    deps = {},               tag = "assets" },
        { name = "spawn_entities",deps = {"load_sprites"}, tag = "scene"  },
    }
}
local restored_pipe = lurek.pipeline.fromTable(def)
print("restored pipeline:", restored_pipe:getName())

-- -----------------------------------------------------------------------------
-- Pipeline methods
-- -----------------------------------------------------------------------------

-- Rename the pipeline after loading it from a generic def table so
-- the progress log identifies the level it belongs to.
pipe:setName("dungeon_level_1")
print("renamed:", pipe:getName())

-- Read the pipeline name in the progress callback to prefix log lines
-- with the active pipeline so output from parallel pipelines is distinguishable.
print("pipeline name:", pipe:getName())

-- Set the pipeline to "continue" mode so optional asset-download steps
-- don't abort the whole level load when the CDN is unavailable.
pipe:setErrorMode("continue")
print("error mode:", pipe:getErrorMode())

-- Read the error mode before running to log whether a step failure
-- will abort or continue the rest of the pipeline.
print("error mode check:", pipe:getErrorMode())

-- Register the asset-loading step first so entity spawning can declare
-- a dependency on it and only run after assets are ready.
local step_spawn = lurek.pipeline.newStep("spawn_entities", function(ctx)
    print("  [spawn_entities] spawning player and enemies...")
    ctx.entities_ready = true
end)
local step_ai = lurek.pipeline.newStep("init_ai", function(ctx)
    print("  [init_ai] initialising pathfinders...")
end)
pipe:addStep(step_load)
pipe:addStep(step_spawn)
pipe:addStep(step_ai)
print("steps after addStep:", pipe:getStepCount())

-- Add an optional background-music preload step that only runs when
-- the config flag for music is enabled.
local music_enabled = true
pipe:addConditional("preload_music", {}, function(ctx)
    print("  [preload_music] buffering music track...")
end, function() return music_enabled end)
print("steps with conditional:", pipe:getStepCount())

-- Drop the debug-overlay step from the pipeline in release builds
-- so it does not consume time in the shipped game.
local pipe2 = lurek.pipeline.newPipeline("test_remove")
local tmp_step = lurek.pipeline.newStep("debug_overlay", function(ctx) end)
pipe2:addStep(tmp_step)
pipe2:removeStep("debug_overlay")
print("steps after remove:", pipe2:getStepCount())

-- Look up the spawn_entities step by name to adjust its retry count
-- after profiling shows it occasionally times out on a slow machine.
local spawn_step = pipe:getStep("spawn_entities")
print("got step:", spawn_step ~= nil)

-- Iterate all steps to print a pre-run checklist in the dev console
-- so the team can verify the pipeline structure before profiling.
local all_steps = pipe:getSteps()
print("all steps:")
for _, s in ipairs(all_steps) do print("  -", s:getName()) end

-- Read the step count before running to set the progress bar maximum
-- in the loading screen UI.
print("step count:", pipe:getStepCount())

-- Retrieve all "assets" tagged steps to cancel only asset-related
-- work when the player exits back to the main menu mid-load.
local asset_steps = pipe:getStepsByTag("assets")
print("steps tagged 'assets':", #asset_steps)

-- Validate the pipeline DAG before running to detect missing
-- dependency references that would cause a runtime deadlock.
local ok, errs = pipe:validate()
print("pipeline valid:", ok, "errors:", errs and #errs or 0)

-- Read the topological order to display an animated progress
-- visualiser that highlights each step as it executes.
local order = pipe:getExecutionOrder()
print("execution order:", table.concat(order, " -> "))

-- Read the parallel groups to schedule independent steps on separate
-- threads and measure the theoretical speedup vs sequential execution.
local groups = pipe:getParallelGroups()
print("parallel groups:", #groups)

-- Print the ASCII DAG to the devtools console so the level designer
-- can verify the dependency structure without a visual editor.
print(pipe:toAscii())

-- Serialise the pipeline definition to a table so it can be stored
-- in the save file and restored at next launch without recompilation.
local pipe_tbl = pipe:toTable()
print("serialised steps:", #(pipe_tbl.steps or {}))

-- Register a callback that triggers the fade-in animation when every
-- step of the level-load pipeline finishes successfully.
pipe:setOnComplete(function(result)
    print("  pipeline done! context:", result ~= nil)
end)

-- Register a step-error handler that logs which step failed and switches
-- the loading screen to an error state.
pipe:setOnStepError(function(step_name, err)
    print("  step error in:", step_name, "->", err)
end)

-- Register a progress callback that updates the loading-bar percentage
-- each time a step completes during an async level load.
pipe:onProgress(function(name, status)
    print("  progress:", name, "->", status)
end)

-- Execute the level pipeline synchronously so the loading screen
-- blocks until every asset and entity is ready.
local ctx = { level = "dungeon_1" }
local result = pipe:run(ctx)
print("pipeline result:", result ~= nil)

-- Read the result table after a synchronous run to check which steps
-- produced side-effects that the level initialisation code depends on.
local res = pipe:getResult()
print("result table:", res ~= nil)

-- Start the pipeline asynchronously on the next frame so the loading
-- screen can render a progress indicator while work runs.
local async_pipe = lurek.pipeline.newPipeline("async_load")
local async_step = lurek.pipeline.newStep("async_work", function(ctx)
    print("  [async_work] running...")
end)
async_pipe:addStep(async_step)
async_pipe:runAsync({ level = "overworld" })
print("async pipeline running:", async_pipe:isRunning())

-- Advance the async pipeline by one tick each frame from within the
lurek.process callback to drain steps at frame rate.
local done = async_pipe:update(0.016)
print("async pipeline complete:", done)

-- Guard the update call so the frame loop does not call update on
-- a pipeline that has already finished or was never started.
print("is running:", async_pipe:isRunning())

-- Check completion after each update tick to trigger the scene
-- activation code exactly once when the pipeline finishes.
print("is complete:", async_pipe:isComplete())

-- Cancel the asset pipeline when the player exits the loading screen
-- so pending steps do not run after the level is discarded.
async_pipe:cancel()
print("cancelled, running:", async_pipe:isRunning())

-- Reset the pipeline after a failure so it can be re-run with a fresh
-- context when the player retries loading.
pipe:reset()
print("reset, complete:", pipe:isComplete())

-- Retrieve the active context table mid-run to read progress data
-- that earlier steps wrote for use by later steps.
local active_ctx = pipe:getContext()
print("context:", active_ctx ~= nil)

-- Clear all steps from the pipeline before reloading the definition
-- from a hot-reloaded TOML file during a live game session.
local disposable_pipe = lurek.pipeline.newPipeline("disposable")
disposable_pipe:addStep(lurek.pipeline.newStep("x", function() end))
disposable_pipe:clear()
print("cleared, steps:", disposable_pipe:getStepCount())

-- Read the type name to validate that a variable holds a Pipeline
-- before calling pipeline-only methods on it.
print("pipeline type:", pipe:type())

-- Check whether an object is a Pipeline before dispatching it to the
-- serialisation routine that only handles pipeline objects.
print("typeOf Pipeline:", pipe:typeOf("Pipeline"))

-- -----------------------------------------------------------------------------
-- Step methods
-- -----------------------------------------------------------------------------

local step = pipe:getStep("load_assets") or step_load

-- Read the step name to include it in progress log lines so the
-- developer can match log output to pipeline definitions.
print("step name:", step:getName())

-- Replace the callback on an existing step to swap implementations
-- between debug and release without creating a new step.
step:setCallback(function(ctx)
    print("  [load_assets] callback replaced")
    ctx.textures_ready = true
end)

-- Guard the cloud-save step so it only runs when the player has
-- a network connection, otherwise it is silently skipped.
local cloud_step = lurek.pipeline.newStep("cloud_save", function(ctx) end)
cloud_step:setCondition(function()
    return false  -- no network in this demo run
end)
print("condition set on cloud_save")

-- Delay the splash-hide step by 0.5 seconds after the load finishes
-- so the player sees the splash long enough to read the tip text.
step:setDelay(0.5)
print("delay:", step:getDelay())

-- Read the delay before scheduling the step to pre-warm the timer
-- that will fire the step start exactly on schedule.
print("configured delay:", step:getDelay())  -- 0.5

-- Set a 5-second timeout on the network-fetch step so the pipeline
-- does not hang indefinitely when the server is unreachable.
local fetch_step = lurek.pipeline.newStep("fetch_leaderboard", function(ctx) end)
fetch_step:setTimeout(5.0)
print("timeout:", fetch_step:getTimeout())

-- Read the timeout before the async run to confirm the watchdog
-- will fire before the intended frame budget overruns.
print("fetch timeout:", fetch_step:getTimeout())  -- 5.0

-- Allow the leaderboard fetch to retry up to 3 times before giving
-- up so a brief network hiccup does not fail the whole sequence.
fetch_step:setRetryCount(3)
print("retry count:", fetch_step:getRetryCount())

-- Read the retry count to display it in the failure dialog: "retried
-- X times" helps users understand why the load took longer.
print("retry count check:", fetch_step:getRetryCount())  -- 3

-- Space retries 2 seconds apart so a rate-limited API endpoint is not
-- hammered and the retry has time to succeed.
fetch_step:setRetryDelay(2.0)
print("retry delay set")

-- Mark the leaderboard fetch as optional so the pipeline continues
-- into the game even if the fetch fails after all retries.
fetch_step:setOptional(true)
print("optional:", fetch_step:isOptional())

-- Check whether a step is optional before deciding to fail the whole
-- pipeline or just log a warning and continue.
print("fetch optional:", fetch_step:isOptional())  -- true

-- Attach a per-step error handler to the fetch step so the UI shows
-- an offline badge immediately when it fails.
fetch_step:setOnError(function(err)
    print("  fetch error:", err)
end)

-- Store the target asset path in step metadata so the loading screen
-- tooltip shows which file is currently being loaded.
step:setData("asset_path", "assets/dungeon_atlas.png")
print("data set:", step:getData("asset_path"))

-- Read the asset path stored in step metadata to display it on the
-- loading bar without threading the value through the context table.
print("asset_path:", step:getData("asset_path"))

-- Tag the step as "io" so the profiler can group all I/O steps and
-- report total I/O time separately from CPU work steps.
step:setTag("io")
print("tag:", step:getTag())

-- Read the tag to route step progress events to the correct
-- subsystem profiler bucket.
print("step tag:", step:getTag())  -- "io"

-- Declare that spawn_entities depends on load_assets so the pipeline
-- scheduler never starts spawning before textures are loaded.
step_spawn:dependsOn("load_assets")
step_ai:dependsOn(step_spawn)  -- accepts step object too
print("spawn deps:", step_spawn:getDependencyCount())

-- Read the dependency list to verify the DAG structure in a unit test
-- before committing the pipeline definition.
local deps = step_spawn:getDependencies()
print("spawn dependencies:", table.concat(deps, ", "))

-- Read the dependency count to decide whether to display a dependency
-- chain visualization for this step in the devtools panel.
print("dep count:", step_spawn:getDependencyCount())

-- Read the step status after a pipeline run to determine which steps
-- completed, were skipped, or failed for the post-run report.
print("step status:", step:getStatus())

-- Read the error message from a failed step to surface it in the
-- error dialog shown to the player after a loading failure.
local err_msg = step:getError()
print("step error:", err_msg or "none")

-- Read execution time after the pipeline run to identify bottleneck
-- steps that should be profiled or parallelised.
print(string.format("step duration: %.3f s", step:getDuration()))

-- Read the attempt count to include in the retry log message: "step
-- 'X' failed on attempt N of M".
print("attempt:", step:getAttempt())

-- Read the type name to confirm a variable holds a PipelineStep before
-- calling step-only methods on it.
print("step type:", step:type())

-- Check that an argument is a PipelineStep before passing it to a
-- helper that calls dependsOn to avoid a runtime error.
print("typeOf PipelineStep:", step:typeOf("PipelineStep"))

-- =============================================================================
-- Advanced Edge Cases and Extra API Demonstrations
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Pipeline methods
-- -----------------------------------------------------------------------------

-- Sets the callback to invoke each time a step completes successfully.
pipeline:setOnStepComplete([cb])
