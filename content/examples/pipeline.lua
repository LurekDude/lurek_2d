-- content/examples/pipeline.lua
-- Scaffolded coverage of the lurek.pipeline API (60 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/pipeline_api.rs   (Lua binding, arg types, return shape)
--   * src/pipeline/                 (semantics, side effects)
--   * docs/specs/pipeline.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/pipeline.lua

-- ── lurek.pipeline.* functions ──

--@api-stub: lurek.pipeline.newStep
-- Creates a new pipeline step with the given name and optional callback.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: lurek.pipeline.newStep
  local _todo = "TODO: write a real lurek.pipeline.newStep usage example"
  print(_todo)
end

--@api-stub: lurek.pipeline.newPipeline
-- Creates a new empty pipeline with the given name (defaults to "pipeline").
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: lurek.pipeline.newPipeline
  local _todo = "TODO: write a real lurek.pipeline.newPipeline usage example"
  print(_todo)
end

--@api-stub: lurek.pipeline.fromTable
-- Deserialises a pipeline from a definition table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: lurek.pipeline.fromTable
  local _todo = "TODO: write a real lurek.pipeline.fromTable usage example"
  print(_todo)
end

-- ── Step methods ──

--@api-stub: Step:getName
-- Returns the unique name of this step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:getName
  local _todo = "TODO: write a real Step:getName usage example"
  print(_todo)
end

--@api-stub: Step:setCallback
-- Stores a Lua function as the execute callback for this step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:setCallback
  local _todo = "TODO: write a real Step:setCallback usage example"
  print(_todo)
end

--@api-stub: Step:setCondition
-- Stores a Lua function (or nil) as the run-condition for this step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:setCondition
  local _todo = "TODO: write a real Step:setCondition usage example"
  print(_todo)
end

--@api-stub: Step:setDelay
-- Sets the delay in seconds to wait after dependencies finish.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:setDelay
  local _todo = "TODO: write a real Step:setDelay usage example"
  print(_todo)
end

--@api-stub: Step:getDelay
-- Returns the configured delay in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:getDelay
  local _todo = "TODO: write a real Step:getDelay usage example"
  print(_todo)
end

--@api-stub: Step:setTimeout
-- Stores a timeout in seconds in the step's metadata.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:setTimeout
  local _todo = "TODO: write a real Step:setTimeout usage example"
  print(_todo)
end

--@api-stub: Step:getTimeout
-- Returns the timeout stored in metadata, or 0.0 if unset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:getTimeout
  local _todo = "TODO: write a real Step:getTimeout usage example"
  print(_todo)
end

--@api-stub: Step:setRetryCount
-- Sets the maximum number of retry attempts on failure.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:setRetryCount
  local _todo = "TODO: write a real Step:setRetryCount usage example"
  print(_todo)
end

--@api-stub: Step:getRetryCount
-- Returns the configured retry count.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:getRetryCount
  local _todo = "TODO: write a real Step:getRetryCount usage example"
  print(_todo)
end

--@api-stub: Step:setRetryDelay
-- Sets the delay in seconds between retry attempts.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:setRetryDelay
  local _todo = "TODO: write a real Step:setRetryDelay usage example"
  print(_todo)
end

--@api-stub: Step:setOptional
-- Marks whether this step is optional (downstream steps continue on failure).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:setOptional
  local _todo = "TODO: write a real Step:setOptional usage example"
  print(_todo)
end

--@api-stub: Step:isOptional
-- Returns whether this step is marked as optional.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:isOptional
  local _todo = "TODO: write a real Step:isOptional usage example"
  print(_todo)
end

--@api-stub: Step:setOnError
-- Stores a Lua function (or nil) to call if this step fails.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:setOnError
  local _todo = "TODO: write a real Step:setOnError usage example"
  print(_todo)
end

--@api-stub: Step:setData
-- Stores an arbitrary string value under the given key in step metadata.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:setData
  local _todo = "TODO: write a real Step:setData usage example"
  print(_todo)
end

--@api-stub: Step:getData
-- Retrieves a metadata value by key, returning nil if not found.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:getData
  local _todo = "TODO: write a real Step:getData usage example"
  print(_todo)
end

--@api-stub: Step:setTag
-- Sets the tag on this step for grouping and filtering.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:setTag
  local _todo = "TODO: write a real Step:setTag usage example"
  print(_todo)
end

--@api-stub: Step:getTag
-- Returns the tag on this step, or nil if unset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:getTag
  local _todo = "TODO: write a real Step:getTag usage example"
  print(_todo)
end

--@api-stub: Step:dependsOn
-- Adds a dependency on another step by name or PipelineStep.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:dependsOn
  local _todo = "TODO: write a real Step:dependsOn usage example"
  print(_todo)
end

--@api-stub: Step:getDependencies
-- Returns the list of dependency step names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:getDependencies
  local _todo = "TODO: write a real Step:getDependencies usage example"
  print(_todo)
end

--@api-stub: Step:getDependencyCount
-- Returns the number of declared dependencies.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:getDependencyCount
  local _todo = "TODO: write a real Step:getDependencyCount usage example"
  print(_todo)
end

--@api-stub: Step:getStatus
-- Returns the current execution status as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:getStatus
  local _todo = "TODO: write a real Step:getStatus usage example"
  print(_todo)
end

--@api-stub: Step:getError
-- Returns the error message from the last failed attempt, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:getError
  local _todo = "TODO: write a real Step:getError usage example"
  print(_todo)
end

--@api-stub: Step:getDuration
-- Returns total seconds spent executing this step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:getDuration
  local _todo = "TODO: write a real Step:getDuration usage example"
  print(_todo)
end

--@api-stub: Step:getAttempt
-- Returns the number of execution attempts so far.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:getAttempt
  local _todo = "TODO: write a real Step:getAttempt usage example"
  print(_todo)
end

--@api-stub: Step:type
-- Returns the type name "PipelineStep".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:type
  local _todo = "TODO: write a real Step:type usage example"
  print(_todo)
end

--@api-stub: Step:typeOf
-- Returns true when the given name matches "PipelineStep" or a parent type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Step:typeOf
  local _todo = "TODO: write a real Step:typeOf usage example"
  print(_todo)
end

-- ── Pipeline methods ──

--@api-stub: Pipeline:addStep
-- Adds a step to the pipeline.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:addStep
  local _todo = "TODO: write a real Pipeline:addStep usage example"
  print(_todo)
end

--@api-stub: Pipeline:removeStep
-- Removes a step from the pipeline by name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:removeStep
  local _todo = "TODO: write a real Pipeline:removeStep usage example"
  print(_todo)
end

--@api-stub: Pipeline:getStep
-- Returns the LuaStep wrapper for the named step, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:getStep
  local _todo = "TODO: write a real Pipeline:getStep usage example"
  print(_todo)
end

--@api-stub: Pipeline:getSteps
-- Returns a Lua array of all step wrappers in the pipeline.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:getSteps
  local _todo = "TODO: write a real Pipeline:getSteps usage example"
  print(_todo)
end

--@api-stub: Pipeline:getStepCount
-- Returns the total number of steps.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:getStepCount
  local _todo = "TODO: write a real Pipeline:getStepCount usage example"
  print(_todo)
end

--@api-stub: Pipeline:getStepsByTag
-- Returns a Lua array of all steps whose tag matches the given string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:getStepsByTag
  local _todo = "TODO: write a real Pipeline:getStepsByTag usage example"
  print(_todo)
end

--@api-stub: Pipeline:clear
-- Clears all steps from the pipeline.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:clear
  local _todo = "TODO: write a real Pipeline:clear usage example"
  print(_todo)
end

--@api-stub: Pipeline:validate
-- Validates the pipeline DAG.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:validate
  local _todo = "TODO: write a real Pipeline:validate usage example"
  print(_todo)
end

--@api-stub: Pipeline:getExecutionOrder
-- Returns the topological execution order as an array of step names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:getExecutionOrder
  local _todo = "TODO: write a real Pipeline:getExecutionOrder usage example"
  print(_todo)
end

--@api-stub: Pipeline:getParallelGroups
-- Returns parallel execution groups as a nested array of step name arrays.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:getParallelGroups
  local _todo = "TODO: write a real Pipeline:getParallelGroups usage example"
  print(_todo)
end

--@api-stub: Pipeline:run
-- Executes the pipeline synchronously in topological order.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:run
  local _todo = "TODO: write a real Pipeline:run usage example"
  print(_todo)
end

--@api-stub: Pipeline:runAsync
-- Starts an async pipeline run.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:runAsync
  local _todo = "TODO: write a real Pipeline:runAsync usage example"
  print(_todo)
end

--@api-stub: Pipeline:update
-- Advances the async pipeline by one tick.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:update
  local _todo = "TODO: write a real Pipeline:update usage example"
  print(_todo)
end

--@api-stub: Pipeline:cancel
-- Cancels all pending and waiting steps.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:cancel
  local _todo = "TODO: write a real Pipeline:cancel usage example"
  print(_todo)
end

--@api-stub: Pipeline:reset
-- Resets all step states and clears the async context.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:reset
  local _todo = "TODO: write a real Pipeline:reset usage example"
  print(_todo)
end

--@api-stub: Pipeline:isRunning
-- Returns true if the pipeline is currently running asynchronously.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:isRunning
  local _todo = "TODO: write a real Pipeline:isRunning usage example"
  print(_todo)
end

--@api-stub: Pipeline:isComplete
-- Returns true if all steps have reached a terminal state.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:isComplete
  local _todo = "TODO: write a real Pipeline:isComplete usage example"
  print(_todo)
end

--@api-stub: Pipeline:setErrorMode
-- Sets the pipeline error mode: "abort" or "continue".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:setErrorMode
  local _todo = "TODO: write a real Pipeline:setErrorMode usage example"
  print(_todo)
end

--@api-stub: Pipeline:getErrorMode
-- Returns the current error mode as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:getErrorMode
  local _todo = "TODO: write a real Pipeline:getErrorMode usage example"
  print(_todo)
end

--@api-stub: Pipeline:getResult
-- Returns the current result table built from step states, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:getResult
  local _todo = "TODO: write a real Pipeline:getResult usage example"
  print(_todo)
end

--@api-stub: Pipeline:getContext
-- Returns the stored async context table, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:getContext
  local _todo = "TODO: write a real Pipeline:getContext usage example"
  print(_todo)
end

--@api-stub: Pipeline:setOnComplete
-- Sets the callback to invoke when the pipeline completes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:setOnComplete
  local _todo = "TODO: write a real Pipeline:setOnComplete usage example"
  print(_todo)
end

--@api-stub: Pipeline:setOnStepComplete
-- Sets the callback to invoke each time a step completes successfully.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:setOnStepComplete
  local _todo = "TODO: write a real Pipeline:setOnStepComplete usage example"
  print(_todo)
end

--@api-stub: Pipeline:setOnStepError
-- Sets the callback to invoke each time a step fails.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:setOnStepError
  local _todo = "TODO: write a real Pipeline:setOnStepError usage example"
  print(_todo)
end

--@api-stub: Pipeline:getName
-- Returns the pipeline's name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:getName
  local _todo = "TODO: write a real Pipeline:getName usage example"
  print(_todo)
end

--@api-stub: Pipeline:setName
-- Sets the pipeline's name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:setName
  local _todo = "TODO: write a real Pipeline:setName usage example"
  print(_todo)
end

--@api-stub: Pipeline:toTable
-- Serialises the pipeline definition to a Lua table (no callbacks).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:toTable
  local _todo = "TODO: write a real Pipeline:toTable usage example"
  print(_todo)
end

--@api-stub: Pipeline:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:type
  local _todo = "TODO: write a real Pipeline:type usage example"
  print(_todo)
end

--@api-stub: Pipeline:onProgress
-- Registers a callback invoked after every step with `(step_name, status)`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:onProgress
  local _todo = "TODO: write a real Pipeline:onProgress usage example"
  print(_todo)
end

--@api-stub: Pipeline:toAscii
-- Returns a multi-line ASCII string visualising the pipeline DAG.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:toAscii
  local _todo = "TODO: write a real Pipeline:toAscii usage example"
  print(_todo)
end

--@api-stub: Pipeline:typeOf
-- Returns the type identifier string of this pipeline stage object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/pipeline_api.rs and docs/specs/pipeline.md).
do  -- TODO: Pipeline:typeOf
  local _todo = "TODO: write a real Pipeline:typeOf usage example"
  print(_todo)
end

