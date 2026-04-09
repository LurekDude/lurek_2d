-- examples/debugbridge.lua
-- Demonstrates luna.debugbridge — the remote debug protocol server for Luna2D.
-- The bridge opens a TCP/WebSocket server that external tools (VS Code extension,
-- browser DevTools, custom scripts) connect to for real-time game inspection.
-- Run with: cargo run -- examples/debugbridge
--
-- Protocol overview:
--   1. Call luna.debugbridge.start() once at startup.
--   2. Call luna.debugbridge.poll() every frame inside luna.process() to process
--      incoming client messages and queue outgoing responses.
--   3. Forward luna.print() output with capturePrint() for remote console display.
--   4. Broadcast custom events with broadcast() for custom tooling.
--   5. Call stop() on shutdown (automatically called on luna.quit).
--
-- Security note: The bridge is NOT authenticated — only start it in development
-- builds.  Never start it in shipped games.

-- ─────────────────────────────────────────────────────────────────────────────
-- START / STOP
-- ─────────────────────────────────────────────────────────────────────────────

-- Start the debug server on the default port (8765).
-- Returns true on success, false if the port is already in use.
local ok = luna.debugbridge.start()
if not ok then
    luna.log.warn("[debugbridge] server could not start — port already in use?")
end

-- Use a custom port when the default is occupied
-- local ok2 = luna.debugbridge.start(9000)

-- Check server state at any time
if luna.debugbridge.isRunning() then
    local port = luna.debugbridge.getPort()    -- e.g. 8765
    luna.log.info(string.format("[debugbridge] listening on port %d", port))
end

-- Count connected clients (WebSocket connections)
local clients = luna.debugbridge.getClientCount()   -- 0 initially
luna.log.debug("[debugbridge] connected clients: " .. clients)

-- ─────────────────────────────────────────────────────────────────────────────
-- POLLING — MUST be called every frame
-- poll() drains the outgoing message queue and processes incoming client
-- requests (variable inspection, eval, screenshot requests, etc.).
-- Without poll() the bridge appears connected but never responds.
-- ─────────────────────────────────────────────────────────────────────────────

-- Simulated single poll — in real code: inside luna.process(dt)
luna.debugbridge.poll()

-- Full integration pattern (put inside luna.process):
--   luna.process = function(dt)
--       -- Game logic ...
--       luna.debugbridge.poll()       -- bridge must be last in the frame
--   end

-- ─────────────────────────────────────────────────────────────────────────────
-- PRINT CAPTURE
-- Route all game print() calls to connected debug clients so they appear
-- in the remote console.  The bridge does NOT intercept Lua's print()
-- automatically — you must call capturePrint() explicitly (or wrap print).
-- ─────────────────────────────────────────────────────────────────────────────

-- Capture a message with optional source location metadata
luna.debugbridge.capturePrint("level 1 loaded")
luna.debugbridge.capturePrint("enemy spawned at (128, 64)", "spawn.lua", 42)

-- Replace the global print so all output is automatically captured
local _original_print = print
print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(select(i, ...))
    end
    local message = table.concat(parts, "\t")
    _original_print(message)                              -- keep stdout working
    luna.debugbridge.capturePrint(message, "global", 0)  -- forward to clients
end

-- Configure the ring-buffer capacity for print history (default 256)
luna.debugbridge.setMaxPrintHistory(512)

-- Retrieve recent captured messages for local display (e.g. in-game console)
-- Returns an array of {message, source, line, timestamp_ms}
local history = luna.debugbridge.getPrintHistory()       -- all entries
local last_20 = luna.debugbridge.getPrintHistory(20)     -- latest 20

for _, entry in ipairs(last_20) do
    -- entry.message      — the captured string
    -- entry.source       — source file or "" if not provided
    -- entry.line         — line number or 0
    -- entry.timestamp_ms — milliseconds since epoch
    _ = entry
end

-- Flush the print history buffer (called automatically on luna.quit)
luna.debugbridge.clearPrintHistory()

-- ─────────────────────────────────────────────────────────────────────────────
-- PERFORMANCE SNAPSHOT
-- Ask the bridge for a live performance snapshot.  Connected clients receive
-- this automatically on each poll(); getPerformance() gives a local copy.
-- ─────────────────────────────────────────────────────────────────────────────

local perf = luna.debugbridge.getPerformance()
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
luna.debugbridge.requestScreenshot()          -- full resolution
luna.debugbridge.requestScreenshot(0.5)       -- half-resolution (scale = 0.5)

-- Check for a pending screenshot request and fill it
-- In a real game this goes in luna.render_ui or a post-render hook:
--   if luna.debugbridge.isScreenshotRequested() then
--       local path = "save/bridge_screenshot.png"
--       luna.graphics.saveScreenshot(path)
--       luna.debugbridge.broadcast("screenshot", '{"path":"' .. path .. '"}')
--   end

local waiting = luna.debugbridge.isScreenshotRequested()   -- false or true
_ = waiting

-- ─────────────────────────────────────────────────────────────────────────────
-- BROADCAST — push custom events to all connected clients
-- Useful for custom tooling: level editors, balance dashboards, AI visualisers.
-- event  — event type string (client-side switch key)
-- data   — JSON-encoded string payload (must be valid JSON)
-- ─────────────────────────────────────────────────────────────────────────────

-- Broadcast a simple state event
luna.debugbridge.broadcast("gameState", '{"phase":"playing","level":1}')

-- Broadcast a player stats update
local hp, mp, level = 100, 42, 5
luna.debugbridge.broadcast("playerStats",
    string.format('{"hp":%d,"mp":%d,"level":%d}', hp, mp, level))

-- Broadcast a custom map event for a level-editor tool
luna.debugbridge.broadcast("tileChanged", '{"x":3,"y":7,"tile":12}')

-- Broadcast an AI state event for a visualiser
luna.debugbridge.broadcast("aiState", '{"entity":5,"state":"chasing","target":1}')

-- ─────────────────────────────────────────────────────────────────────────────
-- FULL FRAME INTEGRATION TEMPLATE
-- Copy this pattern into your main.lua when you want live debugging support.
-- ─────────────────────────────────────────────────────────────────────────────

-- luna.init = function()
--     if DEBUG_MODE then
--         local ok = luna.debugbridge.start()   -- default port 8765
--         if ok then
--             luna.log.info("[debugbridge] started — connect VS Code extension")
-- end

-- luna.process = function(dt)
--     -- ... all game logic ...
--
--     if luna.debugbridge.isRunning() then
--         luna.debugbridge.capturePrint("[frame] dt=" .. string.format("%.4f", dt))
--         luna.debugbridge.broadcast("frameTick", string.format('{"dt":%f}', dt))
--         luna.debugbridge.poll()    -- always last
-- end

-- luna.render_ui = function()
--     if luna.debugbridge.isRunning() and luna.debugbridge.isScreenshotRequested() then
--         luna.graphics.saveScreenshot("save/screenshot.png")
--         luna.debugbridge.broadcast("screenshot", '{"path":"save/screenshot.png"}')
-- end

-- ─────────────────────────────────────────────────────────────────────────────
-- STOP — explicit shutdown (also automatic on luna.quit)
-- ─────────────────────────────────────────────────────────────────────────────

luna.debugbridge.stop()
luna.log.info(string.format("[debugbridge] stopped, was running: %s", tostring(ok)))

luna.log.info("[debugbridge.lua] example complete")
