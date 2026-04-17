-- content/examples/devtools.lua
-- Lurek2D lurek.devtools API Reference
-- Run with: cargo run -- content/examples/devtools
--
-- Scenario: A game development session — logging, profiling frame times,
-- hot-reloading assets via file watchers, live variable watches, and an
-- interactive REPL console for runtime debugging.

print("=== lurek.devtools — Development Tools ===\n")

-- =============================================================================
-- Logging — structured log output to console and file
-- =============================================================================

-- ---- Stub: lurek.devtools.setLogLevel ------------------------------------
--@api-stub: lurek.devtools.setLogLevel
-- Set minimum log level to "debug" during development — shows all messages.
-- Levels: "debug" < "info" < "warn" < "error"
lurek.devtools.setLogLevel("debug")
print("log level set to: debug")

-- ---- Stub: lurek.devtools.getLogLevel ------------------------------------
--@api-stub: lurek.devtools.getLogLevel
-- Confirm the active log level for the settings panel.
local level = lurek.devtools.getLogLevel()
print("current log level: " .. tostring(level))

-- ---- Stub: lurek.devtools.setLogConsole ----------------------------------
--@api-stub: lurek.devtools.setLogConsole
-- Enable console output so log messages appear in the terminal during dev.
lurek.devtools.setLogConsole(true)
print("console logging enabled")

-- ---- Stub: lurek.devtools.getLogConsole ----------------------------------
--@api-stub: lurek.devtools.getLogConsole
-- Verify console output is active.
local console_on = lurek.devtools.getLogConsole()
print("console logging: " .. tostring(console_on))

-- ---- Stub: lurek.devtools.setLogFile -------------------------------------
--@api-stub: lurek.devtools.setLogFile
-- Also write logs to a file for post-session analysis.
lurek.devtools.setLogFile("logs/game_debug.log")
print("log file set to: logs/game_debug.log")

-- ---- Stub: lurek.devtools.getLogFile -------------------------------------
--@api-stub: lurek.devtools.getLogFile
-- Read back the configured log file path.
local log_path = lurek.devtools.getLogFile()
print("log file path: " .. tostring(log_path))

-- ---- Stub: lurek.devtools.log --------------------------------------------
--@api-stub: lurek.devtools.log
-- Log messages at different severity levels during gameplay.
lurek.devtools.log("info", "Game started — loading level 1")
lurek.devtools.log("debug", "Player spawn at (100, 200)")
lurek.devtools.log("warn", "Texture 'enemy_boss.png' not found — using fallback")
lurek.devtools.log("error", "Physics body leaked — entity destroyed without cleanup")
print("4 log messages written at different levels")

-- ---- Stub: lurek.devtools.getLogHistory ----------------------------------
--@api-stub: lurek.devtools.getLogHistory
-- Retrieve the last 10 log entries for an in-game debug overlay.
local history = lurek.devtools.getLogHistory(10)
if history then
    print("recent log entries: " .. #history)
    for i, entry in ipairs(history) do
        print("  [" .. i .. "] " .. tostring(entry.level or "") .. ": " .. tostring(entry.message or entry))
    end
end

-- ---- Stub: lurek.devtools.clearLog ---------------------------------------
--@api-stub: lurek.devtools.clearLog
-- Clear the log buffer when starting a new test run.
lurek.devtools.clearLog()
print("log buffer cleared")

-- =============================================================================
-- Profiling — measure frame zones and identify hot paths
-- =============================================================================

-- ---- Stub: lurek.devtools.setProfilingEnabled ----------------------------
--@api-stub: lurek.devtools.setProfilingEnabled
-- Enable the profiler to start collecting zone data.
lurek.devtools.setProfilingEnabled(true)
print("profiling enabled")

-- ---- Stub: lurek.devtools.isProfilingEnabled -----------------------------
--@api-stub: lurek.devtools.isProfilingEnabled
-- Show a "PROFILING" indicator in the debug HUD when active.
local profiling = lurek.devtools.isProfilingEnabled()
print("profiling active: " .. tostring(profiling))

-- ---- Stub: lurek.devtools.profilePush ------------------------------------
--@api-stub: lurek.devtools.profilePush
-- Open named profiling zones to measure specific systems.
-- Zones nest: "update" contains "physics" and "ai" sub-zones.
lurek.devtools.profilePush("update")
  lurek.devtools.profilePush("physics")
  -- ... physics simulation work happens here ...

-- ---- Stub: lurek.devtools.profilePop -------------------------------------
--@api-stub: lurek.devtools.profilePop
-- Close profiling zones in reverse order (LIFO).
  lurek.devtools.profilePop()  -- closes "physics"
  lurek.devtools.profilePush("ai")
  -- ... AI tick work happens here ...
  lurek.devtools.profilePop()  -- closes "ai"
lurek.devtools.profilePop()    -- closes "update"
print("profiling zones: update > physics, update > ai")

-- ---- Stub: lurek.devtools.profileFrame -----------------------------------
--@api-stub: lurek.devtools.profileFrame
-- Seal the current frame's profiling data. Call once at the end of each frame.
lurek.devtools.profileFrame()
print("profile frame sealed")

-- ---- Stub: lurek.devtools.getProfileFrameCount ---------------------------
--@api-stub: lurek.devtools.getProfileFrameCount
-- Show how many frames of profiling data are retained.
local frame_count = lurek.devtools.getProfileFrameCount()
print("retained profile frames: " .. tostring(frame_count))

-- ---- Stub: lurek.devtools.getProfileData ---------------------------------
--@api-stub: lurek.devtools.getProfileData
-- Get zone data for the most recent frame (nil = latest).
local profile = lurek.devtools.getProfileData(nil)
if profile then
    print("profile zones in latest frame:")
    for _, zone in ipairs(profile) do
        print("  " .. tostring(zone.name or "?") .. ": " .. tostring(zone.duration_ms or zone.time or "?") .. "ms")
    end
else
    print("no profile data yet")
end

-- ---- Stub: lurek.devtools.profilerReport ---------------------------------
--@api-stub: lurek.devtools.profilerReport
-- Generate a flat summary of all zones across all stored frames.
-- Useful for finding the most expensive systems over multiple frames.
local report = lurek.devtools.profilerReport()
if report then
    print("profiler report (" .. #report .. " zones):")
    for _, z in ipairs(report) do
        print("  " .. tostring(z.name or "?")
            .. " — avg: " .. tostring(z.avg_ms or "?") .. "ms"
            .. ", max: " .. tostring(z.max_ms or "?") .. "ms"
            .. ", calls: " .. tostring(z.calls or "?"))
    end
end

-- ---- Stub: lurek.devtools.resetProfile -----------------------------------
--@api-stub: lurek.devtools.resetProfile
-- Clear all profiling data before a new benchmark run.
lurek.devtools.resetProfile()
print("profiler reset — all zone data cleared")

-- =============================================================================
-- Frame Time Tracking — FPS counter and timing statistics
-- =============================================================================

-- ---- Stub: lurek.devtools.setFrameHistorySize ----------------------------
--@api-stub: lurek.devtools.setFrameHistorySize
-- Keep 300 frames of history (5 seconds at 60 FPS) for the FPS graph.
lurek.devtools.setFrameHistorySize(300)
print("frame history buffer: 300 samples")

-- ---- Stub: lurek.devtools.getFrameHistorySize ----------------------------
--@api-stub: lurek.devtools.getFrameHistorySize
-- Confirm the buffer size.
local hist_size = lurek.devtools.getFrameHistorySize()
print("frame history size: " .. tostring(hist_size))

-- ---- Stub: lurek.devtools.recordFrameTime --------------------------------
--@api-stub: lurek.devtools.recordFrameTime
-- Record simulated frame times for different load scenarios.
local simulated_dts = {0.0166, 0.0167, 0.0165, 0.0200, 0.0333, 0.0166, 0.0168}
for _, dt in ipairs(simulated_dts) do
    lurek.devtools.recordFrameTime(dt)
end
print(#simulated_dts .. " frame time samples recorded")

-- ---- Stub: lurek.devtools.getFrameStats ----------------------------------
--@api-stub: lurek.devtools.getFrameStats
-- Display computed stats in the FPS overlay: avg, min, max, p99.
local stats = lurek.devtools.getFrameStats()
if stats then
    print("frame stats:")
    print("  avg:  " .. tostring(stats.avg_ms or stats.avg or "?") .. "ms")
    print("  min:  " .. tostring(stats.min_ms or stats.min or "?") .. "ms")
    print("  max:  " .. tostring(stats.max_ms or stats.max or "?") .. "ms")
    print("  fps:  " .. tostring(stats.fps or "?"))
end

-- ---- Stub: lurek.devtools.getFrameHistory --------------------------------
--@api-stub: lurek.devtools.getFrameHistory
-- Get the raw sample array for drawing an FPS graph in the debug overlay.
local frame_hist = lurek.devtools.getFrameHistory()
if frame_hist then
    print("frame history: " .. #frame_hist .. " samples")
end

-- =============================================================================
-- File Watching — hot-reload assets and scripts during development
-- =============================================================================

-- ---- Stub: lurek.devtools.watch ------------------------------------------
--@api-stub: lurek.devtools.watch
-- Watch the player sprite sheet for live editing — re-upload texture on change.
local added = lurek.devtools.watch("assets/sprites/player.png")
print("watch 'assets/sprites/player.png': " .. tostring(added))

-- Also watch the main game script for hot-reload.
lurek.devtools.watch("main.lua")
lurek.devtools.watch("assets/levels/level1.json")
print("3 paths watched for changes")

-- ---- Stub: lurek.devtools.getWatchedPaths --------------------------------
--@api-stub: lurek.devtools.getWatchedPaths
-- List all watched paths in the dev tools panel.
local watched = lurek.devtools.getWatchedPaths()
if watched then
    print("watched paths (" .. #watched .. "):")
    for _, p in ipairs(watched) do print("  " .. p) end
end

-- ---- Stub: lurek.devtools.getWatchInterval -------------------------------
--@api-stub: lurek.devtools.getWatchInterval
-- Check the current poll interval.
local interval = lurek.devtools.getWatchInterval()
print("watch poll interval: " .. tostring(interval) .. "s")

-- ---- Stub: lurek.devtools.setWatchInterval -------------------------------
--@api-stub: lurek.devtools.setWatchInterval
-- Poll every 0.5 seconds instead of the default — faster hot-reload feedback.
lurek.devtools.setWatchInterval(0.5)
print("watch interval set to 0.5s")

-- ---- Stub: lurek.devtools.scan -------------------------------------------
--@api-stub: lurek.devtools.scan
-- Poll all watched paths and get a list of files that changed since last scan.
-- Call this once per frame in lurek.process() to detect hot-reload triggers.
local changed = lurek.devtools.scan()
if changed and #changed > 0 then
    print("changed files:")
    for _, path in ipairs(changed) do
        print("  " .. path .. " — triggering reload")
    end
else
    print("no files changed since last scan")
end

-- ---- Stub: lurek.devtools.unwatch ----------------------------------------
--@api-stub: lurek.devtools.unwatch
-- Stop watching the level file after it's fully loaded.
local removed = lurek.devtools.unwatch("assets/levels/level1.json")
print("unwatched level1.json: " .. tostring(removed))

-- ---- Stub: lurek.devtools.clearWatches -----------------------------------
--@api-stub: lurek.devtools.clearWatches
-- Clear all watches when entering release mode (no hot-reload in production).
lurek.devtools.clearWatches()
print("all file watches cleared")

-- =============================================================================
-- Standalone FileWatcher — per-asset watcher with callback
-- =============================================================================

-- ---- Stub: lurek.devtools.newFileWatcher ---------------------------------
--@api-stub: lurek.devtools.newFileWatcher
-- Create a dedicated watcher for the tilemap file — fires a callback on change.
local tilemap_watcher = lurek.devtools.newFileWatcher("assets/maps/dungeon.tmx")
print("FileWatcher created for: assets/maps/dungeon.tmx")

-- ---- Stub: FileWatcher:getPath -------------------------------------------
--@api-stub: FileWatcher:getPath
-- Confirm which file this watcher is monitoring.
local wp = tilemap_watcher:getPath()
print("watcher path: " .. tostring(wp))

-- ---- Stub: FileWatcher:onChanged -----------------------------------------
--@api-stub: FileWatcher:onChanged
-- Register a callback that fires when the tilemap file is modified.
tilemap_watcher:onChanged(function()
    print("  [watcher] dungeon.tmx changed — reloading tilemap!")
end)
print("onChanged callback registered for tilemap watcher")

-- ---- Stub: FileWatcher:check ---------------------------------------------
--@api-stub: FileWatcher:check
-- Poll the watcher each frame. Returns true if the file changed and the callback fired.
local did_change = tilemap_watcher:check()
print("tilemap watcher check: changed=" .. tostring(did_change))

-- ---- Stub: FileWatcher:cancel --------------------------------------------
--@api-stub: FileWatcher:cancel
-- Stop watching when the level is unloaded — removes the callback.
tilemap_watcher:cancel()
print("tilemap watcher cancelled")

-- =============================================================================
-- Live Watches — expose game variables for the debug inspector
-- =============================================================================

local player_hp = 85
local player_x, player_y = 100, 200
local enemy_count = 7

-- ---- Stub: lurek.devtools.exposeWatch ------------------------------------
--@api-stub: lurek.devtools.exposeWatch
-- Register live watches that sample game state on demand.
-- The getter function is called each time the debug panel refreshes.
local watch_hp = lurek.devtools.exposeWatch("player_hp", function()
    return player_hp
end, "player")
print("watch registered: player_hp (id=" .. tostring(watch_hp) .. ")")

local watch_pos = lurek.devtools.exposeWatch("player_pos", function()
    return player_x .. ", " .. player_y
end, "player")
print("watch registered: player_pos (id=" .. tostring(watch_pos) .. ")")

local watch_enemies = lurek.devtools.exposeWatch("enemy_count", function()
    return enemy_count
end, "world")
print("watch registered: enemy_count (id=" .. tostring(watch_enemies) .. ")")

-- ---- Stub: lurek.devtools.getWatches -------------------------------------
--@api-stub: lurek.devtools.getWatches
-- Sample all watches — the debug panel calls this each refresh.
local watches = lurek.devtools.getWatches()
if watches then
    print("live watches (" .. #watches .. "):")
    for _, w in ipairs(watches) do
        print("  [" .. tostring(w.category or "?") .. "] "
            .. tostring(w.name or "?") .. " = " .. tostring(w.value or "?"))
    end
end

-- ---- Stub: lurek.devtools.removeWatch ------------------------------------
--@api-stub: lurek.devtools.removeWatch
-- Remove the enemy count watch after all enemies are defeated.
local removed_w = lurek.devtools.removeWatch(watch_enemies)
print("enemy_count watch removed: " .. tostring(removed_w))

-- =============================================================================
-- Snapshot and Console — capture state, evaluate expressions
-- =============================================================================

-- ---- Stub: lurek.devtools.snapshot ---------------------------------------
--@api-stub: lurek.devtools.snapshot
-- Take a full debug snapshot — combines watches, frame stats, and profile data
-- into one table for serialization or remote debugging.
local snap = lurek.devtools.snapshot()
if snap then
    print("debug snapshot captured:")
    for k, _ in pairs(snap) do print("  section: " .. k) end
end

-- ---- Stub: lurek.devtools.getCallStack -----------------------------------
--@api-stub: lurek.devtools.getCallStack
-- Capture the current Lua call stack for error reporting.
-- Max depth of 10 frames keeps the output manageable.
local stack = lurek.devtools.getCallStack(10)
if stack then
    print("call stack (" .. #stack .. " frames):")
    for i, frame in ipairs(stack) do
        print("  " .. i .. ": " .. tostring(frame.source or "?")
            .. ":" .. tostring(frame.line or "?")
            .. " " .. tostring(frame.name or "<anonymous>"))
    end
end

-- ---- Stub: lurek.devtools.eval -------------------------------------------
--@api-stub: lurek.devtools.eval
-- Evaluate a Lua expression at runtime — useful for the debug console.
local ok, result = lurek.devtools.eval("return 2 + 2")
print("eval '2 + 2': ok=" .. tostring(ok) .. " result=" .. tostring(result))

-- ---- Stub: lurek.devtools.openConsole ------------------------------------
--@api-stub: lurek.devtools.openConsole
-- Open the interactive console overlay for live debugging.
local opened = lurek.devtools.openConsole()
print("console opened: " .. tostring(opened))

-- ---- Stub: lurek.devtools.isConsoleOpen ----------------------------------
--@api-stub: lurek.devtools.isConsoleOpen
-- Check if the console is showing — pause game input while it's open.
local console_open = lurek.devtools.isConsoleOpen()
print("console open: " .. tostring(console_open))

-- =============================================================================
-- REPL Console — interactive Lua shell with history
-- =============================================================================

-- ---- Stub: lurek.devtools.newRepl ----------------------------------------
--@api-stub: lurek.devtools.newRepl
-- Create a REPL console with 100-entry history buffer for the debug overlay.
local repl = lurek.devtools.newRepl(100)
print("REPL console created with 100-entry history")

-- ---- Stub: ReplConsole:eval ----------------------------------------------
--@api-stub: ReplConsole:eval
-- Evaluate expressions through the REPL — results are returned as strings.
local r1 = repl:eval("return 'Hello from REPL'")
print("repl eval: " .. tostring(r1))

local r2 = repl:eval("return math.sqrt(144)")
print("repl eval: " .. tostring(r2))

local r3 = repl:eval("return type(lurek)")
print("repl eval: " .. tostring(r3))

-- ---- Stub: ReplConsole:history -------------------------------------------
--@api-stub: ReplConsole:history
-- Retrieve REPL input history for arrow-key recall.
local repl_hist = repl:history()
if repl_hist then
    print("REPL history (" .. #repl_hist .. " entries):")
    for i, cmd in ipairs(repl_hist) do
        print("  [" .. i .. "] " .. cmd)
    end
end

-- ---- Stub: ReplConsole:len -----------------------------------------------
--@api-stub: ReplConsole:len
-- Query the number of entries currently stored in the REPL history.
local hist_count = repl:len()
print("REPL history length: " .. tostring(hist_count))

-- ---- Stub: ReplConsole:clear ---------------------------------------------
--@api-stub: ReplConsole:clear
-- Wipe the REPL history buffer to free memory or reset the debug session.
repl:clear()
local after_clear = repl:len()
print("REPL history after clear: " .. tostring(after_clear))

print("\n-- devtools.lua example complete --")
