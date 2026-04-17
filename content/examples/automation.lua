-- content/examples/automation.lua
-- Lurek2D lurek.automation API Reference
-- Run with: cargo run -- content/examples/automation

-- =============================================================================
-- lurek.automation — Scriptable test automation and macro recording
--
-- The automation module plays back recorded action sequences for automated
-- testing, demo recording, and tutorial replay.  Scripts are step-based
-- sequences loaded from Lua tables or TOML files.  Macros record and replay
-- player input for QA regression testing.
-- =============================================================================

-- ---- Stub: lurek.automation.load -----------------------------------------
--@api-stub: lurek.automation.load
-- Load a test automation script that walks through the tutorial flow.  Each
-- step describes an action (click, move, wait) with timing metadata.
local tutorial_script = {
    name = "tutorial_walkthrough",
    steps = {
        { action = "click",  target = "btn_new_game", delay = 0.5 },
        { action = "wait",   duration = 1.0 },
        { action = "move",   x = 400, y = 300, duration = 0.3 },
        { action = "click",  target = "btn_start", delay = 0.2 },
        { action = "keypress", key = "space", delay = 0.5 },
    },
}
lurek.automation.load(tutorial_script)
print("loaded automation script: " .. tutorial_script.name)
print("steps: " .. #tutorial_script.steps)

-- ---- Stub: lurek.automation.loadFromToml ---------------------------------
--@api-stub: lurek.automation.loadFromToml
-- Load a test script from a TOML file authored by QA.  TOML is more readable
-- than Lua tables for non-programmers writing test plans.
lurek.automation.loadFromToml("tests/automation/smoke_test.toml")
print("loaded TOML automation script")

-- ---- Stub: lurek.automation.hasScript ------------------------------------
--@api-stub: lurek.automation.hasScript
-- Check whether a named script is loaded before attempting to start it.
-- Prevents runtime errors when a test plan references a missing script.
local has_tutorial = lurek.automation.hasScript("tutorial_walkthrough")
print("tutorial script loaded: " .. tostring(has_tutorial))

-- ---- Stub: lurek.automation.getScripts -----------------------------------
--@api-stub: lurek.automation.getScripts
-- List all loaded automation scripts in the QA dashboard so testers can
-- pick which sequence to run.
local scripts = lurek.automation.getScripts()
print("loaded scripts:")
for i, name in ipairs(scripts) do
    print(string.format("  [%d] %s", i, name))
end

-- ---- Stub: lurek.automation.unload ---------------------------------------
--@api-stub: lurek.automation.unload
-- Remove a script after it finishes to free memory.  Useful in long QA
-- sessions that cycle through dozens of test plans.
lurek.automation.unload("tutorial_walkthrough")
print("unloaded tutorial_walkthrough script")

-- Reload for subsequent examples
lurek.automation.load(tutorial_script)

-- ---- Stub: lurek.automation.start ----------------------------------------
--@api-stub: lurek.automation.start
-- Begin playback of the tutorial automation.  The script will execute steps
-- sequentially, advancing on each update() call.
lurek.automation.start("tutorial_walkthrough")
print("automation playback started")

-- ---- Stub: lurek.automation.isRunning ------------------------------------
--@api-stub: lurek.automation.isRunning
-- Show a "REPLAY" badge in the corner of the screen while automation is
-- actively playing back so developers know input is synthetic.
local running = lurek.automation.isRunning()
print("automation running: " .. tostring(running))
if running then
    print("  [REPLAY] indicator should be visible")
end

-- ---- Stub: lurek.automation.update ---------------------------------------
--@api-stub: lurek.automation.update
-- Advance the automation by one frame's worth of time.  Call this in
-- lurek.process() so automation keeps pace with the game loop.
local dt = 0.016   -- 60 FPS delta
lurek.automation.update(dt)
print("automation advanced by " .. dt .. " seconds")

-- ---- Stub: lurek.automation.getCurrentStep -------------------------------
--@api-stub: lurek.automation.getCurrentStep
-- Display which step is currently executing in the QA overlay.
local step = lurek.automation.getCurrentStep()
print("current step index: " .. tostring(step))

-- ---- Stub: lurek.automation.getStepCount ---------------------------------
--@api-stub: lurek.automation.getStepCount
-- Show progress as "step 2 of 5" in the automation overlay.
local total = lurek.automation.getStepCount()
local current = lurek.automation.getCurrentStep()
print(string.format("progress: step %d of %d", current or 0, total or 0))

-- ---- Stub: lurek.automation.getCurrentScript -----------------------------
--@api-stub: lurek.automation.getCurrentScript
-- Log which script is playing for the test report header.
local script_name = lurek.automation.getCurrentScript()
print("active script: " .. (script_name or "none"))

-- ---- Stub: lurek.automation.getElapsedTime -------------------------------
--@api-stub: lurek.automation.getElapsedTime
-- Record total playback time for performance benchmarking.  If the tutorial
-- takes longer than 30 seconds the test is flagged as slow.
local elapsed = lurek.automation.getElapsedTime()
print(string.format("elapsed playback time: %.2f sec", elapsed or 0))

-- ---- Stub: lurek.automation.pause ----------------------------------------
--@api-stub: lurek.automation.pause
-- Pause automation when the game hits a loading screen so timed steps do
-- not advance while assets are streaming.
lurek.automation.pause()
print("automation paused during loading screen")

-- ---- Stub: lurek.automation.isPaused -------------------------------------
--@api-stub: lurek.automation.isPaused
-- Check the paused state to decide whether to show a "PAUSED" badge
-- alongside the "REPLAY" indicator.
local paused = lurek.automation.isPaused()
print("automation paused: " .. tostring(paused))

-- ---- Stub: lurek.automation.resume ---------------------------------------
--@api-stub: lurek.automation.resume
-- Resume automation after the loading screen finishes.
lurek.automation.resume()
print("automation resumed after loading")

-- ---- Stub: lurek.automation.stop -----------------------------------------
--@api-stub: lurek.automation.stop
-- Abort automation early if a critical assertion fails mid-sequence.
lurek.automation.stop()
print("automation stopped -- all steps cancelled")

-- ---- Stub: lurek.automation.isComplete -----------------------------------
--@api-stub: lurek.automation.isComplete
-- After stopping, check whether the script ran to completion or was aborted.
local complete = lurek.automation.isComplete()
print("script completed naturally: " .. tostring(complete))

-- ---- Stub: lurek.automation.getStepLimit ---------------------------------
--@api-stub: lurek.automation.getStepLimit
-- Read the maximum step limit to display in the QA dashboard.
local limit = lurek.automation.getStepLimit()
print("step limit: " .. tostring(limit or "unlimited"))

-- ---- Stub: lurek.automation.setStepLimit ---------------------------------
--@api-stub: lurek.automation.setStepLimit
-- Cap automation at 100 steps for smoke tests.  If the script has more, it
-- will stop after reaching the limit to keep test runs short.
lurek.automation.setStepLimit(100)
print("step limit set to 100")

-- ---- Stub: lurek.automation.setPlaybackSpeed -----------------------------
--@api-stub: lurek.automation.setPlaybackSpeed
-- Speed up automation to 4x for fast regression testing.  At 4x a 30-second
-- test completes in 7.5 seconds of real time.
lurek.automation.setPlaybackSpeed(4.0)
print("playback speed: 4.0x")

-- ---- Stub: lurek.automation.getPlaybackSpeed -----------------------------
--@api-stub: lurek.automation.getPlaybackSpeed
-- Display the current playback multiplier in the QA toolbar.
local speed = lurek.automation.getPlaybackSpeed()
print("current playback speed: " .. speed .. "x")

-- ---- Stub: lurek.automation.saveMacro ------------------------------------
--@api-stub: lurek.automation.saveMacro
-- Record the player's input during a gameplay session and save it as a
-- named macro.  QA can replay it later to test the same sequence.
lurek.automation.saveMacro("boss_fight_attempt_1")
print("macro saved: boss_fight_attempt_1")

-- ---- Stub: lurek.automation.hasMacro -------------------------------------
--@api-stub: lurek.automation.hasMacro
-- Check if a macro exists before trying to play it.
local has_macro = lurek.automation.hasMacro("boss_fight_attempt_1")
print("boss fight macro exists: " .. tostring(has_macro))

-- ---- Stub: lurek.automation.listMacros -----------------------------------
--@api-stub: lurek.automation.listMacros
-- Show all saved macros in a dropdown so the tester can pick one to replay.
local macros = lurek.automation.listMacros()
print("saved macros:")
for i, name in ipairs(macros) do
    print(string.format("  [%d] %s", i, name))
end

-- ---- Stub: lurek.automation.playMacro ------------------------------------
--@api-stub: lurek.automation.playMacro
-- Replay a saved macro to reproduce a bug.  The macro feeds the exact same
-- input sequence the player originally performed.
lurek.automation.playMacro("boss_fight_attempt_1")
print("replaying macro: boss_fight_attempt_1")

-- ---- Stub: lurek.automation.setHighlightMode -----------------------------
--@api-stub: lurek.automation.setHighlightMode
-- Enable highlight mode to draw a visual indicator (e.g. a yellow circle)
-- on the element that automation is currently interacting with.  Useful for
-- demo recordings and tutorial videos.
lurek.automation.setHighlightMode(true)
print("highlight mode enabled -- active element will be visually marked")

-- ---- Stub: lurek.automation.isHighlightMode ------------------------------
--@api-stub: lurek.automation.isHighlightMode
-- Read highlight state to update a toggle checkbox in the QA toolbar.
local highlight = lurek.automation.isHighlightMode()
print("highlight mode: " .. tostring(highlight))

-- ---- Stub: lurek.automation.waitUntil ------------------------------------
--@api-stub: lurek.automation.waitUntil
-- Register a condition callback that blocks the automation until a game
-- state is reached (e.g. "wait until boss health < 50%").  This makes
-- scripts resilient to timing variations between machines.
lurek.automation.waitUntil(function()
    -- In a real game, check actual game state here
    local boss_hp_pct = 45   -- simulated
    return boss_hp_pct < 50
end, 10.0)    -- timeout after 10 seconds
print("waitUntil registered: boss HP < 50% (timeout 10s)")
