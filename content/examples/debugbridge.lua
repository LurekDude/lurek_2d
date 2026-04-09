-- examples/debugbridge.lua
-- Demonstrates lurek.debugbridge — the remote debug protocol server for Lurek2D.
-- The bridge opens a TCP/WebSocket server that external tools (VS Code extension,
-- browser DevTools, custom scripts) connect to for real-time game inspection.
-- Run with: cargo run -- examples/debugbridge
--
-- Protocol overview:
1. Call lurek.debugbridge.start() once at startup.
2. Call lurek.debugbridge.poll() every frame inside lurek.process() to process
incoming client messages and queue outgoing responses.
3. Forward lurek.print() output with capturePrint() for remote console display.
4. Broadcast custom events with broadcast() for custom tooling.
5. Call stop() on shutdown (automatically called on lurek.quit).
--
-- Security note: The bridge is NOT authenticated — only start it in development
-- builds.  Never start it in shipped games.

-- ─────────────────────────────────────────────────────────────────────────────
-- START / STOP
-- ─────────────────────────────────────────────────────────────────────────────

-- Start the debug server on the default port (8765).
-- Returns true on success, false if the port is already in use.
local ok = lurek.debugbridge.start()
if not ok then
    lurek.log.warn("[debugbridge] server could not start — port already in use?")
end

-- Use a custom port when the default is occupied
local ok2 = lurek.debugbridge.start(9000)

-- Check server state at any time
if lurek.debugbridge.isRunning() then
    local port = lurek.debugbridge.getPort()    -- e.g. 8765
    lurek.log.info(string.format("[debugbridge] listening on port %d", port))
end

-- Count connected clients (WebSocket connections)
local clients = lurek.debugbridge.getClientCount()   -- 0 initially
lurek.log.debug("[debugbridge] connected clients: " .. clients)

-- ─────────────────────────────────────────────────────────────────────────────
-- POLLING — MUST be called every frame
-- poll() drains the outgoing message queue and processes incoming client
-- requests (variable inspection, eval, screenshot requests, etc.).
-- Without poll() the bridge appears connected but never responds.
-- ─────────────────────────────────────────────────────────────────────────────

-- Simulated single poll — in real code: inside lurek.process(dt)
lurek.debugbridge.poll()

-- Full integration pattern (put inside lurek.process):
lurek.process = function(dt)
-- Game logic ...
lurek.debugbridge.poll()       -- bridge must be last in the frame
end

-- ─────────────────────────────────────────────────────────────────────────────
-- PRINT CAPTURE
-- Route all game print() calls to connected debug clients so they appear
-- in the remote console.  The bridge does NOT intercept Lua's print()
-- automatically — you must call capturePrint() explicitly (or wrap print).
-- ─────────────────────────────────────────────────────────────────────────────

-- Capture a message with optional source location metadata
lurek.debugbridge.capturePrint("level 1 loaded")
lurek.debugbridge.capturePrint("enemy spawned at (128, 64)", "spawn.lua", 42)

-- Replace the global print so all output is automatically captured
local _original_print = print
print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(select(i, ...))
    end
    local message = table.concat(parts, "\t")
    _original_print(message)                              -- keep stdout working
    lurek.debugbridge.capturePrint(message, "global", 0)  -- forward to clients
end

-- Configure the ring-buffer capacity for print history (default 256)
lurek.debugbridge.setMaxPrintHistory(512)

-- Retrieve recent captured messages for local display (e.g. in-game console)
-- Returns an array of {message, source, line, timestamp_ms}
local history = lurek.debugbridge.getPrintHistory()       -- all entries
local last_20 = lurek.debugbridge.getPrintHistory(20)     -- latest 20

for _, entry in ipairs(last_20) do
    -- entry.message      — the captured string
    -- entry.source       — source file or "" if not provided
    -- entry.line         — line number or 0
    -- entry.timestamp_ms — milliseconds since epoch
    _ = entry
end

-- Flush the print history buffer (called automatically on lurek.quit)
lurek.debugbridge.clearPrintHistory()

-- ─────────────────────────────────────────────────────────────────────────────
-- PERFORMANCE SNAPSHOT
-- Ask the bridge for a live performance snapshot.  Connected clients receive
-- this automatically on each poll(); getPerformance() gives a local copy.
-- ─────────────────────────────────────────────────────────────────────────────

local perf = lurek.debugbridge.getPerformance()
-- perf.fps   — current frames per second
-- perf.dt    — last delta-time in seconds
-- perf.avg   — average frame time (rolling window)
-- perf.min   — shortest frame time recorded
-- perf.max   — worst spike in the rolling window

if perf then
    print(string.format("perf: %.1f fps  dt=%.2fms  worst=%.2fms",
        perf.fps, perf.dt * 1000, perf.max * 1000))
end

-- ─────────────────────────────────────────────────────────────────────────────
-- SCREENSHOT REQUEST
-- A connected client can request a screenshot; the game should fulfil it on
-- the next render cycle.  The bridge only flags the request — the game is
-- responsible for actually capturing and sending the pixels.
-- ─────────────────────────────────────────────────────────────────────────────

-- Programmatically request a screenshot (as if a client sent the command)
lurek.debugbridge.requestScreenshot()          -- full resolution
lurek.debugbridge.requestScreenshot(0.5)       -- half-resolution (scale = 0.5)

-- Check for a pending screenshot request and fill it
-- In a real game this goes in lurek.render_ui or a post-render hook:
if lurek.debugbridge.isScreenshotRequested() then
local path = "save/bridge_screenshot.png"
lurek.graphics.saveScreenshot(path)
lurek.debugbridge.broadcast("screenshot", '{"path":"' .. path .. '"}')
end

local waiting = lurek.debugbridge.isScreenshotRequested()   -- false or true
_ = waiting

-- ─────────────────────────────────────────────────────────────────────────────
-- BROADCAST — push custom events to all connected clients
-- Useful for custom tooling: level editors, balance dashboards, AI visualisers.
-- event  — event type string (client-side switch key)
-- data   — JSON-encoded string payload (must be valid JSON)
-- ─────────────────────────────────────────────────────────────────────────────

-- Broadcast a simple state event
lurek.debugbridge.broadcast("gameState", '{"phase":"playing","level":1}')

-- Broadcast a player stats update
local hp, mp, level = 100, 42, 5
lurek.debugbridge.broadcast("playerStats",
    string.format('{"hp":%d,"mp":%d,"level":%d}', hp, mp, level))

-- Broadcast a custom map event for a level-editor tool
lurek.debugbridge.broadcast("tileChanged", '{"x":3,"y":7,"tile":12}')

-- Broadcast an AI state event for a visualiser
lurek.debugbridge.broadcast("aiState", '{"entity":5,"state":"chasing","target":1}')

-- ─────────────────────────────────────────────────────────────────────────────
-- FULL FRAME INTEGRATION TEMPLATE
-- Copy this pattern into your main.lua when you want live debugging support.
-- ─────────────────────────────────────────────────────────────────────────────

-- lurek.init = function()
if DEBUG_MODE then
local ok = lurek.debugbridge.start()   -- default port 8765
if ok then
lurek.log.info("[debugbridge] started  -- connect VS Code extension")
-- end

-- lurek.process = function(dt)
-- ... all game logic ...
--
if lurek.debugbridge.isRunning() then
lurek.debugbridge.capturePrint("[frame] dt=" .. string.format("%.4f", dt))
lurek.debugbridge.broadcast("frameTick", string.format('{"dt":%f}', dt))
lurek.debugbridge.poll()    -- always last
-- end

-- lurek.render_ui = function()
if lurek.debugbridge.isRunning() and lurek.debugbridge.isScreenshotRequested() then
lurek.graphics.saveScreenshot("save/screenshot.png")
lurek.debugbridge.broadcast("screenshot", '{"path":"save/screenshot.png"}')
-- end

-- ─────────────────────────────────────────────────────────────────────────────
-- STOP — explicit shutdown (also automatic on lurek.quit)
-- ─────────────────────────────────────────────────────────────────────────────

lurek.debugbridge.stop()
lurek.log.info(string.format("[debugbridge] stopped, was running: %s", tostring(ok)))

lurek.log.info("[debugbridge.lua] example complete")
