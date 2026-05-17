-- content/examples/automation.lua
-- Demonstrates the lurek.automation module for scripted input playback, macros, and test automation.
-- Run: cargo run -- content/examples/automation.lua

--@api-stub: lurek.automation.load
-- Loads an automation script from a Lua table of steps and optional metadata
do
  -- Define an automation script as a table with steps array and optional meta.
  -- Each step has a time (seconds from script start), action type, and parameters.
  -- Common actions: "keypress", "keyrelease", "mousepress", "mouserelease", "mousemove", "wait"
  local menu_skip = {
    meta = { description = "skip main menu and start game" },
    steps = {
      { time = 0.0, action = "wait" },
      { time = 0.5, action = "keypress",   key = "return" },
      { time = 0.6, action = "keyrelease", key = "return" },
      { time = 1.2, action = "keypress",   key = "return" },
      { time = 1.3, action = "keyrelease", key = "return" },
    },
  }
  -- The name is used to reference this script in start(), saveMacro(), etc.
  lurek.automation.load("menu_skip", menu_skip)
end

--@api-stub: lurek.automation.unload
-- Unloads a named automation script to free memory
do
  -- Load a temporary calibration script for the tutorial
  lurek.automation.load("tutorial_tap", {
    steps = {
      { time = 0.0, action = "keypress",   key = "space" },
      { time = 0.1, action = "keyrelease", key = "space" },
    },
  })
  -- After the tutorial finishes, remove the script to keep memory clean
  local removed = lurek.automation.unload("tutorial_tap")
  if removed then
    lurek.log.info("tutorial_tap script cleaned up", "automation")
  end
end

--@api-stub: lurek.automation.hasScript
-- Returns whether a script is loaded by name
do
  -- Guard against double-loading: only register the attract-mode script once
  if not lurek.automation.hasScript("attract_loop") then
    lurek.automation.load("attract_loop", {
      steps = {
        { time = 0.0, action = "keypress", key = "right" },
        { time = 1.0, action = "keyrelease", key = "right" },
        { time = 2.0, action = "keypress", key = "space" },
        { time = 2.1, action = "keyrelease", key = "space" },
      },
    })
  end
end

--@api-stub: lurek.automation.getScripts
-- Returns an array of all loaded script names
do
  -- Useful for debug overlays or test harness inventory
  lurek.automation.load("walk_right", { steps = { { time = 0, action = "keypress", key = "d" } } })
  lurek.automation.load("jump_combo", { steps = { { time = 0, action = "keypress", key = "space" } } })
  local scripts = lurek.automation.getScripts()
  for i, name in ipairs(scripts) do
    lurek.log.debug("script [" .. i .. "]: " .. name, "automation")
  end
end

--@api-stub: lurek.automation.start
-- Starts playback of a loaded automation script by name
do
  -- Typical pattern: load in conf, start in init
  lurek.automation.load("speed_run", {
    meta = { description = "automated speed-run route" },
    steps = {
      { time = 0.0, action = "keypress",   key = "d" },
      { time = 2.5, action = "keyrelease", key = "d" },
      { time = 2.6, action = "keypress",   key = "space" },
      { time = 2.7, action = "keyrelease", key = "space" },
    },
  })
  -- Start playback — the script will inject input events when update() is called
  function lurek.init()
    lurek.automation.start("speed_run")
  end
end

--@api-stub: lurek.automation.stop
-- Stops the currently running automation script immediately
do
  -- Let the player break out of automation by pressing Escape
  function lurek.keypressed(key)
    if key == "escape" and lurek.automation.isRunning() then
      lurek.automation.stop()
      lurek.log.info("player cancelled automation", "automation")
    end
  end
end

--@api-stub: lurek.automation.pause
-- Pauses automation playback without losing progress
do
  -- Pause automation when the game menu opens so input does not bleed through
  local menu_visible = false
  function lurek.keypressed(key)
    if key == "escape" then
      menu_visible = not menu_visible
      if menu_visible and lurek.automation.isRunning() then
        lurek.automation.pause()
      end
    end
  end
end

--@api-stub: lurek.automation.resume
-- Resumes paused automation playback from where it left off
do
  -- Resume automation when the menu closes
  local menu_visible = true
  function lurek.keypressed(key)
    if key == "escape" and menu_visible then
      menu_visible = false
      if lurek.automation.isPaused() then
        lurek.automation.resume()
      end
    end
  end
end

--@api-stub: lurek.automation.update
-- Advances automation playback by dt seconds; dispatches input events for passed steps
do
  -- Call update() every frame in process() to drive the automation timeline
  -- The module compares elapsed time against each step's time field
  -- and fires the corresponding input event when the step is reached
  function lurek.process(dt)
    lurek.automation.update(dt)
  end
end

--@api-stub: lurek.automation.isRunning
-- Returns true when an automation script is actively playing
do
  -- Show an indicator so players know the game is in auto-play mode
  function lurek.draw_ui()
    if lurek.automation.isRunning() then
      lurek.render.setColor(1, 1, 0, 1)
      lurek.render.print("[AUTO] press ESC to cancel", 8, 8)
      lurek.render.setColor(1, 1, 1, 1)
    end
  end
end

--@api-stub: lurek.automation.isPaused
-- Returns true when automation is loaded and paused
do
  -- Dim the auto indicator when paused
  function lurek.draw_ui()
    if lurek.automation.isPaused() then
      lurek.render.setColor(0.5, 0.5, 0.5, 0.7)
      lurek.render.print("[AUTO PAUSED]", 8, 8)
      lurek.render.setColor(1, 1, 1, 1)
    end
  end
end

--@api-stub: lurek.automation.isComplete
-- Returns true when the current script has played all steps
do
  -- Chain scripts: when one finishes, start the next
  local queue = { "phase_1", "phase_2", "phase_3" }
  local qi = 1
  function lurek.process(dt)
    lurek.automation.update(dt)
    if lurek.automation.isComplete() then
      lurek.automation.stop()
      qi = qi + 1
      if qi <= #queue then
        lurek.automation.start(queue[qi])
      end
    end
  end
end

--@api-stub: lurek.automation.getCurrentStep
-- Returns the 1-based index of the step currently being processed
do
  -- Display a progress bar during automation playback
  function lurek.draw_ui()
    if lurek.automation.isRunning() then
      local step = lurek.automation.getCurrentStep()
      local total = lurek.automation.getStepCount()
      local pct = step / math.max(total, 1)
      lurek.render.rectangle("fill", 8, 8, 200 * pct, 12)
    end
  end
end

--@api-stub: lurek.automation.getStepCount
-- Returns the total number of steps in the currently active script
do
  -- Log how many steps will execute before starting a long automation run
  function lurek.init()
    lurek.automation.start("speed_run")
    local count = lurek.automation.getStepCount()
    lurek.log.info("speed_run: " .. count .. " input steps queued", "automation")
  end
end

--@api-stub: lurek.automation.getCurrentScript
-- Returns the name of the active script, or nil if nothing is playing
do
  -- Show the current automation script name in a debug HUD
  function lurek.draw_ui()
    local name = lurek.automation.getCurrentScript()
    if name then
      lurek.render.print("playing: " .. name, 8, 24)
    else
      lurek.render.print("automation idle", 8, 24)
    end
  end
end

--@api-stub: lurek.automation.getElapsedTime
-- Returns the time in seconds since the current script started
do
  -- Show a running timer while automation plays for QA timing analysis
  function lurek.draw_ui()
    if lurek.automation.isRunning() then
      local elapsed = lurek.automation.getElapsedTime()
      lurek.render.print(string.format("auto t=%.2fs", elapsed), 8, 40)
    end
  end
end

--@api-stub: lurek.automation.loadFromToml
-- Loads an automation script from a TOML-formatted string
do
  -- TOML format is useful for loading scripts from external files or configs
  -- Each [[steps]] block defines one step with time, action, and key fields
  local toml_text = [=[
[meta]
description = "press jump then dash"

[[steps]]
time = 0.0
action = "keypress"
key = "space"

[[steps]]
time = 0.15
action = "keyrelease"
key = "space"

[[steps]]
time = 0.3
action = "keypress"
key = "lshift"

[[steps]]
time = 0.4
action = "keyrelease"
key = "lshift"
]=]
  lurek.automation.loadFromToml("jump_dash", toml_text)
end

--@api-stub: lurek.automation.getStepLimit
-- Returns the maximum step count for a loaded script, or nil if unlimited
do
  -- Check whether a script has a step limit before running it in CI
  local limit = lurek.automation.getStepLimit("speed_run")
  if limit then
    lurek.log.info("speed_run capped at " .. limit .. " steps", "automation")
  else
    lurek.log.info("speed_run has no step limit", "automation")
  end
end

--@api-stub: lurek.automation.setStepLimit
-- Sets the maximum number of steps a script will execute before auto-stopping
do
  -- Cap long scripts during CI to avoid infinite loops in broken automation
  local CI_STEP_CAP = 128
  local ok = lurek.automation.setStepLimit("speed_run", CI_STEP_CAP)
  if ok then
    lurek.log.info("speed_run limited to " .. CI_STEP_CAP .. " steps for CI", "automation")
  end
end

--@api-stub: lurek.automation.saveMacro
-- Saves a loaded script as a reusable macro by name
do
  -- Macros are lightweight named copies stored for quick replay
  -- Useful for common input sequences reused across different test scenarios
  lurek.automation.load("confirm_dialog", {
    steps = {
      { time = 0.0, action = "keypress",   key = "return" },
      { time = 0.1, action = "keyrelease", key = "return" },
    },
  })
  lurek.automation.saveMacro("confirm", "confirm_dialog")
end

--@api-stub: lurek.automation.playMacro
-- Starts playback of a previously saved macro
do
  -- Play a macro whenever a dialog appears to auto-dismiss it during testing
  function lurek.init()
    if lurek.automation.hasMacro("confirm") then
      lurek.automation.playMacro("confirm")
    end
  end
end

--@api-stub: lurek.automation.hasMacro
-- Returns true if a macro with the given name has been saved
do
  -- Verify required macros exist before starting an automated test run
  local required = { "confirm", "cancel", "menu_nav" }
  for _, name in ipairs(required) do
    if not lurek.automation.hasMacro(name) then
      lurek.log.warn("missing required macro: " .. name, "automation")
    end
  end
end

--@api-stub: lurek.automation.listMacros
-- Returns an array of all saved macro names
do
  -- Print available macros at startup for QA reference
  local macros = lurek.automation.listMacros()
  if #macros > 0 then
    lurek.log.info("available macros: " .. table.concat(macros, ", "), "automation")
  else
    lurek.log.info("no macros registered", "automation")
  end
end

--@api-stub: lurek.automation.setPlaybackSpeed
-- Sets the speed multiplier for automation playback (1.0 = real-time)
do
  -- Run automation at 4x speed during CI to complete tests faster
  -- Use 0.5x for slow-motion debugging of input timing issues
  local is_ci = false -- os.getenv not available in lurek sandbox
  if is_ci then
    lurek.automation.setPlaybackSpeed(4.0)
  else
    lurek.automation.setPlaybackSpeed(1.0)
  end
end

--@api-stub: lurek.automation.getPlaybackSpeed
-- Returns the current playback speed multiplier
do
  -- Show speed indicator when running faster than real-time
  function lurek.draw_ui()
    local speed = lurek.automation.getPlaybackSpeed()
    if speed ~= 1.0 then
      lurek.render.print(string.format("[%.1fx]", speed), 8, 56)
    end
  end
end

--@api-stub: lurek.automation.setHighlightMode
-- Enables visual highlight mode to show which inputs automation is injecting
do
  -- Enable highlight mode during recording or debugging so the developer
  -- can visually confirm which inputs are being injected
  local debug_mode = true
  lurek.automation.setHighlightMode(debug_mode)
end

--@api-stub: lurek.automation.isHighlightMode
-- Returns true when highlight mode is active
do
  -- Draw a pulsing indicator when highlight mode shows injected inputs
  function lurek.draw()
    if lurek.automation.isHighlightMode() then
      local alpha = 0.3 + 0.3 * math.sin(lurek.timer.getTime() * 4)
      lurek.render.setColor(1, 1, 0, alpha)
      lurek.render.rectangle("fill", 0, 0, 16, 16)
      lurek.render.setColor(1, 1, 1, 1)
    end
  end
end

--@api-stub: lurek.automation.waitUntil
-- Suspends automation until a predicate returns true or a timeout elapses
do
  -- Wait for a loading screen to finish before continuing the automation
  -- The predicate is called each frame during update(); if it returns true
  -- or the timeout (seconds) expires, playback resumes
  local level_loaded = false
  function lurek.init()
    lurek.automation.waitUntil(function()
      return level_loaded
    end, 10.0)
  end
  -- Somewhere else in the game:
  -- level_loaded = true  -- this unblocks the automation
end

--@api-stub: lurek.automation.setCondition
-- Sets a named boolean condition that automation steps can reference
do
  -- Conditions let automation scripts branch or wait based on game state
  -- without the script needing direct access to game variables
  local boss_defeated = false
  function lurek.process(dt)
    -- Update the condition each frame so automation scripts can react
    lurek.automation.setCondition("boss_defeated", boss_defeated)
    lurek.automation.update(dt)
  end
end

--@api-stub: lurek.automation.getCondition
-- Returns the current value of a named automation condition
do
  -- Read conditions from the debug overlay to verify game state during replays
  function lurek.draw_ui()
    local boss = lurek.automation.getCondition("boss_defeated")
    local door = lurek.automation.getCondition("door_open")
    lurek.render.print("boss_defeated=" .. tostring(boss), 8, 72)
    lurek.render.print("door_open=" .. tostring(door), 8, 88)
  end
end

--@api-stub: lurek.automation.isFailed
-- Returns true when the current automation script encountered an error
do
  -- Check for failures each frame and abort the test run if automation breaks
  function lurek.process(dt)
    lurek.automation.update(dt)
    if lurek.automation.isFailed() then
      local err = lurek.automation.getLastError() or "unknown error"
      lurek.log.error("automation failed: " .. err, "automation")
      lurek.automation.stop()
    end
  end
end

--@api-stub: lurek.automation.getLastError
-- Returns the last error message string, or nil if no error occurred
do
  -- After a test run completes, check if there was an error and report it
  function lurek.quit()
    local err = lurek.automation.getLastError()
    if err then
      lurek.log.error("automation error on exit: " .. err, "automation")
    else
      lurek.log.info("automation completed cleanly", "automation")
    end
  end
end

print("content/examples/automation.lua")
