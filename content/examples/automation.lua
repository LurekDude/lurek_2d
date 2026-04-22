-- content/examples/automation.lua
-- Practical usage examples for the lurek.automation API (28 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.automation.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/automation.lua

print("[example] lurek.automation — 28 API entries")

-- ── lurek.automation.* free functions ──

--@api-stub: lurek.automation.load
-- Loads a named script from a Lua data table containing a steps array.
-- Call when you need to invoke load.
local ok, obj = pcall(function() return lurek.automation.load("name", {}) end)
if ok and obj then print("created:", obj) end
print("lurek.automation.load ok=", ok)

--@api-stub: lurek.automation.unload
-- Removes a loaded script by name, returning true if it existed.
-- Call when you need to invoke unload.
local ok, result = pcall(function() return lurek.automation.unload("name") end)
if ok then print("lurek.automation.unload ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.automation.hasScript
-- Returns true if a script with the given name is registered.
-- Call when you need to check has script.
local ok, result = pcall(function() return lurek.automation.hasScript("name") end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.automation.hasScript ok=", ok)

--@api-stub: lurek.automation.getScripts
-- Returns an array of all registered script names.
-- Call when you need to read scripts.
local ok, value = pcall(function() return lurek.automation.getScripts() end)
local v = ok and value or "(unavailable)"
print("lurek.automation.getScripts ->", v)

--@api-stub: lurek.automation.start
-- Starts playback of the named script from the beginning.
-- Call when you need to invoke start.
local ok, result = pcall(function() return lurek.automation.start("name") end)
if not ok then print("action skipped:", result) end
print("lurek.automation.start fired=", ok)

--@api-stub: lurek.automation.stop
-- Stops playback and resets the simulator to idle.
-- Call when you need to invoke stop.
local ok, result = pcall(function() return lurek.automation.stop() end)
if not ok then print("action skipped:", result) end
print("lurek.automation.stop fired=", ok)

--@api-stub: lurek.automation.pause
-- Pauses playback at the current step position.
-- Call when you need to invoke pause.
local ok, result = pcall(function() return lurek.automation.pause() end)
if not ok then print("action skipped:", result) end
print("lurek.automation.pause fired=", ok)

--@api-stub: lurek.automation.resume
-- Resumes playback from a paused position.
-- Call when you need to invoke resume.
local ok, result = pcall(function() return lurek.automation.resume() end)
if not ok then print("action skipped:", result) end
print("lurek.automation.resume fired=", ok)

--@api-stub: lurek.automation.update
-- Advances the playback clock by `dt` seconds, dispatching due steps.
-- Call when you need to invoke update.
local ok, err = pcall(function() lurek.automation.update(1.0) end)
if not ok then print("set skipped:", err) end
print("lurek.automation.update applied=", ok)

--@api-stub: lurek.automation.isRunning
-- Returns true if the simulator is actively playing a script.
-- Call when you need to check is running.
local ok, result = pcall(function() return lurek.automation.isRunning() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.automation.isRunning ok=", ok)

--@api-stub: lurek.automation.isPaused
-- Returns true if playback is currently paused.
-- Call when you need to check is paused.
local ok, result = pcall(function() return lurek.automation.isPaused() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.automation.isPaused ok=", ok)

--@api-stub: lurek.automation.isComplete
-- Returns true if all steps in the active script have been dispatched.
-- Call when you need to check is complete.
local ok, result = pcall(function() return lurek.automation.isComplete() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.automation.isComplete ok=", ok)

--@api-stub: lurek.automation.getCurrentStep
-- Returns the index of the next step to be dispatched.
-- Call when you need to read current step.
local ok, value = pcall(function() return lurek.automation.getCurrentStep() end)
local v = ok and value or "(unavailable)"
print("lurek.automation.getCurrentStep ->", v)

--@api-stub: lurek.automation.getStepCount
-- Returns the total number of steps in the active script.
-- Call when you need to read step count.
local ok, value = pcall(function() return lurek.automation.getStepCount() end)
local v = ok and value or "(unavailable)"
print("lurek.automation.getStepCount ->", v)

--@api-stub: lurek.automation.getCurrentScript
-- Returns the name of the active script, or nil if idle.
-- Call when you need to read current script.
local ok, value = pcall(function() return lurek.automation.getCurrentScript() end)
local v = ok and value or "(unavailable)"
print("lurek.automation.getCurrentScript ->", v)

--@api-stub: lurek.automation.getElapsedTime
-- Returns seconds elapsed since playback started.
-- Call when you need to read elapsed time.
local ok, value = pcall(function() return lurek.automation.getElapsedTime() end)
local v = ok and value or "(unavailable)"
print("lurek.automation.getElapsedTime ->", v)

--@api-stub: lurek.automation.loadFromToml
-- Parses a TOML string and registers it as a named script.
-- Call when you need to load from toml.
local ok, obj = pcall(function() return lurek.automation.loadFromToml("name", "toml_str value") end)
if ok and obj then print("created:", obj) end
print("lurek.automation.loadFromToml ok=", ok)

--@api-stub: lurek.automation.getStepLimit
-- Returns the step limit for the named script, or nil if not found.
-- Call when you need to read step limit.
local ok, value = pcall(function() return lurek.automation.getStepLimit("name") end)
local v = ok and value or "(unavailable)"
print("lurek.automation.getStepLimit ->", v)

--@api-stub: lurek.automation.setStepLimit
-- Sets the step limit for the named script (clamped to 1..MAX_STEPS).
-- Call when you need to assign step limit.
local ok, err = pcall(function() lurek.automation.setStepLimit("name", 10) end)
if not ok then print("set skipped:", err) end
print("lurek.automation.setStepLimit applied=", ok)

--@api-stub: lurek.automation.saveMacro
-- Saves a currently-loaded script under a macro name for fast replay.
-- Call when you need to invoke save macro.
local ok, obj = pcall(function() return lurek.automation.saveMacro("macro_name", "script_name") end)
if ok and obj then print("created:", obj) end
print("lurek.automation.saveMacro ok=", ok)

--@api-stub: lurek.automation.playMacro
-- Loads and starts playback of a previously saved macro.
-- Call when you need to play macro.
local ok, result = pcall(function() return lurek.automation.playMacro("name") end)
if not ok then print("action skipped:", result) end
print("lurek.automation.playMacro fired=", ok)

--@api-stub: lurek.automation.hasMacro
-- Returns true if a macro with the given name has been saved.
-- Call when you need to check has macro.
local ok, result = pcall(function() return lurek.automation.hasMacro("name") end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.automation.hasMacro ok=", ok)

--@api-stub: lurek.automation.listMacros
-- Returns an array of all saved macro names.
-- Call when you need to invoke list macros.
local ok, result = pcall(function() return lurek.automation.listMacros() end)
if ok then print("lurek.automation.listMacros ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.automation.setPlaybackSpeed
-- Sets the dt multiplier for script playback (0.5 = half speed, 2.0 = double).
-- Call when you need to assign playback speed.
local ok, err = pcall(function() lurek.automation.setPlaybackSpeed(1) end)
if not ok then print("set skipped:", err) end
print("lurek.automation.setPlaybackSpeed applied=", ok)

--@api-stub: lurek.automation.getPlaybackSpeed
-- Returns the current playback speed multiplier (default 1.0).
-- Call when you need to read playback speed.
local ok, value = pcall(function() return lurek.automation.getPlaybackSpeed() end)
local v = ok and value or "(unavailable)"
print("lurek.automation.getPlaybackSpeed ->", v)

--@api-stub: lurek.automation.setHighlightMode
-- Enables or disables the highlight overlay hint.
-- Call when you need to assign highlight mode.
local ok, err = pcall(function() lurek.automation.setHighlightMode(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.automation.setHighlightMode applied=", ok)

--@api-stub: lurek.automation.isHighlightMode
-- Returns whether the highlight overlay hint is active.
-- Call when you need to check is highlight mode.
local ok, result = pcall(function() return lurek.automation.isHighlightMode() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.automation.isHighlightMode ok=", ok)

--@api-stub: lurek.automation.waitUntil
-- Pauses playback advancement until predicate() returns true or timeout seconds elapse.
-- Call when you need to invoke wait until.
local ok, result = pcall(function() return lurek.automation.waitUntil(nil, nil) end)
if ok then print("lurek.automation.waitUntil ->", result)
else print("unavailable:", result) end

