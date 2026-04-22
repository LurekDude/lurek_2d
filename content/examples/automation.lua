-- content/examples/automation.lua
-- Hand-written coverage of the lurek.automation API (28 items).
--
-- Drives the engine via timed input scripts (a steps array of keypress,
-- mousemove, wait, etc.) so demos and tests can reproduce gameplay
-- without a human at the keyboard. Scripts are loaded from Lua tables
-- or TOML strings, then started/paused/resumed; `update(dt)` dispatches
-- due steps into the engine event queue.
--
-- Run: cargo run -- content/examples/automation.lua

-- ── lurek.automation.* functions ──

--@api-stub: lurek.automation.load
-- Loads a named script from a Lua data table containing a steps array.
-- Build the steps table once at startup; the simulator stores it by name and only dispatches when started.
do  -- lurek.automation.load
  local intro = {
    meta = { description = "intro cutscene skip" },
    steps = {
      { time = 0.0, action = "keypress",   key = "space" },
      { time = 0.5, action = "keyrelease", key = "space" },
    },
  }
  lurek.automation.load("intro_skip", intro)
end

--@api-stub: lurek.automation.unload
-- Removes a loaded script by name, returning true if it existed.
-- Use after a one-shot script (e.g. boot autoplay) finishes to free the slot for the next chapter.
do  -- lurek.automation.unload
  lurek.automation.load("boot_autoplay", { steps = { { time = 0, action = "wait" } } })
  if lurek.automation.unload("boot_autoplay") then
    lurek.log.info("boot_autoplay script removed", "automation")
  end
end

--@api-stub: lurek.automation.hasScript
-- Returns true if a script with the given name is registered.
-- Guard `start` with this when scripts are loaded conditionally (e.g. only in demo builds).
do  -- lurek.automation.hasScript
  if not lurek.automation.hasScript("attract_loop") then
    lurek.automation.load("attract_loop", {
      steps = { { time = 1.0, action = "keypress", key = "return" } },
    })
  end
end

--@api-stub: lurek.automation.getScripts
-- Returns an array of all registered script names.
-- Iterate the returned table to populate a debug-overlay dropdown of replayable scripts.
do  -- lurek.automation.getScripts
  lurek.automation.load("a", { steps = { { time = 0, action = "wait" } } })
  lurek.automation.load("b", { steps = { { time = 0, action = "wait" } } })
  for _, name in ipairs(lurek.automation.getScripts()) do
    lurek.log.debug("registered script: " .. name, "automation")
  end
end

--@api-stub: lurek.automation.start
-- Starts playback of the named script from the beginning.
-- Call once after `load`; calling `start` again resets the clock to t=0 even mid-playback.
do  -- lurek.automation.start
  lurek.automation.load("hop", {
    steps = { { time = 0.2, action = "keypress", key = "space" } },
  })
  function lurek.init() lurek.automation.start("hop") end
end

--@api-stub: lurek.automation.stop
-- Stops playback and resets the simulator to idle.
-- Call when a player takes manual control to abort the current automation.
do  -- lurek.automation.stop
  function lurek.init()
    if lurek.automation.isRunning() then
      lurek.automation.stop()
    end
  end
end

--@api-stub: lurek.automation.pause
-- Pauses playback at the current step position.
-- Useful when opening a pause menu so the script clock freezes alongside the simulation.
do  -- lurek.automation.pause
  local menu_open = true
  if menu_open and lurek.automation.isRunning() then
    lurek.automation.pause()
  end
end

--@api-stub: lurek.automation.resume
-- Resumes playback from a paused position.
-- Pair with `pause` when closing modals; safe to call when not paused (no-op).
do  -- lurek.automation.resume
  if lurek.automation.isPaused() then
    lurek.automation.resume()
  end
end

--@api-stub: lurek.automation.update
-- Advances the playback clock by `dt` seconds, dispatching due steps.
-- Call once per frame from `lurek.process(dt)` so the simulator stays in lock-step with game time.
do  -- lurek.automation.update
  function lurek.process(dt)
    lurek.automation.update(dt)
  end
end

--@api-stub: lurek.automation.isRunning
-- Returns true if the simulator is actively playing a script.
-- Use to gate UI hints like "Press ESC to skip" so they only appear during automated cutscenes.
do  -- lurek.automation.isRunning
  function lurek.render_ui()
    if lurek.automation.isRunning() then
      lurek.render.print("[AUTO] press ESC to skip", 8, 8)
    end
  end
end

--@api-stub: lurek.automation.isPaused
-- Returns true if playback is currently paused.
-- Distinguish from `isRunning() == false`: a paused script is still loaded and resumable.
do  -- lurek.automation.isPaused
  if lurek.automation.isPaused() then
    lurek.log.info("script halted on pause menu", "automation")
  end
end

--@api-stub: lurek.automation.isComplete
-- Returns true if all steps in the active script have been dispatched.
-- Use as a frame-end check to chain into the next script or hand control back to the player.
do  -- lurek.automation.isComplete
  function lurek.process(dt)
    lurek.automation.update(dt)
    if lurek.automation.isComplete() then
      lurek.automation.stop()
    end
  end
end

--@api-stub: lurek.automation.getCurrentStep
-- Returns the index of the next step to be dispatched.
-- Combine with `getStepCount` to render a progress indicator for long demo scripts.
do  -- lurek.automation.getCurrentStep
  function lurek.render_ui()
    local i = lurek.automation.getCurrentStep()
    local n = lurek.automation.getStepCount()
    lurek.render.print("step " .. i .. " / " .. n, 8, 24)
  end
end

--@api-stub: lurek.automation.getStepCount
-- Returns the total number of steps in the active script.
-- Cache the count after `start` if you draw it every frame; it does not change mid-playback.
do  -- lurek.automation.getStepCount
  local total = 0
  function lurek.init()
    lurek.automation.start("intro_skip")
    total = lurek.automation.getStepCount()
    lurek.log.info("playing " .. total .. " steps", "automation")
  end
end

--@api-stub: lurek.automation.getCurrentScript
-- Returns the name of the active script, or nil if idle.
-- Display in a debug HUD to confirm which scenario is currently driving the engine.
do  -- lurek.automation.getCurrentScript
  function lurek.render_ui()
    local name = lurek.automation.getCurrentScript() or "(idle)"
    lurek.render.print("script: " .. name, 8, 40)
  end
end

--@api-stub: lurek.automation.getElapsedTime
-- Returns seconds elapsed since playback started.
-- Use to drive synchronised visuals (e.g. fade-in tied to the same clock the script uses).
do  -- lurek.automation.getElapsedTime
  function lurek.render_ui()
    local t = lurek.automation.getElapsedTime()
    lurek.render.print(string.format("t = %.2fs", t), 8, 56)
  end
end

--@api-stub: lurek.automation.loadFromToml
-- Parses a TOML string and registers it as a named script.
-- Prefer TOML for designer-authored scripts that live alongside game data; falls back to `load` for code-built tables.
do  -- lurek.automation.loadFromToml
  local toml = [=[
[meta]
description = "left-right wiggle"
[[steps]]
time = 0.0
action = "keypress"
key = "left"
[[steps]]
time = 0.3
action = "keyrelease"
key = "left"
]=]
  lurek.automation.loadFromToml("wiggle", toml)
end

--@api-stub: lurek.automation.getStepLimit
-- Returns the step limit for the named script, or nil if not found.
-- Read before `setStepLimit` to log the change, or to detect typo'd script names (returns nil).
do  -- lurek.automation.getStepLimit
  local limit = lurek.automation.getStepLimit("intro_skip")
  if limit then
    lurek.log.debug("intro_skip step limit = " .. limit, "automation")
  end
end

--@api-stub: lurek.automation.setStepLimit
-- Sets the step limit for the named script (clamped to 1..MAX_STEPS).
-- Lower this for fuzz/CI runs to bound playback time; the engine clamps silently if you exceed MAX_STEPS.
do  -- lurek.automation.setStepLimit
  if lurek.automation.setStepLimit("wiggle", 64) then
    lurek.log.info("wiggle script limited to 64 steps", "automation")
  end
end

--@api-stub: lurek.automation.saveMacro
-- Saves a currently-loaded script under a macro name for fast replay.
-- Save common input sequences (open menu, dismiss dialog) once at startup, then `playMacro` whenever needed.
do  -- lurek.automation.saveMacro
  lurek.automation.load("dismiss_dialog", {
    steps = { { time = 0.05, action = "keypress", key = "return" } },
  })
  lurek.automation.saveMacro("dismiss", "dismiss_dialog")
end

--@api-stub: lurek.automation.playMacro
-- Loads and starts playback of a previously saved macro.
-- Convenience wrapper: equivalent to `load(macroScript) + start(name)` in one call; errors if the macro is unknown.
do  -- lurek.automation.playMacro
  function lurek.init()
    if lurek.automation.hasMacro("dismiss") then
      lurek.automation.playMacro("dismiss")
    end
  end
end

--@api-stub: lurek.automation.hasMacro
-- Returns true if a macro with the given name has been saved.
-- Always check before `playMacro` since unknown macro names raise an error.
do  -- lurek.automation.hasMacro
  if not lurek.automation.hasMacro("dismiss") then
    lurek.log.warn("macro 'dismiss' not registered yet", "automation")
  end
end

--@api-stub: lurek.automation.listMacros
-- Returns an array of all saved macro names.
-- Iterate to expose macros in a developer console for one-click replay during testing.
do  -- lurek.automation.listMacros
  for _, name in ipairs(lurek.automation.listMacros()) do
    lurek.log.debug("macro available: " .. name, "automation")
  end
end

--@api-stub: lurek.automation.setPlaybackSpeed
-- Sets the dt multiplier for script playback (0.5 = half speed, 2.0 = double).
-- Use 4.0 in CI to slash test runtime; negative values clamp to 0 (frozen clock) instead of rewinding.
do  -- lurek.automation.setPlaybackSpeed
  local fast_ci = true
  lurek.automation.setPlaybackSpeed(fast_ci and 4.0 or 1.0)
end

--@api-stub: lurek.automation.getPlaybackSpeed
-- Returns the current playback speed multiplier (default 1.0).
-- Read after a config-driven `setPlaybackSpeed` to confirm clamping (e.g. negative inputs become 0).
do  -- lurek.automation.getPlaybackSpeed
  local speed = lurek.automation.getPlaybackSpeed()
  if speed ~= 1.0 then
    lurek.log.info("automation running at " .. speed .. "x", "automation")
  end
end

--@api-stub: lurek.automation.setHighlightMode
-- Enables or disables the highlight overlay hint.
-- Turn on during recording/demo capture so a render pass can draw the simulated cursor for the audience.
do  -- lurek.automation.setHighlightMode
  local recording = true
  lurek.automation.setHighlightMode(recording)
end

--@api-stub: lurek.automation.isHighlightMode
-- Returns whether the highlight overlay hint is active.
-- Branch your render code on this so the highlight ring only paints when the toggle is on.
do  -- lurek.automation.isHighlightMode
  local gfx = lurek.render
  function lurek.render()
    if lurek.automation.isHighlightMode() then
      gfx.setColor(1, 1, 0, 0.5)
      gfx.circle("line", 320, 240, 24)
    end
  end
end

--@api-stub: lurek.automation.waitUntil
-- Pauses playback advancement until predicate() returns true or timeout seconds elapse.
-- Use to sync scripted input with async events (level loaded, asset streamed); the timeout is a safety net.
do  -- lurek.automation.waitUntil
  local level_ready = false
  function lurek.init()
    lurek.automation.waitUntil(function() return level_ready end, 5.0)
  end
end
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
