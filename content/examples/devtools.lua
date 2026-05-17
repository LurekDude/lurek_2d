-- content/examples/devtools.lua
-- lurek.devtools API examples: logging, profiling, file watching, REPL, watches, and inspection.
-- Run: cargo run -- content/examples/devtools.lua

-- =============================================================================
-- LOGGING
-- =============================================================================

--@api-stub: lurek.devtools.log
-- Adds a message to the devtools log using an explicit severity level
do
  -- Use log() when the severity is determined at runtime.
  -- Levels: "trace", "debug", "info", "warn", "error", "fatal"
  -- Common pattern: choose severity based on game state thresholds.
  local hp, max_hp = 12, 100
  local level = (hp < max_hp * 0.2) and "warn" or "info"
  lurek.devtools.log(level, "player hp " .. hp .. "/" .. max_hp)

  -- Useful for generic logging helpers where the caller decides severity.
  local function log_asset(severity, asset_path, msg)
    lurek.devtools.log(severity, "[asset:" .. asset_path .. "] " .. msg)
  end
  log_asset("debug", "hero.png", "loaded 256x256 RGBA")
end

--@api-stub: lurek.devtools.trace
-- Adds a trace-level diagnostic message to the devtools log
do
  -- Trace is the most verbose level. Use for per-frame data only needed
  -- during deep debugging sessions. Hidden by default until setLogLevel("trace").
  local dt = 1 / 60
  lurek.devtools.trace("tick dt=" .. string.format("%.4f", dt) .. " entities=128")
end

--@api-stub: lurek.devtools.debug
-- Adds a debug-level diagnostic message to the devtools log
do
  -- Debug is for implementation details useful during development.
  -- Example: tracking state machine transitions.
  local state = "attacking"
  local target_id = 42
  lurek.devtools.debug("AI state -> " .. state .. " target=" .. target_id)
end

--@api-stub: lurek.devtools.info
-- Adds an info-level diagnostic message to the devtools log
do
  -- Info is for milestones and confirmations during normal operation.
  -- Example: level loaded, save complete, connection established.
  local level_name = "forest_01"
  local entity_count = 87
  lurek.devtools.info("level '" .. level_name .. "' loaded: " .. entity_count .. " entities")
end

--@api-stub: lurek.devtools.warn
-- Adds a warning-level diagnostic message to the devtools log
do
  -- Warn is for recoverable problems that may degrade quality.
  -- Example: fallback texture used, slow frame detected, deprecated API call.
  local texture = "assets/hero_alt.png"
  lurek.devtools.warn("texture not found: " .. texture .. " — using placeholder")
end

--@api-stub: lurek.devtools.error
-- Adds an error-level diagnostic message to the devtools log
do
  -- Error is for failures that impact gameplay but do not crash.
  -- Example: save failed, network timeout, script error caught by pcall.
  local path = "save/slot1.sav"
  local ok = false
  if not ok then
    lurek.devtools.error("save failed: " .. path .. " (disk full?)")
  end
end

--@api-stub: lurek.devtools.fatal
-- Adds a fatal-level diagnostic message to the devtools log
do
  -- Fatal is for unrecoverable states. It logs the message but does NOT
  -- raise or halt execution — your code must handle shutdown separately.
  local ok, err = pcall(function()
    error("GPU device lost")
  end)
  if not ok then
    lurek.devtools.fatal("critical failure: " .. tostring(err))
    -- Game would initiate graceful shutdown here.
  end
end

--@api-stub: lurek.devtools.setLogLevel
-- Sets the minimum severity that remains visible in devtools log output
do
  -- Messages below this level are silently discarded.
  -- Set to "debug" during development, "info" or "warn" for shipping builds.
  local is_shipping = false
  lurek.devtools.setLogLevel(is_shipping and "warn" or "debug")
  -- This trace message will be hidden because level is "debug":
  lurek.devtools.trace("this is suppressed")
  -- This debug message will pass:
  lurek.devtools.debug("this is visible")
end

--@api-stub: lurek.devtools.getLogLevel
-- Returns the minimum severity currently used by devtools log output
do
  -- Use to conditionally skip expensive string formatting.
  local current = lurek.devtools.getLogLevel()
  if current == "trace" or current == "debug" then
    -- Only build expensive debug strings when they would actually be logged.
    local dump = "entity_positions={...}"  -- imagine a costly serialization
    lurek.devtools.debug(dump)
  end
end

--@api-stub: lurek.devtools.setLogConsole
-- Enables or disables mirroring devtools log entries to the console
do
  -- When true, all devtools.log/info/warn/etc. messages also appear in stdout.
  -- Useful during development without an in-game console overlay.
  lurek.devtools.setLogConsole(true)
  lurek.devtools.info("messages now visible in terminal output")
end

--@api-stub: lurek.devtools.getLogConsole
-- Returns whether devtools log entries are mirrored to the console
do
  -- Guard expensive debug output behind console-enabled checks.
  if lurek.devtools.getLogConsole() then
    lurek.devtools.debug("console active — verbose output enabled")
  end
end

--@api-stub: lurek.devtools.setLogFile
-- Sets the file path used by devtools file logging state
do
  -- Direct devtools log output to a file for post-session analysis.
  -- Combine with a session ID to keep logs separated per play session.
  local session_id = os.time and os.time() or 1700000000
  local path = "save/logs/session_" .. session_id .. ".log"
  lurek.devtools.setLogFile(path)
  lurek.devtools.info("file logging started: " .. path)
end

--@api-stub: lurek.devtools.getLogFile
-- Returns the file path currently stored as the devtools log target
do
  -- Check if file logging is configured before relying on it.
  local path = lurek.devtools.getLogFile()
  if path == "" then
    lurek.devtools.warn("no log file set — crash reports will lack file output")
  else
    lurek.devtools.debug("logging to: " .. path)
  end
end

--@api-stub: lurek.devtools.getLogHistory
-- Returns recent devtools log entries as structured tables
do
  -- Retrieve the last N log entries. Each entry has:
  --   .level (string), .timestamp (number), .message (string),
  --   .source (string), .line (number), .category (string or nil)
  lurek.devtools.info("loading level forest_01")
  lurek.devtools.warn("missing optional asset")
  local recent = lurek.devtools.getLogHistory(5)
  for _, entry in ipairs(recent) do
    -- Display in an in-game console overlay:
    lurek.devtools.trace("[" .. entry.level .. "] " .. entry.message)
  end
end

--@api-stub: lurek.devtools.clearLog
-- Clears all in-memory devtools log entries
do
  -- Clear stale messages on scene transitions so the debug console
  -- only shows messages relevant to the current scene.
  lurek.devtools.info("old scene messages")
  lurek.devtools.clearLog()
  lurek.devtools.info("scene transition complete — log cleared")
  local history = lurek.devtools.getLogHistory(100)
  -- Only the "scene transition" message remains.
  lurek.devtools.debug("entries after clear: " .. #history)
end

-- =============================================================================
-- PROFILING
-- =============================================================================

--@api-stub: lurek.devtools.setProfilingEnabled
-- Enables or disables collection of CPU profiling zones
do
  -- Toggle profiling with a debug key. When disabled, profilePush/Pop
  -- calls become no-ops with near-zero overhead.
  local debug_mode = true
  lurek.devtools.setProfilingEnabled(debug_mode)
  lurek.devtools.info("profiler " .. (debug_mode and "enabled" or "disabled"))
end

--@api-stub: lurek.devtools.isProfilingEnabled
-- Returns whether CPU profiling zone collection is currently enabled
do
  -- Use to guard expensive profiling annotations that build strings.
  if lurek.devtools.isProfilingEnabled() then
    lurek.devtools.profilePush("ai_decision_tree")
    -- ... AI logic ...
    lurek.devtools.profilePop()
  end
end

--@api-stub: lurek.devtools.profilePush
-- Starts a named profiling zone on the current profiler stack
do
  -- Push/Pop zones nest. The profiler builds a tree:
  --   game_update
  --     physics_step
  --     ai_update
  --       pathfinding
  --     render_submit
  lurek.devtools.setProfilingEnabled(true)
  lurek.devtools.profilePush("game_update")
  lurek.devtools.profilePush("physics_step")
  -- ... physics simulation ...
  lurek.devtools.profilePop()
  lurek.devtools.profilePush("ai_update")
  lurek.devtools.profilePush("pathfinding")
  -- ... A* search ...
  lurek.devtools.profilePop()
  lurek.devtools.profilePop()
  lurek.devtools.profilePop()
end

--@api-stub: lurek.devtools.profilePop
-- Ends the current profiling zone on the profiler stack
do
  -- Always match every Push with a Pop. Mismatched calls produce
  -- incorrect zone trees. Wrap in pcall if the work might error.
  lurek.devtools.setProfilingEnabled(true)
  lurek.devtools.profilePush("render_world")
  local ok, err = pcall(function()
    -- ... draw calls that might fail ...
  end)
  lurek.devtools.profilePop()  -- Pop even if the work errored.
  if not ok then
    lurek.devtools.error("render failed: " .. tostring(err))
  end
end

--@api-stub: lurek.devtools.profileFrame
-- Closes the current profiling frame and stores its zone tree for later inspection
do
  -- Call once per frame at the end of your game loop.
  -- The stored frame can be queried later with getProfileData.
  function lurek.process(dt)
    lurek.devtools.profilePush("frame")
    -- ... entire frame logic ...
    lurek.devtools.profilePop()
    lurek.devtools.profileFrame()  -- Stores this frame's zone tree.
  end
end

--@api-stub: lurek.devtools.getProfileFrameCount
-- Returns how many profiling frames are currently stored
do
  -- Frames accumulate until resetProfile() is called.
  -- Use to determine when you have enough data for meaningful statistics.
  local n = lurek.devtools.getProfileFrameCount()
  if n >= 60 then
    lurek.devtools.info("profiler: " .. n .. " frames buffered — ready for analysis")
  else
    lurek.devtools.debug("profiler: " .. n .. "/60 frames collected")
  end
end

--@api-stub: lurek.devtools.getProfileData
-- Returns the profiler zone tree for a retained frame
do
  -- Each zone entry has: .name, .time (total seconds), .selfTime (excluding children),
  -- .startTime (relative offset), and .children (nested zones array).
  -- Frame index 0 = oldest retained frame.
  local zones = lurek.devtools.getProfileData(0)
  for _, z in ipairs(zones) do
    local ms = z.time * 1000
    local self_ms = z.selfTime * 1000
    lurek.devtools.debug(
      string.format("  %s: %.2fms total, %.2fms self", z.name, ms, self_ms)
    )
  end
end

--@api-stub: lurek.devtools.resetProfile
-- Clears profiler state, active zones, and retained profiling frames
do
  -- Use when starting a benchmark from a known clean state.
  lurek.devtools.resetProfile()
  lurek.devtools.info("profiler reset — starting fresh benchmark")
  lurek.devtools.profilePush("benchmark_run")
  -- ... code under test ...
  lurek.devtools.profilePop()
  lurek.devtools.profileFrame()
end

--@api-stub: lurek.devtools.profilerReport
-- Aggregates retained profiler frames into per-zone timing rows
do
  -- Builds a summary across all retained frames.
  -- Each row: .name, .calls, .total_ms, .avg_ms, .min_ms, .max_ms, .self_ms
  -- Perfect for displaying a profiler overlay or writing a report.
  lurek.devtools.setProfilingEnabled(true)
  lurek.devtools.profilePush("sim")
  lurek.devtools.profilePop()
  lurek.devtools.profileFrame()
  local report = lurek.devtools.profilerReport()
  for _, row in ipairs(report) do
    lurek.devtools.info(string.format(
      "%s: avg=%.2fms, calls=%d, self=%.2fms",
      row.name, row.avg_ms, row.calls, row.self_ms
    ))
  end
end

-- =============================================================================
-- FRAME TIMING
-- =============================================================================

--@api-stub: lurek.devtools.recordFrameTime
-- Records one CPU frame duration sample for devtools frame statistics
do
  -- Call every frame with the delta time. Devtools accumulates samples
  -- for statistical analysis (min, max, avg, percentiles).
  function lurek.process(dt)
    lurek.devtools.recordFrameTime(dt)
  end
end

--@api-stub: lurek.devtools.getFrameStats
-- Returns aggregate CPU frame timing statistics from recorded samples
do
  -- Returns a table: .fps, .dt, .avg, .min, .max, .p50, .p95, .p99, .samples
  -- Use for an FPS counter overlay or performance budget warnings.
  lurek.devtools.recordFrameTime(0.016)
  lurek.devtools.recordFrameTime(0.017)
  lurek.devtools.recordFrameTime(0.032)  -- A spike frame
  local s = lurek.devtools.getFrameStats()
  lurek.devtools.info(string.format(
    "FPS: %.0f | avg: %.1fms | p99: %.1fms | samples: %d",
    s.fps, s.avg * 1000, s.p99 * 1000, s.samples
  ))
  if s.p99 > 0.020 then
    lurek.devtools.warn("p99 exceeds 20ms budget — investigate hitches")
  end
end

--@api-stub: lurek.devtools.recordGpuFrameTime
-- Records one GPU frame duration sample for devtools frame statistics
do
  -- Separate GPU timing lets you distinguish CPU-bound from GPU-bound frames.
  -- Pass the GPU-side frame duration (from timestamp queries or estimation).
  function lurek.process(dt)
    local gpu_dt = dt * 0.7  -- Hypothetical GPU measurement
    lurek.devtools.recordGpuFrameTime(gpu_dt)
  end
end

--@api-stub: lurek.devtools.getGpuFrameStats
-- Returns aggregate GPU frame timing statistics from recorded samples
do
  -- Same structure as getFrameStats but for GPU timings.
  -- Compare CPU vs GPU stats to identify the bottleneck.
  lurek.devtools.recordGpuFrameTime(0.008)
  lurek.devtools.recordGpuFrameTime(0.009)
  local gpu = lurek.devtools.getGpuFrameStats()
  local cpu = lurek.devtools.getFrameStats()
  local bottleneck = (gpu.avg > cpu.avg) and "GPU" or "CPU"
  lurek.devtools.info("bottleneck: " .. bottleneck ..
    " (cpu=" .. string.format("%.1f", cpu.avg * 1000) ..
    "ms, gpu=" .. string.format("%.1f", gpu.avg * 1000) .. "ms)")
end

--@api-stub: lurek.devtools.getFrameHistory
-- Returns retained CPU frame duration samples in insertion order
do
  -- Returns an array of raw dt values (seconds). Use for plotting
  -- a frame-time graph in a debug overlay.
  lurek.devtools.recordFrameTime(0.016)
  lurek.devtools.recordFrameTime(0.017)
  lurek.devtools.recordFrameTime(0.033)
  local history = lurek.devtools.getFrameHistory()
  -- Find the worst frame in the history for spike detection:
  local worst = 0
  for _, dt in ipairs(history) do
    if dt > worst then worst = dt end
  end
  lurek.devtools.debug("worst frame in history: " .. string.format("%.1f", worst * 1000) .. "ms")
end

--@api-stub: lurek.devtools.setFrameHistorySize
-- Sets the maximum number of CPU frame duration samples retained by devtools
do
  -- Default is usually small. Increase for longer frame graphs.
  -- 600 samples at 60fps = 10 seconds of history.
  lurek.devtools.setFrameHistorySize(600)
  lurek.devtools.info("frame history: 10s window at 60fps")
end

--@api-stub: lurek.devtools.getFrameHistorySize
-- Returns the current CPU frame history capacity
do
  -- Values above 10000 are clamped internally. Use to verify the cap.
  lurek.devtools.setFrameHistorySize(50000)
  local actual = lurek.devtools.getFrameHistorySize()
  lurek.devtools.info("requested 50000, got " .. actual .. " (internal cap applies)")
end

-- =============================================================================
-- FILE WATCHING (module-level)
-- =============================================================================

--@api-stub: lurek.devtools.watch
-- Adds a path to the module-level devtools file watcher
do
  -- Returns true if the path was newly added, false if already watched.
  -- Use for hot-reload workflows: watch script files and reload on change.
  local added = lurek.devtools.watch("content/examples/devtools.lua")
  lurek.devtools.info("watch added: " .. tostring(added))

  -- Watching the same path twice returns false (no duplicate):
  local dup = lurek.devtools.watch("content/examples/devtools.lua")
  lurek.devtools.debug("duplicate add: " .. tostring(dup))
end

--@api-stub: lurek.devtools.unwatch
-- Removes a path from the module-level devtools file watcher
do
  -- Returns true if the path was actually being watched and is now removed.
  lurek.devtools.watch("content/levels/forest_01.toml")
  local removed = lurek.devtools.unwatch("content/levels/forest_01.toml")
  lurek.devtools.debug("unwatched forest_01: " .. tostring(removed))

  -- Unwatching a path not in the list returns false:
  local noop = lurek.devtools.unwatch("nonexistent.lua")
  lurek.devtools.debug("unwatch nonexistent: " .. tostring(noop))
end

--@api-stub: lurek.devtools.getWatchedPaths
-- Returns all paths currently watched by the module-level file watcher
do
  -- Returns a sorted array of path strings. Use to display
  -- which files are being monitored in a debug panel.
  lurek.devtools.watch("conf.toml")
  lurek.devtools.watch("main.lua")
  local paths = lurek.devtools.getWatchedPaths()
  lurek.devtools.info("monitoring " .. #paths .. " file(s):")
  for _, p in ipairs(paths) do
    lurek.devtools.debug("  " .. p)
  end
end

--@api-stub: lurek.devtools.scan
-- Polls module-level file watches and returns paths that changed since the previous scan
do
  -- Call scan() each frame (or at your watch interval). It returns only
  -- the paths that changed since the last scan — use to trigger reload.
  lurek.devtools.watch("content/examples/devtools.lua")
  lurek.devtools.watch("conf.toml")
  function lurek.process(dt)
    local changed = lurek.devtools.scan()
    for _, path in ipairs(changed) do
      lurek.devtools.info("hot-reload triggered: " .. path)
      -- Reload the changed script or config here.
    end
  end
end

--@api-stub: lurek.devtools.clearWatches
-- Removes every path from the module-level file watcher
do
  -- Use on scene transitions to stop watching old scene files.
  lurek.devtools.watch("old_scene.lua")
  lurek.devtools.watch("old_data.toml")
  lurek.devtools.clearWatches()
  local remaining = lurek.devtools.getWatchedPaths()
  lurek.devtools.info("watches after clear: " .. #remaining)  -- 0
end

--@api-stub: lurek.devtools.getWatchInterval
-- Returns the polling interval hint used by devtools watch UIs
do
  -- The interval is a hint for UIs that visualize watch state.
  -- A smaller interval means faster detection but more filesystem polling.
  local interval = lurek.devtools.getWatchInterval()
  lurek.devtools.info("current watch poll interval: " .. interval .. "s")
end

--@api-stub: lurek.devtools.setWatchInterval
-- Sets the polling interval hint used by devtools watch UIs
do
  -- Set to 0.25s for responsive hot-reload; increase for battery savings.
  -- Minimum is 0.01s (clamped internally).
  lurek.devtools.setWatchInterval(0.25)
  lurek.devtools.info("watch interval set to " .. lurek.devtools.getWatchInterval() .. "s")
end

-- =============================================================================
-- DEBUGGING & INSPECTION
-- =============================================================================

--@api-stub: lurek.devtools.getCallStack
-- Returns Lua call stack frames using the Lua debug library
do
  -- Returns up to max_depth frames (default 20, max 100).
  -- Each frame: .source, .line, .name, .what
  -- Useful for error reporting or building stack traces in-game.
  local function inner_function()
    local frames = lurek.devtools.getCallStack(5)
    for i, f in ipairs(frames) do
      ---@cast f {source: string, line: integer, name: string, what: string}
      lurek.devtools.debug(string.format(
        "#%d %s:%d in %s (%s)", i, f.source, f.line, f.name, f.what
      ))
    end
  end
  inner_function()
end

--@api-stub: LReplConsole:eval
-- Evaluates Lua code in the current state and returns success plus values or failure plus an error message
do
  -- Returns (true, result) on success, (false, error_string) on failure.
  -- Use for in-game console commands, debug expressions, or live tweaking.
  local ok, value = lurek.devtools.eval("return 2 + 2")
  if ok then
    lurek.devtools.info("eval result: " .. tostring(value))
  end

  -- Error case: syntax or runtime error returns false + message.
  local ok2, err = lurek.devtools.eval("return undefined_var.field")
  if not ok2 then
    lurek.devtools.warn("eval error: " .. tostring(err))
  end
end

--@api-stub: lurek.devtools.openConsole
-- Marks the devtools console as open for UI state tracking
do
  -- This is a UI state flag. It does not render anything — your game UI
  -- reads isConsoleOpen() to decide whether to draw the console panel.
  lurek.devtools.openConsole()
  lurek.devtools.debug("console open flag: " .. tostring(lurek.devtools.isConsoleOpen()))
end

--@api-stub: lurek.devtools.isConsoleOpen
-- Returns whether the devtools console is marked open
do
  -- Use in your draw_ui callback to conditionally render the console.
  function lurek.draw_ui()
    if lurek.devtools.isConsoleOpen() then
      -- Draw console background, input field, log history...
      lurek.devtools.trace("drawing console overlay")
    end
  end
end

--@api-stub: lurek.devtools.openEntityInspector
-- Marks the devtools entity inspector as open for UI state tracking
do
  -- Another UI flag for an entity/component inspector panel.
  -- Your game decides what "entity inspector" means.
  lurek.devtools.openEntityInspector()
  lurek.devtools.debug("entity inspector opened")
end

--@api-stub: lurek.devtools.isEntityInspectorOpen
-- Returns whether the devtools entity inspector is marked open
do
  -- Pattern: toggle panels with keyboard shortcuts.
  function lurek.draw_ui()
    if lurek.devtools.isEntityInspectorOpen() then
      -- Show entity list, components, selected entity details...
      lurek.devtools.trace("drawing entity inspector")
    end
  end
end

-- =============================================================================
-- WATCH EXPRESSIONS
-- =============================================================================

--@api-stub: lurek.devtools.exposeWatch
-- Registers a watch expression callback for snapshots and watch panels
do
  -- Watches are named getter callbacks. External tools (VS Code extension,
  -- in-game overlay) can poll getWatches() to display live values.
  -- Optional category groups watches in the UI.
  local player = { x = 256.5, y = 128.0, hp = 80, max_hp = 100 }
  lurek.devtools.exposeWatch("player.x", function() return player.x end, "position")
  lurek.devtools.exposeWatch("player.y", function() return player.y end, "position")
  lurek.devtools.exposeWatch("player.hp", function()
    return player.hp .. "/" .. player.max_hp
  end, "combat")
  lurek.devtools.debug("3 watches registered for player state")
end

--@api-stub: lurek.devtools.removeWatch
-- Removes a previously exposed watch expression by id
do
  -- exposeWatch returns a numeric id. Pass it to removeWatch to unregister.
  -- Returns true if the watch existed and was removed.
  local score = 0
  local id = lurek.devtools.exposeWatch("score", function() return score end, "hud")
  lurek.devtools.debug("watch id=" .. id)
  local removed = lurek.devtools.removeWatch(id)
  lurek.devtools.debug("removed: " .. tostring(removed))  -- true
  local again = lurek.devtools.removeWatch(id)
  lurek.devtools.debug("remove again: " .. tostring(again))  -- false (already gone)
end

--@api-stub: lurek.devtools.getWatches
-- Evaluates exposed watch callbacks and returns their current values
do
  -- Returns an array of {name, category, value} tables.
  -- The getter is called at query time so values are always fresh.
  local frame_count = 0
  lurek.devtools.exposeWatch("frames", function() return frame_count end, "engine")
  lurek.devtools.exposeWatch("time", function() return frame_count / 60 end, "engine")
  frame_count = 120

  local watches = lurek.devtools.getWatches()
  for _, w in ipairs(watches) do
    lurek.devtools.info(w.category .. "/" .. w.name .. " = " .. tostring(w.value))
  end
end

-- =============================================================================
-- SNAPSHOTS
-- =============================================================================

--@api-stub: lurek.devtools.snapshot
-- Captures a combined devtools snapshot containing frame stats, watch values, profile data, and recent logs
do
  -- A snapshot bundles everything into one table:
  --   .frameStats (same as getFrameStats)
  --   .watches (same as getWatches)
  --   .profile (zone data)
  --   .log (recent entries)
  --   .watchCount (number of registered watches)
  -- Use to serialize the full devtools state for external tools or crash reports.
  lurek.devtools.recordFrameTime(0.016)
  lurek.devtools.exposeWatch("test", function() return "ok" end)
  local snap = lurek.devtools.snapshot()
  lurek.devtools.info(string.format(
    "snapshot: fps=%.0f, watches=%d, log_entries=%d",
    snap.frameStats.fps, snap.watchCount, #snap.log
  ))
end

-- =============================================================================
-- FILE WATCHER USERDATA (per-path watcher)
-- =============================================================================

--@api-stub: lurek.devtools.newFileWatcher
-- Creates a dedicated file watcher userdata for one path
do
  -- Unlike module-level watch/scan, newFileWatcher creates a handle
  -- with its own callback. Use for watching specific config files.
  local fw = lurek.devtools.newFileWatcher("content/examples/devtools.lua")
  fw:onChanged(function()
    lurek.devtools.info("devtools.lua modified — reloading")
  end)
  -- Poll in your game loop:
  function lurek.process(dt)
    fw:check()
  end
end

--@api-stub: LFileWatcher:onChanged
-- Fires the callback registered for the changed event on this file watcher.
do
  -- The callback receives no arguments. Use a closure to capture context.
  local fw = lurek.devtools.newFileWatcher("conf.toml")
  local reload_count = 0
  fw:onChanged(function()
    reload_count = reload_count + 1
    lurek.devtools.info("conf.toml reloaded (#" .. reload_count .. ")")
    -- Re-read the config file, apply changes...
  end)
end

--@api-stub: LFileWatcher:check
-- Checks on this file watcher and returns the result.
do
  -- Returns true if a change was detected (and callback was fired).
  -- Returns false if no change. Call periodically.
  local fw = lurek.devtools.newFileWatcher("content/examples/devtools.lua")
  fw:onChanged(function() end)
  function lurek.process(dt)
    local changed = fw:check()
    if changed then
      lurek.devtools.info("file changed this frame")
    end
  end
end

--@api-stub: LFileWatcher:getPath
-- Returns the path of this file watcher.
do
  -- Useful when you store multiple watchers in a list.
  local fw = lurek.devtools.newFileWatcher("content/levels/forest_01.toml")
  fw:onChanged(function()
    lurek.devtools.info("changed: " .. fw:getPath())
  end)
  lurek.devtools.debug("watcher target: " .. fw:getPath())
end

--@api-stub: LFileWatcher:cancel
-- Cancels the current operation of this file watcher.
do
  -- After cancel(), check() becomes a no-op and the callback is cleared.
  -- Use when a watched file is no longer relevant (e.g., scene unloaded).
  local fw = lurek.devtools.newFileWatcher("conf.toml")
  fw:onChanged(function() lurek.devtools.info("changed") end)
  fw:cancel()
  lurek.devtools.debug("watcher cancelled for: " .. fw:getPath())
  -- fw:check() will now always return false.
end

-- =============================================================================
-- REPL CONSOLE
-- =============================================================================

--@api-stub: lurek.devtools.newRepl
-- Creates a REPL console userdata with bounded command history
do
  -- The REPL evaluates code in the current Lua VM and stores history.
  -- max_history limits stored lines (default 200).
  -- Use for in-game developer consoles.
  local repl = lurek.devtools.newRepl(100)
  local result = repl:eval("return math.pi * 2")
  lurek.devtools.info("repl: pi*2 = " .. tostring(result))
end

--@api-stub: LReplConsole:eval
-- Performs the eval operation on this repl console.
do
  -- eval() runs Lua code and returns the result.
  -- The command is automatically added to history.
  local repl = lurek.devtools.newRepl(50)
  local greeting = repl:eval("return string.upper('hello world')")
  lurek.devtools.info("> " .. tostring(greeting))

  -- Side effects work too:
  repl:eval("_G.debug_flag = true")
  local flag = repl:eval("return _G.debug_flag")
  lurek.devtools.debug("debug_flag = " .. tostring(flag))
end

--@api-stub: LReplConsole:history
-- Performs the history operation on this repl console.
do
  -- Returns an array of previously evaluated command strings.
  -- Use for command recall (up/down arrow in a console UI).
  local repl = lurek.devtools.newRepl(20)
  repl:eval("x = 1")
  repl:eval("x = x + 1")
  repl:eval("return x")
  local hist = repl:history()
  lurek.devtools.info("history (" .. #hist .. " entries):")
  for i, line in ipairs(hist) do
    lurek.devtools.debug("  " .. i .. ": " .. line)
  end
end

--@api-stub: LReplConsole:clear
-- Clears all items from this repl console.
do
  -- Wipes command history. Use for a "clear" command in the console.
  local repl = lurek.devtools.newRepl(10)
  repl:eval("return 1")
  repl:eval("return 2")
  lurek.devtools.debug("before clear: " .. repl:len() .. " entries")
  repl:clear()
  lurek.devtools.debug("after clear: " .. repl:len() .. " entries")  -- 0
end

--@api-stub: LReplConsole:len
-- Performs the len operation on this repl console.
do
  -- Returns the number of entries stored in history.
  -- Use to show "5/100" in the console status bar.
  local repl = lurek.devtools.newRepl(100)
  repl:eval("print('a')")
  repl:eval("print('b')")
  lurek.devtools.info("REPL history: " .. repl:len() .. "/100")
end

-- =============================================================================
-- TYPE INTROSPECTION (LFileWatcher)
-- =============================================================================

--@api-stub: LReplConsole:type
-- Returns the Lua-visible type name for this file watcher handle
do
  -- Returns the string "LFileWatcher". Use for debugging or type dispatch.
  local fw = lurek.devtools.newFileWatcher("save/")
  lurek.devtools.debug("type = " .. fw:type())  -- "LFileWatcher"
end

--@api-stub: LReplConsole:typeOf
-- Returns whether this file watcher handle matches a supported type name
do
  -- Checks against "LFileWatcher" and the base "Object" type.
  local fw = lurek.devtools.newFileWatcher("save/")
  lurek.devtools.debug("is LFileWatcher: " .. tostring(fw:typeOf("LFileWatcher")))  -- true
  lurek.devtools.debug("is Object: " .. tostring(fw:typeOf("Object")))  -- true
  lurek.devtools.debug("is LSource: " .. tostring(fw:typeOf("LSource")))  -- false
end

-- =============================================================================
-- TYPE INTROSPECTION (LReplConsole)
-- =============================================================================

--@api-stub: LReplConsole:type
-- Returns the Lua-visible type name for this REPL console handle
do
  -- Returns the string "LReplConsole".
  local repl = lurek.devtools.newRepl(50)
  lurek.devtools.debug("type = " .. repl:type())  -- "LReplConsole"
end

--@api-stub: LReplConsole:typeOf
-- Returns whether this REPL console handle matches a supported type name
do
  -- Checks against "LReplConsole" and the base "Object" type.
  local repl = lurek.devtools.newRepl(50)
  lurek.devtools.debug("is LReplConsole: " .. tostring(repl:typeOf("LReplConsole")))  -- true
  lurek.devtools.debug("is Object: " .. tostring(repl:typeOf("Object")))  -- true
  lurek.devtools.debug("is LFileWatcher: " .. tostring(repl:typeOf("LFileWatcher")))  -- false
end

print("content/examples/devtools.lua")

-- =============================================================================
-- STUBS: 8 uncovered lurek.devtools API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LFileWatcher methods
-- -----------------------------------------------------------------------------
