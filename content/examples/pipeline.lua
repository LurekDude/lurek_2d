-- content/examples/pipeline.lua
-- Practical usage examples for the lurek.pipeline API (60 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.pipeline.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/pipeline.lua

print("[example] lurek.pipeline — 60 API entries")

-- ── lurek.pipeline.* free functions ──

--@api-stub: lurek.pipeline.newStep
-- Creates a new pipeline step with the given name and optional callback.
-- Call when you need to create a new step.
local ok, obj = pcall(function() return lurek.pipeline.newStep("name", function() end) end)
if ok and obj then print("created:", obj) end
print("lurek.pipeline.newStep ok=", ok)

--@api-stub: lurek.pipeline.newPipeline
-- Creates a new empty pipeline with the given name (defaults to "pipeline").
-- Call when you need to create a new pipeline.
local ok, obj = pcall(function() return lurek.pipeline.newPipeline("name") end)
if ok and obj then print("created:", obj) end
print("lurek.pipeline.newPipeline ok=", ok)

--@api-stub: lurek.pipeline.fromTable
-- Deserialises a pipeline from a definition table.
-- Call when you need to invoke from table.
local ok, obj = pcall(function() return lurek.pipeline.fromTable(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.pipeline.fromTable ok=", ok)

-- ── Step methods ──

--@api-stub: Step:getName
-- Returns the unique name of this step.
-- Call when you need to read name.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:getName() end)
  print("Step:getName ->", ok, result)
end

--@api-stub: Step:setCallback
-- Stores a Lua function as the execute callback for this step.
-- Call when you need to assign callback.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:setCallback(function() end) end)
  print("Step:setCallback ->", ok, result)
end

--@api-stub: Step:setCondition
-- Stores a Lua function (or nil) as the run-condition for this step.
-- Call when you need to assign condition.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:setCondition(nil) end)
  print("Step:setCondition ->", ok, result)
end

--@api-stub: Step:setDelay
-- Sets the delay in seconds to wait after dependencies finish.
-- Call when you need to assign delay.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:setDelay(1.0) end)
  print("Step:setDelay ->", ok, result)
end

--@api-stub: Step:getDelay
-- Returns the configured delay in seconds.
-- Call when you need to read delay.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:getDelay() end)
  print("Step:getDelay ->", ok, result)
end

--@api-stub: Step:setTimeout
-- Stores a timeout in seconds in the step's metadata.
-- Call when you need to assign timeout.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:setTimeout(1.0) end)
  print("Step:setTimeout ->", ok, result)
end

--@api-stub: Step:getTimeout
-- Returns the timeout stored in metadata, or 0.0 if unset.
-- Call when you need to read timeout.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:getTimeout() end)
  print("Step:getTimeout ->", ok, result)
end

--@api-stub: Step:setRetryCount
-- Sets the maximum number of retry attempts on failure.
-- Call when you need to assign retry count.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:setRetryCount(10) end)
  print("Step:setRetryCount ->", ok, result)
end

--@api-stub: Step:getRetryCount
-- Returns the configured retry count.
-- Call when you need to read retry count.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:getRetryCount() end)
  print("Step:getRetryCount ->", ok, result)
end

--@api-stub: Step:setRetryDelay
-- Sets the delay in seconds between retry attempts.
-- Call when you need to assign retry delay.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:setRetryDelay(1.0) end)
  print("Step:setRetryDelay ->", ok, result)
end

--@api-stub: Step:setOptional
-- Marks whether this step is optional (downstream steps continue on failure).
-- Call when you need to assign optional.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:setOptional(nil) end)
  print("Step:setOptional ->", ok, result)
end

--@api-stub: Step:isOptional
-- Returns whether this step is marked as optional.
-- Call when you need to check is optional.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:isOptional() end)
  print("Step:isOptional ->", ok, result)
end

--@api-stub: Step:setOnError
-- Stores a Lua function (or nil) to call if this step fails.
-- Call when you need to assign on error.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:setOnError(function() end) end)
  print("Step:setOnError ->", ok, result)
end

--@api-stub: Step:setData
-- Stores an arbitrary string value under the given key in step metadata.
-- Call when you need to assign data.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:setData("key", nil) end)
  print("Step:setData ->", ok, result)
end

--@api-stub: Step:getData
-- Retrieves a metadata value by key, returning nil if not found.
-- Call when you need to read data.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:getData("key") end)
  print("Step:getData ->", ok, result)
end

--@api-stub: Step:setTag
-- Sets the tag on this step for grouping and filtering.
-- Call when you need to assign tag.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:setTag("tag") end)
  print("Step:setTag ->", ok, result)
end

--@api-stub: Step:getTag
-- Returns the tag on this step, or nil if unset.
-- Call when you need to read tag.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:getTag() end)
  print("Step:getTag ->", ok, result)
end

--@api-stub: Step:dependsOn
-- Adds a dependency on another step by name or PipelineStep.
-- Returns self for chaining.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:dependsOn(nil) end)
  print("Step:dependsOn ->", ok, result)
end

--@api-stub: Step:getDependencies
-- Returns the list of dependency step names.
-- Call when you need to read dependencies.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:getDependencies() end)
  print("Step:getDependencies ->", ok, result)
end

--@api-stub: Step:getDependencyCount
-- Returns the number of declared dependencies.
-- Call when you need to read dependency count.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:getDependencyCount() end)
  print("Step:getDependencyCount ->", ok, result)
end

--@api-stub: Step:getStatus
-- Returns the current execution status as a string.
-- Call when you need to read status.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:getStatus() end)
  print("Step:getStatus ->", ok, result)
end

--@api-stub: Step:getError
-- Returns the error message from the last failed attempt, or nil.
-- Call when you need to read error.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:getError() end)
  print("Step:getError ->", ok, result)
end

--@api-stub: Step:getDuration
-- Returns total seconds spent executing this step.
-- Call when you need to read duration.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:getDuration() end)
  print("Step:getDuration ->", ok, result)
end

--@api-stub: Step:getAttempt
-- Returns the number of execution attempts so far.
-- Call when you need to read attempt.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:getAttempt() end)
  print("Step:getAttempt ->", ok, result)
end

--@api-stub: Step:type
-- Returns the type name "PipelineStep".
-- Call when you need to invoke type.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Step:type ->", ok, result)
end

--@api-stub: Step:typeOf
-- Returns true when the given name matches "PipelineStep" or a parent type.
-- Call when you need to invoke type of.
-- Build a Step via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newStep(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Step:typeOf ->", ok, result)
end

-- ── Pipeline methods ──

--@api-stub: Pipeline:addStep
-- Adds a step to the pipeline.
-- Returns self for chaining.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:addStep(nil) end)
  print("Pipeline:addStep ->", ok, result)
end

--@api-stub: Pipeline:removeStep
-- Removes a step from the pipeline by name.
-- Call when you need to remove step.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:removeStep("name") end)
  print("Pipeline:removeStep ->", ok, result)
end

--@api-stub: Pipeline:getStep
-- Returns the LuaStep wrapper for the named step, or nil.
-- Call when you need to read step.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:getStep("name") end)
  print("Pipeline:getStep ->", ok, result)
end

--@api-stub: Pipeline:getSteps
-- Returns a Lua array of all step wrappers in the pipeline.
-- Call when you need to read steps.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:getSteps() end)
  print("Pipeline:getSteps ->", ok, result)
end

--@api-stub: Pipeline:getStepCount
-- Returns the total number of steps.
-- Call when you need to read step count.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:getStepCount() end)
  print("Pipeline:getStepCount ->", ok, result)
end

--@api-stub: Pipeline:getStepsByTag
-- Returns a Lua array of all steps whose tag matches the given string.
-- Call when you need to read steps by tag.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:getStepsByTag("tag") end)
  print("Pipeline:getStepsByTag ->", ok, result)
end

--@api-stub: Pipeline:clear
-- Clears all steps from the pipeline.
-- Call when you need to invoke clear.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("Pipeline:clear ->", ok, result)
end

--@api-stub: Pipeline:validate
-- Validates the pipeline DAG.
-- Returns (ok, error_array).
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:validate() end)
  print("Pipeline:validate ->", ok, result)
end

--@api-stub: Pipeline:getExecutionOrder
-- Returns the topological execution order as an array of step names.
-- Call when you need to read execution order.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:getExecutionOrder() end)
  print("Pipeline:getExecutionOrder ->", ok, result)
end

--@api-stub: Pipeline:getParallelGroups
-- Returns parallel execution groups as a nested array of step name arrays.
-- Call when you need to read parallel groups.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:getParallelGroups() end)
  print("Pipeline:getParallelGroups ->", ok, result)
end

--@api-stub: Pipeline:run
-- Executes the pipeline synchronously in topological order.
-- Call when you need to invoke run.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:run("context value") end)
  print("Pipeline:run ->", ok, result)
end

--@api-stub: Pipeline:runAsync
-- Starts an async pipeline run.
-- Steps are executed one-per-frame via update(dt).
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:runAsync("context value") end)
  print("Pipeline:runAsync ->", ok, result)
end

--@api-stub: Pipeline:update
-- Advances the async pipeline by one tick.
-- Returns true when all steps are done.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Pipeline:update ->", ok, result)
end

--@api-stub: Pipeline:cancel
-- Cancels all pending and waiting steps.
-- Call when you need to invoke cancel.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:cancel() end)
  print("Pipeline:cancel ->", ok, result)
end

--@api-stub: Pipeline:reset
-- Resets all step states and clears the async context.
-- Call when you need to invoke reset.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:reset() end)
  print("Pipeline:reset ->", ok, result)
end

--@api-stub: Pipeline:isRunning
-- Returns true if the pipeline is currently running asynchronously.
-- Call when you need to check is running.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:isRunning() end)
  print("Pipeline:isRunning ->", ok, result)
end

--@api-stub: Pipeline:isComplete
-- Returns true if all steps have reached a terminal state.
-- Call when you need to check is complete.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:isComplete() end)
  print("Pipeline:isComplete ->", ok, result)
end

--@api-stub: Pipeline:setErrorMode
-- Sets the pipeline error mode: "abort" or "continue".
-- Call when you need to assign error mode.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:setErrorMode(nil) end)
  print("Pipeline:setErrorMode ->", ok, result)
end

--@api-stub: Pipeline:getErrorMode
-- Returns the current error mode as a string.
-- Call when you need to read error mode.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:getErrorMode() end)
  print("Pipeline:getErrorMode ->", ok, result)
end

--@api-stub: Pipeline:getResult
-- Returns the current result table built from step states, or nil.
-- Call when you need to read result.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:getResult() end)
  print("Pipeline:getResult ->", ok, result)
end

--@api-stub: Pipeline:getContext
-- Returns the stored async context table, or nil.
-- Call when you need to read context.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:getContext() end)
  print("Pipeline:getContext ->", ok, result)
end

--@api-stub: Pipeline:setOnComplete
-- Sets the callback to invoke when the pipeline completes.
-- Call when you need to assign on complete.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:setOnComplete(function() end) end)
  print("Pipeline:setOnComplete ->", ok, result)
end

--@api-stub: Pipeline:setOnStepComplete
-- Sets the callback to invoke each time a step completes successfully.
-- Call when you need to assign on step complete.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:setOnStepComplete(function() end) end)
  print("Pipeline:setOnStepComplete ->", ok, result)
end

--@api-stub: Pipeline:setOnStepError
-- Sets the callback to invoke each time a step fails.
-- Call when you need to assign on step error.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:setOnStepError(function() end) end)
  print("Pipeline:setOnStepError ->", ok, result)
end

--@api-stub: Pipeline:getName
-- Returns the pipeline's name.
-- Call when you need to read name.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:getName() end)
  print("Pipeline:getName ->", ok, result)
end

--@api-stub: Pipeline:setName
-- Sets the pipeline's name.
-- Call when you need to assign name.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:setName("name") end)
  print("Pipeline:setName ->", ok, result)
end

--@api-stub: Pipeline:toTable
-- Serialises the pipeline definition to a Lua table (no callbacks).
-- Call when you need to invoke to table.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:toTable() end)
  print("Pipeline:toTable ->", ok, result)
end

--@api-stub: Pipeline:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Pipeline:type ->", ok, result)
end

--@api-stub: Pipeline:onProgress
-- Registers a callback invoked after every step with `(step_name, status)`.
-- Call when you need to invoke on progress.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:onProgress(function() end) end)
  print("Pipeline:onProgress ->", ok, result)
end

--@api-stub: Pipeline:toAscii
-- Returns a multi-line ASCII string visualising the pipeline DAG.
-- Call when you need to invoke to ascii.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:toAscii() end)
  print("Pipeline:toAscii ->", ok, result)
end

--@api-stub: Pipeline:typeOf
-- Returns the type identifier string of this pipeline stage object.
-- Call when you need to invoke type of.
-- Build a Pipeline via the appropriate lurek.pipeline.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.pipeline.newPipeline(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Pipeline:typeOf ->", ok, result)
end

