-- examples/devtools.lua
-- Demonstrates luna.devtools — runtime diagnostics toolkit for Luna2D.
-- Requires modules.debug = true (default) in conf.lua.
-- Run with: cargo run -- examples/devtools
--
-- luna.devtools provides four facilities:
--   Logger      — in-memory structured log history with level filtering
--   Profiler    — hierarchical CPU-zone profiler across frames
--   FrameStats  — rolling frame-time buffer with p50/p95/p99 percentiles
--   FileWatcher — polling mtime watcher for hot-reload detection

-- ─────────────────────────────────────────────────────────────────────────────
-- LOGGER
-- Structured in-game log buffer.  NOT the same as luna.log (which routes to
-- stdout via RUST_LOG). This logger stores entries in-memory for in-game UI.
-- ─────────────────────────────────────────────────────────────────────────────

-- Emit at specific severity levels
luna.devtools.trace("very fine-grained diagnostic detail")
luna.devtools.debug("player position: x=100, y=200")
luna.devtools.info("world loaded: 256 tiles, 8 enemies")
luna.devtools.warn("asset file not found: hero_jump.png — using fallback")
luna.devtools.error("save slot 2 is corrupted")
luna.devtools.fatal("out of memory — aborting level load")

-- Emit at a runtime-chosen level (same as the level-shorthand functions above)
luna.devtools.log("debug", "velocity updated to 3.14 m/s")

-- Control minimum log level — entries below this level are silently dropped
luna.devtools.setLogLevel("info")    -- "trace"|"debug"|"info"|"warn"|"error"|"fatal"
local lv = luna.devtools.getLogLevel()   -- returns "info"

-- Route log output to the OS console (stdout) as well as the in-memory buffer
luna.devtools.setLogConsole(true)
local has_console = luna.devtools.getLogConsole()   -- true

-- Write log output to a file in addition to the buffer (empty string = disabled)
luna.devtools.setLogFile("save/dev.log")
local log_file = luna.devtools.getLogFile()   -- "save/dev.log"

-- Retrieve recent log entries for an in-game console or HUD display
-- Returns an array of {level, timestamp, message, source, line, category?}
local all_entries = luna.devtools.getLogHistory()        -- last N entries (all)
local last_10 = luna.devtools.getLogHistory(10)          -- last 10 entries

for _, entry in ipairs(last_10) do
    -- entry.level     — "info", "warn", etc.
    -- entry.timestamp — Unix time (seconds)
    -- entry.message   — the log string
    -- entry.source    — file name (may be "?" for Lua)
    -- entry.line      — source line number
end

-- Clear the entire in-memory log buffer
luna.devtools.clearLog()

-- ─────────────────────────────────────────────────────────────────────────────
-- PROFILER
-- Hierarchical zone profiler.  Push a zone, do work, pop it.
-- At end-of-frame call profileFrame() to seal the current frame's data.
-- ─────────────────────────────────────────────────────────────────────────────

-- Enable profiling (disabled by default to avoid overhead in release builds)
luna.devtools.setProfilingEnabled(true)
local profiling = luna.devtools.isProfilingEnabled()   -- true

-- Simulate a profiled frame (in a real game this lives inside luna.process / luna.render)
luna.devtools.profilePush("update")          -- open zone "update"

luna.devtools.profilePush("physics")        -- nested child zone
    -- ... physics update work ...
luna.devtools.profilePop()                  -- close "physics"

luna.devtools.profilePush("ai")             -- sibling zone
    -- ... AI update work ...
luna.devtools.profilePop()                  -- close "ai"

luna.devtools.profilePop()                  -- close "update"

-- Seal the frame — moves current zone tree into the rolling frame history
luna.devtools.profileFrame()

-- Query how many sealed frames are retained
local frame_count = luna.devtools.getProfileFrameCount()

-- Read zone data from the most-recently sealed frame (nil or 0 = most recent)
local zones = luna.devtools.getProfileData()   -- returns array of zone tables

for _, zone in ipairs(zones) do
    -- zone.name      — string name
    -- zone.time      — total wall-clock seconds (includes children)
    -- zone.selfTime  — seconds excluding child zones
    -- zone.startTime — absolute start timestamp
    -- zone.children  — nested array of child zones (same structure)
    print(string.format("%-20s total=%.3fms self=%.3fms",
        zone.name, zone.time * 1000, zone.selfTime * 1000))
end

-- Read a specific historical frame — frame 1 is the oldest in the ring
local older = luna.devtools.getProfileData(1)

-- Clear all profiler data and reset the zone stack
luna.devtools.resetProfile()

-- ─────────────────────────────────────────────────────────────────────────────
-- FRAME STATISTICS
-- Rolling buffer of per-frame delta times.  Records raw samples and computes
-- FPS, min, max, average, and percentile statistics.
-- NOTE: For simple FPS/delta use luna.time.getFPS() / luna.time.getDelta().
-- Use devtools.getFrameStats() when you need p50/p95/p99 analysis.
-- ─────────────────────────────────────────────────────────────────────────────

-- Configure the rolling history capacity (samples kept, clamped 10-10000)
luna.devtools.setFrameHistorySize(120)  -- keep 120 frames ≈ 2 seconds at 60 fps
local cap = luna.devtools.getFrameHistorySize()   -- 120

-- Record a frame-time sample (call once per frame with the current delta time)
-- In a real game: luna.devtools.recordFrameTime(dt) inside luna.process(dt)
luna.devtools.recordFrameTime(1 / 60)   -- simulate a 60 fps frame
luna.devtools.recordFrameTime(1 / 58)   -- simulate a slightly slower frame
luna.devtools.recordFrameTime(1 / 30)   -- simulate a 30 fps spike

-- Compute a full statistics snapshot from all buffered samples
local stats = luna.devtools.getFrameStats()
-- stats.fps     — current estimated FPS (1 / last sample)
-- stats.dt      — last recorded delta time in seconds
-- stats.avg     — mean frame time across all samples
-- stats.min     — shortest frame in the buffer
-- stats.max     — longest frame (worst spike) in the buffer
-- stats.p50     — median frame time (50th percentile)
-- stats.p95     — 95th percentile (most frames are faster than this)
-- stats.p99     — 99th percentile (worst 1% of frames)
-- stats.samples — number of samples in the current buffer

print(string.format("FPS: %.1f  avg: %.2fms  p95: %.2fms  p99: %.2fms",
    stats.fps, stats.avg * 1000, stats.p95 * 1000, stats.p99 * 1000))

-- Access the raw sample array for custom plotting (e.g. a frame-time graph)
local history = luna.devtools.getFrameHistory()  -- {dt1, dt2, dt3, ...}
for i, sample in ipairs(history) do
    -- sample is a number in seconds — multiply by 1000 for ms
    _ = i   -- suppress unused warning
end

-- ─────────────────────────────────────────────────────────────────────────────
-- FILE WATCHER
-- Polls modification timestamps to detect changed files for hot-reload.
-- There is NO background thread — polling only happens when scan() is called.
-- ─────────────────────────────────────────────────────────────────────────────

-- Set the logical poll interval (caller decides when to call scan())
luna.devtools.setWatchInterval(0.5)           -- 500 ms between polls
local interval = luna.devtools.getWatchInterval()  -- 0.5

-- Register paths to watch (returns false if the path is already watched)
local added1 = luna.devtools.watch("assets/shaders/sprite.wgsl")
local added2 = luna.devtools.watch("assets/maps/level1.json")
local added3 = luna.devtools.watch("conf.lua")

-- Query all currently watched paths
local watched = luna.devtools.getWatchedPaths()   -- {"assets/shaders/sprite.wgsl", ...}

-- Poll for changes — returns paths whose mtime changed since last scan()
-- In a real game call this from luna.process(dt) after accumulating watch_interval
local changed = luna.devtools.scan()
for _, path in ipairs(changed) do
    print("file changed, hot-reload: " .. path)
end

-- Remove a specific path from the watch list
local removed = luna.devtools.unwatch("assets/maps/level1.json")  -- true

-- Remove all watches at once
luna.devtools.clearWatches()

-- ─────────────────────────────────────────────────────────────────────────────
-- LUA DEBUG BRIDGE
-- Quick introspection helpers that do NOT require luna.debugbridge.
-- ─────────────────────────────────────────────────────────────────────────────

-- Walk the current Lua call stack (wraps debug.getinfo)
-- Returns an array of {source, line, name, what} frames
local stack = luna.devtools.getCallStack()      -- default max 20 levels
local deep  = luna.devtools.getCallStack(50)    -- up to 50 levels

for _, frame in ipairs(stack) do
    -- frame.source — short source path, e.g. "examples/devtools"
    -- frame.line   — current line number in that source
    -- frame.name   — function name or "?"
    -- frame.what   — "Lua", "C", "main", etc.
end

-- Evaluate an arbitrary Lua string — returns (success, results...)
local ok, value = luna.devtools.eval("return 2 + 2")
if ok then
    print("eval: 2+2 = " .. tostring(value))   -- "4"
end

local fail, err = luna.devtools.eval("return nil + 1")   -- type error
if not fail then
    luna.log.warn("eval error: " .. tostring(err))
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CONSOLE STATE
-- Tracks whether an in-game developer console is open (logical flag only —
-- luna.devtools does not render anything; rendering is your responsibility).
-- ─────────────────────────────────────────────────────────────────────────────

luna.devtools.openConsole()
local is_open = luna.devtools.isConsoleOpen()   -- true

-- Typical pattern: toggle console on a key press, render only when open
-- if luna.devtools.isConsoleOpen() then
--     render_console_overlay()
-- end

-- ─────────────────────────────────────────────────────────────────────────────
-- HOT-RELOAD PATTERN — putting it all together
-- ─────────────────────────────────────────────────────────────────────────────

local watch_timer = 0.0
local watcher_enabled = true

if watcher_enabled then
    luna.devtools.watch("main.lua")
    luna.devtools.watch("assets/tileset.png")
    luna.devtools.setWatchInterval(0.5)
end

-- In your luna.process(dt) you would do:
--   watch_timer = watch_timer + dt
--   if watch_timer >= luna.devtools.getWatchInterval() then
--       watch_timer = 0
--       for _, path in ipairs(luna.devtools.scan()) do
--           luna.log.info("hot-reload: " .. path)
--           -- reload logic here
--   end

luna.log.info("[devtools.lua] example complete")

-- ─────────────────────────────────────────────────────────────────────────────
-- LIVE WATCHES — exposeWatch / getWatches
-- Named getter functions that can be sampled on demand.
-- Ideal for a VS Code live-data panel, an in-game debug overlay, or a
-- devtools JSON wire format to an external tool.
-- ─────────────────────────────────────────────────────────────────────────────

-- A simulated game state.
local player = { hp = 100, mp = 42, x = 128, y = 64 }
local wave   = 3

-- Register watches.  Each returns an integer id.
local id_hp = luna.devtools.exposeWatch("player.hp",    function() return player.hp end, "Player")
local id_mp = luna.devtools.exposeWatch("player.mp",    function() return player.mp end, "Player")
local id_x  = luna.devtools.exposeWatch("player.x",    function() return player.x  end, "Position")
local id_y  = luna.devtools.exposeWatch("player.y",    function() return player.y  end, "Position")
local id_wv = luna.devtools.exposeWatch("wave",         function() return wave      end, "Game")

-- Mutate game state and observe the change.
player.hp = 75
wave = 4

-- getWatches() samples all registered getters instantly.
-- Returns an array of { name, category, value } tables.
local watches = luna.devtools.getWatches()
for _, w in ipairs(watches) do
    luna.log.info(string.format("  watch: [%s] %s = %s",
        w.category, w.name, tostring(w.value)))
end

-- Remove a watch by id.
luna.devtools.removeWatch(id_mp)

-- ─────────────────────────────────────────────────────────────────────────────
-- SNAPSHOT — luna.devtools.snapshot()
-- Takes a structured snapshot of ALL diagnostics at a single point in time:
-- watches, frameStats, profile frame, and recent log tail.
-- Great for saving a crash report, sending to VS Code, or logging before quit.
-- ─────────────────────────────────────────────────────────────────────────────

local snap = luna.devtools.snapshot()

-- snap.watches       — { {name, category, value}, ... }
-- snap.frameStats    — { fps, dt, avg, p95, p99 }
-- snap.profile       — last profiler frame zones (may be empty until a frame runs)
-- snap.log           — last 10 log entries { level, message, source }
-- snap.watchCount    — integer

luna.log.info(string.format("snapshot: %d watches, fps=%.1f, logLines=%d",
    snap.watchCount,
    snap.frameStats.fps or 0,
    #snap.log))

-- Snapshot is a plain table — trivial to serialize.
-- local json = luna.data.encode("json", snap)
-- luna.filesystem.write("save/crash_report.json", json)

-- ─────────────────────────────────────────────────────────────────────────────
-- VS CODE / EXTENSION INTEGRATION HINTS
-- The devtools API is intentionally compatible as a data source for the
-- Luna2D VS Code extension (vscode-extension/).
--
-- Pattern: pump snapshot data every second over luna.thread channels to a
-- background worker that serialises it, then a VS Code MCP endpoint reads it.
-- See vscode-extension/src/providers/ for the expected format.
-- ─────────────────────────────────────────────────────────────────────────────

luna.log.info("[devtools.lua] watch/snapshot example complete")
