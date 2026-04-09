-- examples/devtools.lua
-- Demonstrates lurek.devtools — runtime diagnostics toolkit for Lurek2D.
-- Requires modules.debug = true (default) in conf.lua.
-- Run with: cargo run -- examples/devtools
--
-- lurek.devtools provides four facilities:
Logger  -- in-memory structured log history with level filtering
Profiler  -- hierarchical CPU-zone profiler across frames
FrameStats  -- rolling frame-time buffer with p50/p95/p99 percentiles
FileWatcher  -- polling mtime watcher for hot-reload detection

-- ─────────────────────────────────────────────────────────────────────────────
-- LOGGER
-- Structured in-game log buffer.  NOT the same as lurek.log (which routes to
-- stdout via RUST_LOG). This logger stores entries in-memory for in-game UI.
-- ─────────────────────────────────────────────────────────────────────────────

-- Emit at specific severity levels
lurek.devtools.trace("very fine-grained diagnostic detail")
lurek.devtools.debug("player position: x=100, y=200")
lurek.devtools.info("world loaded: 256 tiles, 8 enemies")
lurek.devtools.warn("asset file not found: hero_jump.png — using fallback")
lurek.devtools.error("save slot 2 is corrupted")
lurek.devtools.fatal("out of memory — aborting level load")

-- Emit at a runtime-chosen level (same as the level-shorthand functions above)
lurek.devtools.log("debug", "velocity updated to 3.14 m/s")

-- Control minimum log level — entries below this level are silently dropped
lurek.devtools.setLogLevel("info")    -- "trace"|"debug"|"info"|"warn"|"error"|"fatal"
local lv = lurek.devtools.getLogLevel()   -- returns "info"

-- Route log output to the OS console (stdout) as well as the in-memory buffer
lurek.devtools.setLogConsole(true)
local has_console = lurek.devtools.getLogConsole()   -- true

-- Write log output to a file in addition to the buffer (empty string = disabled)
lurek.devtools.setLogFile("save/dev.log")
local log_file = lurek.devtools.getLogFile()   -- "save/dev.log"

-- Retrieve recent log entries for an in-game console or HUD display
-- Returns an array of {level, timestamp, message, source, line, category?}
local all_entries = lurek.devtools.getLogHistory()        -- last N entries (all)
local last_10 = lurek.devtools.getLogHistory(10)          -- last 10 entries

for _, entry in ipairs(last_10) do
    -- entry.level     — "info", "warn", etc.
    -- entry.timestamp — Unix time (seconds)
    -- entry.message   — the log string
    -- entry.source    — file name (may be "?" for Lua)
    -- entry.line      — source line number
end

-- Clear the entire in-memory log buffer
lurek.devtools.clearLog()

-- ─────────────────────────────────────────────────────────────────────────────
-- PROFILER
-- Hierarchical zone profiler.  Push a zone, do work, pop it.
-- At end-of-frame call profileFrame() to seal the current frame's data.
-- ─────────────────────────────────────────────────────────────────────────────

-- Enable profiling (disabled by default to avoid overhead in release builds)
lurek.devtools.setProfilingEnabled(true)
local profiling = lurek.devtools.isProfilingEnabled()   -- true

-- Simulate a profiled frame (in a real game this lives inside lurek.process / lurek.render)
lurek.devtools.profilePush("update")          -- open zone "update"

lurek.devtools.profilePush("physics")        -- nested child zone
    -- ... physics update work ...
lurek.devtools.profilePop()                  -- close "physics"

lurek.devtools.profilePush("ai")             -- sibling zone
    -- ... AI update work ...
lurek.devtools.profilePop()                  -- close "ai"

lurek.devtools.profilePop()                  -- close "update"

-- Seal the frame — moves current zone tree into the rolling frame history
lurek.devtools.profileFrame()

-- Query how many sealed frames are retained
local frame_count = lurek.devtools.getProfileFrameCount()

-- Read zone data from the most-recently sealed frame (nil or 0 = most recent)
local zones = lurek.devtools.getProfileData()   -- returns array of zone tables

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
local older = lurek.devtools.getProfileData(1)

-- Clear all profiler data and reset the zone stack
lurek.devtools.resetProfile()

-- ─────────────────────────────────────────────────────────────────────────────
-- FRAME STATISTICS
-- Rolling buffer of per-frame delta times.  Records raw samples and computes
-- FPS, min, max, average, and percentile statistics.
-- NOTE: For simple FPS/delta use lurek.time.getFPS() / lurek.time.getDelta().
-- Use devtools.getFrameStats() when you need p50/p95/p99 analysis.
-- ─────────────────────────────────────────────────────────────────────────────

-- Configure the rolling history capacity (samples kept, clamped 10-10000)
lurek.devtools.setFrameHistorySize(120)  -- keep 120 frames ≈ 2 seconds at 60 fps
local cap = lurek.devtools.getFrameHistorySize()   -- 120

-- Record a frame-time sample (call once per frame with the current delta time)
-- In a real game: lurek.devtools.recordFrameTime(dt) inside lurek.process(dt)
lurek.devtools.recordFrameTime(1 / 60)   -- simulate a 60 fps frame
lurek.devtools.recordFrameTime(1 / 58)   -- simulate a slightly slower frame
lurek.devtools.recordFrameTime(1 / 30)   -- simulate a 30 fps spike

-- Compute a full statistics snapshot from all buffered samples
local stats = lurek.devtools.getFrameStats()
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
local history = lurek.devtools.getFrameHistory()  -- {dt1, dt2, dt3, ...}
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
lurek.devtools.setWatchInterval(0.5)           -- 500 ms between polls
local interval = lurek.devtools.getWatchInterval()  -- 0.5

-- Register paths to watch (returns false if the path is already watched)
local added1 = lurek.devtools.watch("assets/shaders/sprite.wgsl")
local added2 = lurek.devtools.watch("assets/maps/level1.json")
local added3 = lurek.devtools.watch("conf.lua")

-- Query all currently watched paths
local watched = lurek.devtools.getWatchedPaths()   -- {"assets/shaders/sprite.wgsl", ...}

-- Poll for changes — returns paths whose mtime changed since last scan()
-- In a real game call this from lurek.process(dt) after accumulating watch_interval
local changed = lurek.devtools.scan()
for _, path in ipairs(changed) do
    print("file changed, hot-reload: " .. path)
end

-- Remove a specific path from the watch list
local removed = lurek.devtools.unwatch("assets/maps/level1.json")  -- true

-- Remove all watches at once
lurek.devtools.clearWatches()

-- ─────────────────────────────────────────────────────────────────────────────
-- LUA DEBUG BRIDGE
-- Quick introspection helpers that do NOT require lurek.debugbridge.
-- ─────────────────────────────────────────────────────────────────────────────

-- Walk the current Lua call stack (wraps debug.getinfo)
-- Returns an array of {source, line, name, what} frames
local stack = lurek.devtools.getCallStack()      -- default max 20 levels
local deep  = lurek.devtools.getCallStack(50)    -- up to 50 levels

for _, frame in ipairs(stack) do
    -- frame.source — short source path, e.g. "examples/devtools"
    -- frame.line   — current line number in that source
    -- frame.name   — function name or "?"
    -- frame.what   — "Lua", "C", "main", etc.
end

-- Evaluate an arbitrary Lua string — returns (success, results...)
local ok, value = lurek.devtools.eval("return 2 + 2")
if ok then
    print("eval: 2+2 = " .. tostring(value))   -- "4"
end

local fail, err = lurek.devtools.eval("return nil + 1")   -- type error
if not fail then
    lurek.log.warn("eval error: " .. tostring(err))
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CONSOLE STATE
-- Tracks whether an in-game developer console is open (logical flag only —
-- lurek.devtools does not render anything; rendering is your responsibility).
-- ─────────────────────────────────────────────────────────────────────────────

lurek.devtools.openConsole()
local is_open = lurek.devtools.isConsoleOpen()   -- true

-- Typical pattern: toggle console on a key press, render only when open
-- if lurek.devtools.isConsoleOpen() then
render_console_overlay()
-- end

-- ─────────────────────────────────────────────────────────────────────────────
-- HOT-RELOAD PATTERN — putting it all together
-- ─────────────────────────────────────────────────────────────────────────────

local watch_timer = 0.0
local watcher_enabled = true

if watcher_enabled then
    lurek.devtools.watch("main.lua")
    lurek.devtools.watch("assets/tileset.png")
    lurek.devtools.setWatchInterval(0.5)
end

-- In your lurek.process(dt) you would do:
watch_timer = watch_timer + dt
if watch_timer >= lurek.devtools.getWatchInterval() then
watch_timer = 0
for _, path in ipairs(lurek.devtools.scan()) do
lurek.log.info("hot-reload: " .. path)
-- reload logic here
end

lurek.log.info("[devtools.lua] example complete")

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
local id_hp = lurek.devtools.exposeWatch("player.hp",    function() return player.hp end, "Player")
local id_mp = lurek.devtools.exposeWatch("player.mp",    function() return player.mp end, "Player")
local id_x  = lurek.devtools.exposeWatch("player.x",    function() return player.x  end, "Position")
local id_y  = lurek.devtools.exposeWatch("player.y",    function() return player.y  end, "Position")
local id_wv = lurek.devtools.exposeWatch("wave",         function() return wave      end, "Game")

-- Mutate game state and observe the change.
player.hp = 75
wave = 4

-- getWatches() samples all registered getters instantly.
-- Returns an array of { name, category, value } tables.
local watches = lurek.devtools.getWatches()
for _, w in ipairs(watches) do
    lurek.log.info(string.format("  watch: [%s] %s = %s",
        w.category, w.name, tostring(w.value)))
end

-- Remove a watch by id.
lurek.devtools.removeWatch(id_mp)

-- ─────────────────────────────────────────────────────────────────────────────
-- SNAPSHOT — lurek.devtools.snapshot()
-- Takes a structured snapshot of ALL diagnostics at a single point in time:
-- watches, frameStats, profile frame, and recent log tail.
-- Great for saving a crash report, sending to VS Code, or logging before quit.
-- ─────────────────────────────────────────────────────────────────────────────

local snap = lurek.devtools.snapshot()

-- snap.watches       — { {name, category, value}, ... }
-- snap.frameStats    — { fps, dt, avg, p95, p99 }
-- snap.profile       — last profiler frame zones (may be empty until a frame runs)
-- snap.log           — last 10 log entries { level, message, source }
-- snap.watchCount    — integer

lurek.log.info(string.format("snapshot: %d watches, fps=%.1f, logLines=%d",
    snap.watchCount,
    snap.frameStats.fps or 0,
    #snap.log))

-- Snapshot is a plain table — trivial to serialize.
local json = lurek.data.encode("json", snap)
lurek.filesystem.write("save/crash_report.json", json)

-- ─────────────────────────────────────────────────────────────────────────────
-- VS CODE / EXTENSION INTEGRATION HINTS
-- The devtools API is intentionally compatible as a data source for the
-- Lurek2D VS Code extension (extensions/vscode/).
--
-- Pattern: pump snapshot data every second over lurek.thread channels to a
-- background worker that serialises it, then a VS Code MCP endpoint reads it.
-- See extensions/vscode/src/providers/ for the expected format.
-- ─────────────────────────────────────────────────────────────────────────────

lurek.log.info("[devtools.lua] watch/snapshot example complete")
