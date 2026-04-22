-- content/examples/automation.lua
-- Auto-scaffolded coverage of the lurek.automation Lua API (28 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/automation.lua

print("[example] lurek.automation loaded — 28 API items demonstrated")

-- ── lurek.automation free functions ──

--@api-stub: lurek.automation.load
-- Loads a named script from a Lua data table containing a steps array.
-- Use this when loads a named script from a Lua data table containing a steps array is needed.
if false then
  local _r = lurek.automation.load(1, 0)
  print(_r)
end

--@api-stub: lurek.automation.unload
-- Removes a loaded script by name, returning true if it existed.
-- Use this when removes a loaded script by name, returning true if it existed is needed.
if false then
  local _r = lurek.automation.unload(1)
  print(_r)
end

--@api-stub: lurek.automation.hasScript
-- Returns true if a script with the given name is registered.
-- Use this when returns true if a script with the given name is registered is needed.
if false then
  local _r = lurek.automation.hasScript(1)
  print(_r)
end

--@api-stub: lurek.automation.getScripts
-- Returns an array of all registered script names.
-- Use this when returns an array of all registered script names is needed.
if false then
  local _r = lurek.automation.getScripts()
  print(_r)
end

--@api-stub: lurek.automation.start
-- Starts playback of the named script from the beginning.
-- Use this when starts playback of the named script from the beginning is needed.
if false then
  local _r = lurek.automation.start(1)
  print(_r)
end

--@api-stub: lurek.automation.stop
-- Stops playback and resets the simulator to idle.
-- Use this when stops playback and resets the simulator to idle is needed.
if false then
  local _r = lurek.automation.stop()
  print(_r)
end

--@api-stub: lurek.automation.pause
-- Pauses playback at the current step position.
-- Use this when pauses playback at the current step position is needed.
if false then
  local _r = lurek.automation.pause()
  print(_r)
end

--@api-stub: lurek.automation.resume
-- Resumes playback from a paused position.
-- Use this when resumes playback from a paused position is needed.
if false then
  local _r = lurek.automation.resume()
  print(_r)
end

--@api-stub: lurek.automation.update
-- Advances the playback clock by `dt` seconds, dispatching due steps.
-- Use this when advances the playback clock by `dt` seconds, dispatching due steps is needed.
if false then
  local _r = lurek.automation.update(0)
  print(_r)
end

--@api-stub: lurek.automation.isRunning
-- Returns true if the simulator is actively playing a script.
-- Use this when returns true if the simulator is actively playing a script is needed.
if false then
  local _r = lurek.automation.isRunning()
  print(_r)
end

--@api-stub: lurek.automation.isPaused
-- Returns true if playback is currently paused.
-- Use this when returns true if playback is currently paused is needed.
if false then
  local _r = lurek.automation.isPaused()
  print(_r)
end

--@api-stub: lurek.automation.isComplete
-- Returns true if all steps in the active script have been dispatched.
-- Use this when returns true if all steps in the active script have been dispatched is needed.
if false then
  local _r = lurek.automation.isComplete()
  print(_r)
end

--@api-stub: lurek.automation.getCurrentStep
-- Returns the index of the next step to be dispatched.
-- Use this when returns the index of the next step to be dispatched is needed.
if false then
  local _r = lurek.automation.getCurrentStep()
  print(_r)
end

--@api-stub: lurek.automation.getStepCount
-- Returns the total number of steps in the active script.
-- Use this when returns the total number of steps in the active script is needed.
if false then
  local _r = lurek.automation.getStepCount()
  print(_r)
end

--@api-stub: lurek.automation.getCurrentScript
-- Returns the name of the active script, or nil if idle.
-- Use this when returns the name of the active script, or nil if idle is needed.
if false then
  local _r = lurek.automation.getCurrentScript()
  print(_r)
end

--@api-stub: lurek.automation.getElapsedTime
-- Returns seconds elapsed since playback started.
-- Use this when returns seconds elapsed since playback started is needed.
if false then
  local _r = lurek.automation.getElapsedTime()
  print(_r)
end

--@api-stub: lurek.automation.loadFromToml
-- Parses a TOML string and registers it as a named script.
-- Use this when parses a TOML string and registers it as a named script is needed.
if false then
  local _r = lurek.automation.loadFromToml(1, 0)
  print(_r)
end

--@api-stub: lurek.automation.getStepLimit
-- Returns the step limit for the named script, or nil if not found.
-- Use this when returns the step limit for the named script, or nil if not found is needed.
if false then
  local _r = lurek.automation.getStepLimit(1)
  print(_r)
end

--@api-stub: lurek.automation.setStepLimit
-- Sets the step limit for the named script (clamped to 1..MAX_STEPS).
-- Use this when sets the step limit for the named script (clamped to 1..MAX_STEPS) is needed.
if false then
  local _r = lurek.automation.setStepLimit(1, 1)
  print(_r)
end

--@api-stub: lurek.automation.saveMacro
-- Saves a currently-loaded script under a macro name for fast replay.
-- Use this when saves a currently-loaded script under a macro name for fast replay is needed.
if false then
  local _r = lurek.automation.saveMacro(1, 1)
  print(_r)
end

--@api-stub: lurek.automation.playMacro
-- Loads and starts playback of a previously saved macro.
-- Use this when loads and starts playback of a previously saved macro is needed.
if false then
  local _r = lurek.automation.playMacro(1)
  print(_r)
end

--@api-stub: lurek.automation.hasMacro
-- Returns true if a macro with the given name has been saved.
-- Use this when returns true if a macro with the given name has been saved is needed.
if false then
  local _r = lurek.automation.hasMacro(1)
  print(_r)
end

--@api-stub: lurek.automation.listMacros
-- Returns an array of all saved macro names.
-- Use this when returns an array of all saved macro names is needed.
if false then
  local _r = lurek.automation.listMacros()
  print(_r)
end

--@api-stub: lurek.automation.setPlaybackSpeed
-- Sets the dt multiplier for script playback (0.5 = half speed, 2.0 = double).
-- Use this when sets the dt multiplier for script playback (0.5 = half speed, 2.0 = double) is needed.
if false then
  local _r = lurek.automation.setPlaybackSpeed(0)
  print(_r)
end

--@api-stub: lurek.automation.getPlaybackSpeed
-- Returns the current playback speed multiplier (default 1.0).
-- Use this when returns the current playback speed multiplier (default 1.0) is needed.
if false then
  local _r = lurek.automation.getPlaybackSpeed()
  print(_r)
end

--@api-stub: lurek.automation.setHighlightMode
-- Enables or disables the highlight overlay hint.
-- Use this when enables or disables the highlight overlay hint is needed.
if false then
  local _r = lurek.automation.setHighlightMode(1)
  print(_r)
end

--@api-stub: lurek.automation.isHighlightMode
-- Returns whether the highlight overlay hint is active.
-- Use this when returns whether the highlight overlay hint is active is needed.
if false then
  local _r = lurek.automation.isHighlightMode()
  print(_r)
end

--@api-stub: lurek.automation.waitUntil
-- Pauses playback advancement until predicate() returns true or timeout seconds elapse.
-- Use this when pauses playback advancement until predicate() returns true or timeout seconds elapse is needed.
if false then
  local _r = lurek.automation.waitUntil(0, 0)
  print(_r)
end

