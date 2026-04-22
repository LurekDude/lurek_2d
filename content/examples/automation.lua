-- content/examples/automation.lua
-- Scaffolded coverage of the lurek.automation API (28 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/automation_api.rs   (Lua binding, arg types, return shape)
--   * src/automation/                 (semantics, side effects)
--   * docs/specs/automation.md        (canonical reference)
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
-- Run: cargo run -- content/examples/automation.lua

-- ── lurek.automation.* functions ──

--@api-stub: lurek.automation.load
-- Loads a named script from a Lua data table containing a steps array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.load
  local _todo = "TODO: write a real lurek.automation.load usage example"
  print(_todo)
end

--@api-stub: lurek.automation.unload
-- Removes a loaded script by name, returning true if it existed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.unload
  local _todo = "TODO: write a real lurek.automation.unload usage example"
  print(_todo)
end

--@api-stub: lurek.automation.hasScript
-- Returns true if a script with the given name is registered.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.hasScript
  local _todo = "TODO: write a real lurek.automation.hasScript usage example"
  print(_todo)
end

--@api-stub: lurek.automation.getScripts
-- Returns an array of all registered script names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.getScripts
  local _todo = "TODO: write a real lurek.automation.getScripts usage example"
  print(_todo)
end

--@api-stub: lurek.automation.start
-- Starts playback of the named script from the beginning.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.start
  local _todo = "TODO: write a real lurek.automation.start usage example"
  print(_todo)
end

--@api-stub: lurek.automation.stop
-- Stops playback and resets the simulator to idle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.stop
  local _todo = "TODO: write a real lurek.automation.stop usage example"
  print(_todo)
end

--@api-stub: lurek.automation.pause
-- Pauses playback at the current step position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.pause
  local _todo = "TODO: write a real lurek.automation.pause usage example"
  print(_todo)
end

--@api-stub: lurek.automation.resume
-- Resumes playback from a paused position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.resume
  local _todo = "TODO: write a real lurek.automation.resume usage example"
  print(_todo)
end

--@api-stub: lurek.automation.update
-- Advances the playback clock by `dt` seconds, dispatching due steps.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.update
  local _todo = "TODO: write a real lurek.automation.update usage example"
  print(_todo)
end

--@api-stub: lurek.automation.isRunning
-- Returns true if the simulator is actively playing a script.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.isRunning
  local _todo = "TODO: write a real lurek.automation.isRunning usage example"
  print(_todo)
end

--@api-stub: lurek.automation.isPaused
-- Returns true if playback is currently paused.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.isPaused
  local _todo = "TODO: write a real lurek.automation.isPaused usage example"
  print(_todo)
end

--@api-stub: lurek.automation.isComplete
-- Returns true if all steps in the active script have been dispatched.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.isComplete
  local _todo = "TODO: write a real lurek.automation.isComplete usage example"
  print(_todo)
end

--@api-stub: lurek.automation.getCurrentStep
-- Returns the index of the next step to be dispatched.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.getCurrentStep
  local _todo = "TODO: write a real lurek.automation.getCurrentStep usage example"
  print(_todo)
end

--@api-stub: lurek.automation.getStepCount
-- Returns the total number of steps in the active script.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.getStepCount
  local _todo = "TODO: write a real lurek.automation.getStepCount usage example"
  print(_todo)
end

--@api-stub: lurek.automation.getCurrentScript
-- Returns the name of the active script, or nil if idle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.getCurrentScript
  local _todo = "TODO: write a real lurek.automation.getCurrentScript usage example"
  print(_todo)
end

--@api-stub: lurek.automation.getElapsedTime
-- Returns seconds elapsed since playback started.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.getElapsedTime
  local _todo = "TODO: write a real lurek.automation.getElapsedTime usage example"
  print(_todo)
end

--@api-stub: lurek.automation.loadFromToml
-- Parses a TOML string and registers it as a named script.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.loadFromToml
  local _todo = "TODO: write a real lurek.automation.loadFromToml usage example"
  print(_todo)
end

--@api-stub: lurek.automation.getStepLimit
-- Returns the step limit for the named script, or nil if not found.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.getStepLimit
  local _todo = "TODO: write a real lurek.automation.getStepLimit usage example"
  print(_todo)
end

--@api-stub: lurek.automation.setStepLimit
-- Sets the step limit for the named script (clamped to 1..MAX_STEPS).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.setStepLimit
  local _todo = "TODO: write a real lurek.automation.setStepLimit usage example"
  print(_todo)
end

--@api-stub: lurek.automation.saveMacro
-- Saves a currently-loaded script under a macro name for fast replay.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.saveMacro
  local _todo = "TODO: write a real lurek.automation.saveMacro usage example"
  print(_todo)
end

--@api-stub: lurek.automation.playMacro
-- Loads and starts playback of a previously saved macro.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.playMacro
  local _todo = "TODO: write a real lurek.automation.playMacro usage example"
  print(_todo)
end

--@api-stub: lurek.automation.hasMacro
-- Returns true if a macro with the given name has been saved.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.hasMacro
  local _todo = "TODO: write a real lurek.automation.hasMacro usage example"
  print(_todo)
end

--@api-stub: lurek.automation.listMacros
-- Returns an array of all saved macro names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.listMacros
  local _todo = "TODO: write a real lurek.automation.listMacros usage example"
  print(_todo)
end

--@api-stub: lurek.automation.setPlaybackSpeed
-- Sets the dt multiplier for script playback (0.5 = half speed, 2.0 = double).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.setPlaybackSpeed
  local _todo = "TODO: write a real lurek.automation.setPlaybackSpeed usage example"
  print(_todo)
end

--@api-stub: lurek.automation.getPlaybackSpeed
-- Returns the current playback speed multiplier (default 1.0).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.getPlaybackSpeed
  local _todo = "TODO: write a real lurek.automation.getPlaybackSpeed usage example"
  print(_todo)
end

--@api-stub: lurek.automation.setHighlightMode
-- Enables or disables the highlight overlay hint.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.setHighlightMode
  local _todo = "TODO: write a real lurek.automation.setHighlightMode usage example"
  print(_todo)
end

--@api-stub: lurek.automation.isHighlightMode
-- Returns whether the highlight overlay hint is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.isHighlightMode
  local _todo = "TODO: write a real lurek.automation.isHighlightMode usage example"
  print(_todo)
end

--@api-stub: lurek.automation.waitUntil
-- Pauses playback advancement until predicate() returns true or timeout seconds elapse.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/automation_api.rs and docs/specs/automation.md).
do  -- TODO: lurek.automation.waitUntil
  local _todo = "TODO: write a real lurek.automation.waitUntil usage example"
  print(_todo)
end

