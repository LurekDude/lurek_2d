-- content/examples/devtools.lua
-- Hand-written coverage of the lurek.devtools API (48 items).
--
-- The lurek.devtools namespace bundles in-engine logging, frame-time
-- statistics, a hierarchical profiler, file watchers, a snapshot
-- service, and a Lua REPL — all aimed at runtime debugging without
-- pulling in external tooling. State is per-engine-instance and
-- persists across frames; call resetProfile / clearLog between runs.
--
-- Run: cargo run -- content/examples/devtools.lua

-- ── lurek.devtools.* functions ──

--@api-stub: lurek.devtools.log
-- Logs a message at the given level.
-- Use when the level is computed from config; unknown levels are silently dropped, so prefer setLogLevel for the threshold.
do  -- lurek.devtools.log
  local hp, max_hp = 12, 100
  local level = (hp < max_hp * 0.2) and "warn" or "info"
  lurek.devtools.log(level, "player hp " .. hp .. "/" .. max_hp)
end

--@api-stub: lurek.devtools.setLogLevel
-- Sets the minimum log level.
-- Call once at startup from conf; use "info" in shipping builds and "debug"/"trace" while iterating.
do  -- lurek.devtools.setLogLevel
  local shipping = false
  lurek.devtools.setLogLevel(shipping and "info" or "debug")
  lurek.devtools.debug("verbose traces enabled")
end

--@api-stub: lurek.devtools.getLogLevel
-- Returns the current minimum log level.
-- Useful when a debug menu wants to display the active threshold or guard expensive trace formatting.
do  -- lurek.devtools.getLogLevel
  local current = lurek.devtools.getLogLevel()
  if current == "trace" or current == "debug" then
    lurek.devtools.debug("verbose path active (level=" .. current .. ")")
  end
end

--@api-stub: lurek.devtools.setLogConsole
-- Enables or disables console log output.
-- Disable on shipped builds where stdout is captured by an OS log view; pair with setLogFile for offline triage.
do  -- lurek.devtools.setLogConsole
  lurek.devtools.setLogConsole(true)
  lurek.devtools.info("console logging on; ready for live debugging")
end

--@api-stub: lurek.devtools.getLogConsole
-- Returns whether console log output is enabled.
-- Branch on the result before doing expensive string concatenation for a log line.
do  -- lurek.devtools.getLogConsole
  if lurek.devtools.getLogConsole() then
    local entities = 128
    lurek.devtools.debug("world tick: entities=" .. entities)
  end
end

--@api-stub: lurek.devtools.setLogFile
-- Sets the log file path (empty string disables file output).
-- Use a per-session filename so older crash reports are not overwritten when the player relaunches.
do  -- lurek.devtools.setLogFile
  local session_id = 1742
  lurek.devtools.setLogFile("save/logs/session_" .. session_id .. ".log")
  lurek.devtools.info("session log file opened")
end

--@api-stub: lurek.devtools.getLogFile
-- Returns the current log file path.
-- Show this in a settings panel or copy-to-clipboard helper so players can attach the file to bug reports.
do  -- lurek.devtools.getLogFile
  local path = lurek.devtools.getLogFile()
  if path == "" then
    lurek.devtools.warn("no log file configured; bug reports will lack file output")
  end
end

--@api-stub: lurek.devtools.getLogHistory
-- Returns recent log entries as an array of tables.
-- Pass a small count (10–50) when feeding an in-game console; entries carry level, timestamp, message, source, line, category.
do  -- lurek.devtools.getLogHistory
  lurek.devtools.info("loaded forest_01", "scene")
  local recent = lurek.devtools.getLogHistory(20)
  local last = recent[#recent]
  lurek.devtools.debug("last log: [" .. last.level .. "] " .. last.message)
end

--@api-stub: lurek.devtools.clearLog
-- Discards all accumulated log entries from the in-memory devtools log buffer.
-- Call when entering a new level or test scenario so the log viewer only shows messages from the current run.
do  -- lurek.devtools.clearLog
  lurek.devtools.info("old session noise")
  lurek.devtools.clearLog()
  lurek.devtools.info("fresh start: level transition complete")
end

--@api-stub: lurek.devtools.setProfilingEnabled
-- Enables or disables the profiler.
-- Leave off in shipping builds; toggle from a debug menu key so the cost is paid only while measuring.
do  -- lurek.devtools.setProfilingEnabled
  local debug_keys_held = true
  lurek.devtools.setProfilingEnabled(debug_keys_held)
  lurek.devtools.info("profiler now " .. (debug_keys_held and "on" or "off"))
end

--@api-stub: lurek.devtools.isProfilingEnabled
-- Returns whether the profiler is enabled.
-- Gate profilePush/profilePop calls behind this so disabled mode has zero per-zone overhead.
do  -- lurek.devtools.isProfilingEnabled
  if lurek.devtools.isProfilingEnabled() then
    lurek.devtools.profilePush("physics_step")
    lurek.devtools.profilePop()
  end
end

--@api-stub: lurek.devtools.profilePush
-- Opens a named profiling zone on the stack.
-- Pair with profilePop in the same scope; nest freely — the profiler aggregates parent/child timings.
do  -- lurek.devtools.profilePush
  lurek.devtools.setProfilingEnabled(true)
  lurek.devtools.profilePush("ai_update")
  lurek.devtools.profilePush("pathfinding")
  lurek.devtools.profilePop()
  lurek.devtools.profilePop()
end

--@api-stub: lurek.devtools.profilePop
-- Closes the most recent profiling zone.
-- Always call from the same code path that pushed; an unbalanced pop is silently ignored but skews timings.
do  -- lurek.devtools.profilePop
  lurek.devtools.setProfilingEnabled(true)
  lurek.devtools.profilePush("render_world")
  -- ... draw work happens here ...
  lurek.devtools.profilePop()
end

--@api-stub: lurek.devtools.profileFrame
-- Seals the current frame of profiling data.
-- Call once at the very end of every frame so getProfileData/profilerReport see complete frames.
do  -- lurek.devtools.profileFrame
  function lurek.process(dt)
    lurek.devtools.profilePush("frame")
    lurek.devtools.profilePop()
    lurek.devtools.profileFrame()
  end
end

--@api-stub: lurek.devtools.getProfileFrameCount
-- Returns the number of retained profile frames.
-- Use to avoid querying getProfileData(N) before N frames have been recorded.
do  -- lurek.devtools.getProfileFrameCount
  local n = lurek.devtools.getProfileFrameCount()
  if n >= 60 then
    lurek.devtools.info("profiler has " .. n .. " frames buffered — ready to summarise")
  end
end

--@api-stub: lurek.devtools.getProfileData
-- Returns zone data table for a specific frame (0 or nil = most recent).
-- Each zone entry is {name, time, selfTime, startTime, children}; recurse into children for nested timings.
do  -- lurek.devtools.getProfileData
  local zones = lurek.devtools.getProfileData(0)
  for _, z in ipairs(zones) do
    lurek.devtools.debug(z.name .. " total=" .. z.time .. "s self=" .. z.selfTime .. "s")
  end
end

--@api-stub: lurek.devtools.resetProfile
-- Clears all profiling data and resets the zone stack.
-- Call before a measurement run so previous warm-up frames don't pollute averages.
do  -- lurek.devtools.resetProfile
  lurek.devtools.resetProfile()
  lurek.devtools.profilePush("benchmark")
  lurek.devtools.profilePop()
  lurek.devtools.profileFrame()
end

--@api-stub: lurek.devtools.recordFrameTime
-- Records a frame-time sample (call each frame with delta time in seconds).
-- Feed the dt passed to lurek.process so getFrameStats sees real wall-clock time, not synthetic ticks.
do  -- lurek.devtools.recordFrameTime
  function lurek.process(dt)
    lurek.devtools.recordFrameTime(dt)
  end
end

--@api-stub: lurek.devtools.getFrameStats
-- Returns a table of computed frame statistics.
-- Read fps/avg/p95/p99 to drive an on-screen perf overlay; samples is the count of recorded frames.
do  -- lurek.devtools.getFrameStats
  lurek.devtools.recordFrameTime(1/60)
  local s = lurek.devtools.getFrameStats()
  if s.p99 > 0.020 then
    lurek.devtools.warn("p99 frame time " .. s.p99 .. "s exceeds 20ms budget")
  end
end

--@api-stub: lurek.devtools.getFrameHistory
-- Returns the raw frame-time sample array.
-- Plot directly as a graph or feed into your own statistics; oldest sample is index 1.
do  -- lurek.devtools.getFrameHistory
  lurek.devtools.recordFrameTime(0.016)
  local history = lurek.devtools.getFrameHistory()
  local latest = history[#history] or 0
  lurek.devtools.debug("latest frame: " .. (latest * 1000) .. " ms")
end

--@api-stub: lurek.devtools.setFrameHistorySize
-- Sets the frame-history buffer capacity (clamped 10-10000).
-- Larger buffers smooth percentile noise; 600 frames ≈ 10 seconds at 60 FPS is a good default.
do  -- lurek.devtools.setFrameHistorySize
  lurek.devtools.setFrameHistorySize(600)
  lurek.devtools.info("frame history sized for ~10s at 60fps")
end

--@api-stub: lurek.devtools.getFrameHistorySize
-- Returns the current frame-history buffer capacity.
-- Read after setFrameHistorySize to confirm the requested value was not clamped to the 10–10000 range.
do  -- lurek.devtools.getFrameHistorySize
  lurek.devtools.setFrameHistorySize(50000)
  local cap = lurek.devtools.getFrameHistorySize()
  lurek.devtools.info("frame history capacity = " .. cap .. " (clamped from 50000)")
end

--@api-stub: lurek.devtools.watch
-- Adds a file path to the watch list.
-- Returns false when already watched; combine with scan() in a per-frame check for hot-reload of Lua scripts or config.
do  -- lurek.devtools.watch
  local added = lurek.devtools.watch("content/examples/devtools.lua")
  if added then
    lurek.devtools.info("now watching devtools.lua for live reload")
  end
end

--@api-stub: lurek.devtools.unwatch
-- Removes a file path from the watch list.
-- Use when a tool finishes editing or a level unloads, so scan() doesn't keep stat-ing dead files.
do  -- lurek.devtools.unwatch
  lurek.devtools.watch("content/levels/forest_01.toml")
  local removed = lurek.devtools.unwatch("content/levels/forest_01.toml")
  lurek.devtools.debug("unwatched: " .. tostring(removed))
end

--@api-stub: lurek.devtools.getWatchedPaths
-- Returns an array of all watched paths.
-- Render in a debug overlay so contributors can see exactly which files trigger hot-reload.
do  -- lurek.devtools.getWatchedPaths
  lurek.devtools.watch("conf.toml")
  local paths = lurek.devtools.getWatchedPaths()
  lurek.devtools.info("watching " .. #paths .. " path(s)")
end

--@api-stub: lurek.devtools.scan
-- Polls all watched paths and returns paths whose mtime changed.
-- Throttle with setWatchInterval; iterate the result to reload only the files that actually changed.
do  -- lurek.devtools.scan
  lurek.devtools.watch("content/examples/devtools.lua")
  function lurek.process(dt)
    for _, path in ipairs(lurek.devtools.scan()) do
      lurek.devtools.info("reload: " .. path)
    end
  end
end

--@api-stub: lurek.devtools.clearWatches
-- Clears all watched paths.
-- Call on level transition to drop hot-reload registrations from the previous scene in one shot.
do  -- lurek.devtools.clearWatches
  lurek.devtools.watch("a.lua")
  lurek.devtools.watch("b.lua")
  lurek.devtools.clearWatches()
  lurek.devtools.info("watch list cleared (" .. #lurek.devtools.getWatchedPaths() .. " remain)")
end

--@api-stub: lurek.devtools.getWatchInterval
-- Returns the file watch poll interval in seconds.
-- Inspect when tuning hot-reload latency vs CPU cost; default is conservative for large project trees.
do  -- lurek.devtools.getWatchInterval
  local interval = lurek.devtools.getWatchInterval()
  if interval > 1.0 then
    lurek.devtools.warn("watch poll every " .. interval .. "s feels sluggish; consider 0.25")
  end
end

--@api-stub: lurek.devtools.setWatchInterval
-- Sets the file watch poll interval in seconds.
-- Lower values (0.1–0.25) for snappy iteration on small projects; raise to 1.0 if poll cost shows up in profiles.
do  -- lurek.devtools.setWatchInterval
  lurek.devtools.setWatchInterval(0.25)
  lurek.devtools.info("hot-reload poll @ " .. lurek.devtools.getWatchInterval() .. "s")
end

--@api-stub: lurek.devtools.getCallStack
-- Returns the Lua call stack as a table of frames.
-- Pass a max depth (default 20, capped at 100); each frame has source, line, name, what — great for crash dumps.
do  -- lurek.devtools.getCallStack
  local frames = lurek.devtools.getCallStack(10)
  for i, f in ipairs(frames) do
    lurek.devtools.debug("frame " .. i .. ": " .. f.source .. ":" .. f.line .. " in " .. f.name)
  end
end

--@api-stub: lurek.devtools.eval
-- Evaluates a Lua string and returns (success, results...).
-- Powers in-game consoles; on success, results follow the boolean; on error the second value is the error string.
do  -- lurek.devtools.eval
  local ok, value = lurek.devtools.eval("return 21 * 2")
  if ok then
    lurek.devtools.info("eval result = " .. tostring(value))
  end
end

--@api-stub: lurek.devtools.openConsole
-- Opens the console window (updates the console flag; returns true).
-- Wire to a key binding (e.g. backtick) so contributors can summon the REPL without restarting the game.
do  -- lurek.devtools.openConsole
  lurek.devtools.openConsole()
  lurek.devtools.info("console flag is now " .. tostring(lurek.devtools.isConsoleOpen()))
end

--@api-stub: lurek.devtools.isConsoleOpen
-- Returns whether the console is considered open.
-- Branch UI rendering on this so you don't draw the REPL when it's hidden.
do  -- lurek.devtools.isConsoleOpen
  function lurek.render_ui()
    if lurek.devtools.isConsoleOpen() then
      -- console panel would be drawn here
    end
  end
end

--@api-stub: lurek.devtools.exposeWatch
-- Registers a named live watch.
-- Pass a getter function so the value is sampled lazily; the optional category groups watches in viewers.
do  -- lurek.devtools.exposeWatch
  local player = { x = 256, y = 128, hp = 80 }
  local id_x = lurek.devtools.exposeWatch("player.x", function() return player.x end, "actor")
  local id_hp = lurek.devtools.exposeWatch("player.hp", function() return player.hp end, "combat")
  lurek.devtools.debug("registered watch ids " .. id_x .. ", " .. id_hp)
end

--@api-stub: lurek.devtools.removeWatch
-- Removes a watch by the id returned from exposeWatch.
-- Capture the id at registration time and call this when the owning entity is destroyed.
do  -- lurek.devtools.removeWatch
  local fps_value = 60
  local id = lurek.devtools.exposeWatch("fps", function() return fps_value end)
  local removed = lurek.devtools.removeWatch(id)
  lurek.devtools.debug("removed watch " .. id .. " -> " .. tostring(removed))
end

--@api-stub: lurek.devtools.getWatches
-- Calls all registered watch getters and returns a table of {name, category, value} records.
-- Iterate to feed an in-game inspector; getter errors come back stringified rather than throwing.
do  -- lurek.devtools.getWatches
  local score = 1500
  lurek.devtools.exposeWatch("score", function() return score end, "hud")
  for _, w in ipairs(lurek.devtools.getWatches()) do
    lurek.devtools.info(w.category .. "/" .. w.name .. " = " .. tostring(w.value))
  end
end

--@api-stub: lurek.devtools.snapshot
-- Takes a structured snapshot of all watches + frame stats + last profile frame.
-- Serialise the returned table (lurek.serial.encode_json) and post to the VS Code extension or save to disk.
do  -- lurek.devtools.snapshot
  lurek.devtools.recordFrameTime(0.016)
  local snap = lurek.devtools.snapshot()
  lurek.devtools.info("snapshot: fps=" .. snap.frameStats.fps .. " watches=" .. snap.watchCount)
end

--@api-stub: lurek.devtools.profilerReport
-- Returns a flat summary table of all recorded profiler zones across all stored.
-- Each row has name/calls/total_ms/avg_ms/min_ms/max_ms/self_ms — ideal for CSV export or sorting by hottest zone.
do  -- lurek.devtools.profilerReport
  lurek.devtools.profilePush("sim")
  lurek.devtools.profilePop()
  lurek.devtools.profileFrame()
  for _, row in ipairs(lurek.devtools.profilerReport()) do
    lurek.devtools.info(row.name .. " avg=" .. row.avg_ms .. "ms over " .. row.calls .. " calls")
  end
end

--@api-stub: lurek.devtools.newFileWatcher
-- Creates a standalone per-path file watcher.
-- Use when one subsystem (e.g. shader pipeline) needs its own change callback rather than sharing the global watch list.
do  -- lurek.devtools.newFileWatcher
  local fw = lurek.devtools.newFileWatcher("content/examples/devtools.lua")
  fw:onChanged(function() lurek.devtools.info("devtools.lua changed; reloading") end)
  function lurek.process(dt) fw:check() end
end

--@api-stub: lurek.devtools.newRepl
-- Creates an interactive Lua REPL console with a bounded history buffer.
-- The optional argument bounds history; once full, oldest inputs are dropped to make room for new ones.
do  -- lurek.devtools.newRepl
  local repl = lurek.devtools.newRepl(100)
  local result = repl:eval("return math.pi * 2")
  lurek.devtools.info("repl said: " .. result)
end

-- ── FileWatcher methods ──

--@api-stub: FileWatcher:onChanged
-- Registers a callback invoked (with no arguments) when the watched path changes.
-- Calling onChanged again replaces the previous callback; pass nothing-arg closures that capture state via upvalues.
do  -- FileWatcher:onChanged
  local fw = lurek.devtools.newFileWatcher("conf.toml")
  local reloads = 0
  fw:onChanged(function() reloads = reloads + 1; lurek.devtools.info("reload #" .. reloads) end)
end

--@api-stub: FileWatcher:check
-- Polls the watcher.
-- Returns true when the file changed (and fires onChanged); call once per frame from lurek.process for live reload.
do  -- FileWatcher:check
  local fw = lurek.devtools.newFileWatcher("content/examples/devtools.lua")
  function lurek.process(dt)
    if fw:check() then lurek.devtools.info("devtools.lua reloaded") end
  end
end

--@api-stub: FileWatcher:getPath
-- Returns the watched path string.
-- Useful when one log handler manages many watchers and needs to label which file fired the change.
do  -- FileWatcher:getPath
  local fw = lurek.devtools.newFileWatcher("content/levels/forest_01.toml")
  fw:onChanged(function() lurek.devtools.info("changed: " .. fw:getPath()) end)
end

--@api-stub: FileWatcher:cancel
-- Removes the stored `onChanged` callback and stops future notifications.
-- Call when the consuming subsystem shuts down so the captured upvalues can be garbage collected.
do  -- FileWatcher:cancel
  local fw = lurek.devtools.newFileWatcher("conf.toml")
  fw:onChanged(function() end)
  fw:cancel()
  lurek.devtools.debug("watcher cancelled for " .. fw:getPath())
end

-- ── ReplConsole methods ──

--@api-stub: ReplConsole:eval
-- Evaluates a Lua snippet and records the input in history.
-- Expressions return their value as a string; statements return "(ok)"; errors return the error text — always safe to display.
do  -- ReplConsole:eval
  local repl = lurek.devtools.newRepl(50)
  local out = repl:eval("return string.upper('hello')")
  lurek.devtools.info("> " .. out)
end

--@api-stub: ReplConsole:history
-- Returns an ordered array of past inputs (oldest first).
-- Drive an Up/Down arrow recall in your console UI; iterate in reverse for most-recent-first display.
do  -- ReplConsole:history
  local repl = lurek.devtools.newRepl(20)
  repl:eval("x = 1")
  repl:eval("return x + 1")
  for i, line in ipairs(repl:history()) do
    lurek.devtools.debug(i .. ": " .. line)
  end
end

--@api-stub: ReplConsole:clear
-- Clears the REPL history buffer.
-- Wire to a `:clear` command or a button in the console UI; the live Lua VM state is untouched.
do  -- ReplConsole:clear
  local repl = lurek.devtools.newRepl(10)
  repl:eval("return 1")
  repl:clear()
  lurek.devtools.debug("history len after clear = " .. repl:len())
end

--@api-stub: ReplConsole:len
-- Returns the number of history entries.
-- Use to render "N/Max" status in the REPL UI or to decide when to auto-trim before saving a session log.
do  -- ReplConsole:len
  local repl = lurek.devtools.newRepl(100)
  repl:eval("print('hi')")
  if repl:len() > 0 then
    lurek.devtools.info("REPL has " .. repl:len() .. " stored line(s)")
  end
end

