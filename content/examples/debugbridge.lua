-- content/examples/debugbridge.lua
-- Lurek2D lurek.debugbridge API Reference
-- Run with: cargo run -- content/examples/debugbridge

-- =============================================================================
-- lurek.debugbridge — TCP debug server for external tooling
--
-- The debug bridge starts a TCP server on localhost that external tools
-- (VS Code extension, remote inspectors, custom dashboards) connect to.
-- It streams print output, performance stats, and screenshot requests
-- between the running game and any connected client.
-- =============================================================================

-- ---- Stub: lurek.debugbridge.start ---------------------------------------
--@api-stub: lurek.debugbridge.start
-- Launch the debug server on port 9100 during development so the VS Code
-- extension can connect and stream live game output.
local ok = lurek.debugbridge.start(9100)
if ok then
    print("debug bridge started on port 9100")
else
    print("failed to start debug bridge (port in use?)")
end

-- ---- Stub: lurek.debugbridge.isRunning -----------------------------------
--@api-stub: lurek.debugbridge.isRunning
-- Check whether the debug server is active before attempting to broadcast.
-- This avoids errors when the bridge was never started (e.g. release builds).
local running = lurek.debugbridge.isRunning()
print("debug bridge active: " .. tostring(running))
if not running then
    print("  -> skip all debug bridge calls in this session")
end

-- ---- Stub: lurek.debugbridge.getPort -------------------------------------
--@api-stub: lurek.debugbridge.getPort
-- Report the actual listening port.  Useful when port 0 is passed to start()
-- to let the OS assign an ephemeral port.
local port = lurek.debugbridge.getPort()
print("listening on port: " .. port)

-- ---- Stub: lurek.debugbridge.getClientCount ------------------------------
--@api-stub: lurek.debugbridge.getClientCount
-- Show how many external tools are connected.  A debug overlay might display
-- "2 inspectors attached" so the developer knows who is watching.
local clients = lurek.debugbridge.getClientCount()
print("connected clients: " .. clients)
if clients == 0 then
    print("  (no external tools connected)")
end

-- ---- Stub: lurek.debugbridge.capturePrint --------------------------------
--@api-stub: lurek.debugbridge.capturePrint
-- Forward important game events to connected tools.  capturePrint stores the
-- message in print history AND broadcasts it to all TCP clients.
lurek.debugbridge.capturePrint("player entered boss arena", "game.lua", 142)
lurek.debugbridge.capturePrint("boss health: 5000/5000", "boss_ai.lua", 78)
lurek.debugbridge.capturePrint("music switched to boss_theme.ogg")
print("captured 3 print messages")

-- ---- Stub: lurek.debugbridge.getPrintHistory -----------------------------
--@api-stub: lurek.debugbridge.getPrintHistory
-- Retrieve the last N captured prints.  An in-game console can display the
-- most recent 20 messages as scrollable text.
local history = lurek.debugbridge.getPrintHistory(20)
print("print history (" .. #history .. " entries):")
for i, entry in ipairs(history) do
    local src = entry.source or "?"
    local ln  = entry.line or 0
    print(string.format("  [%d] %s  (%s:%d)", i, entry.message, src, ln))
end

-- ---- Stub: lurek.debugbridge.setMaxPrintHistory --------------------------
--@api-stub: lurek.debugbridge.setMaxPrintHistory
-- Limit history to 500 entries to prevent unbounded memory growth during
-- long play sessions with verbose logging.
lurek.debugbridge.setMaxPrintHistory(500)
print("print history cap set to 500")

-- ---- Stub: lurek.debugbridge.clearPrintHistory ---------------------------
--@api-stub: lurek.debugbridge.clearPrintHistory
-- Clear history when the player starts a new level so the console only shows
-- messages relevant to the current gameplay section.
lurek.debugbridge.clearPrintHistory()
print("print history cleared for new level")
local after = lurek.debugbridge.getPrintHistory(10)
print("history after clear: " .. #after .. " entries")

-- ---- Stub: lurek.debugbridge.poll ----------------------------------------
--@api-stub: lurek.debugbridge.poll
-- Poll for incoming requests from connected tools each frame.  Requests are
-- Lua tables with an "action" field (e.g. "eval", "get_state", "set_var").
local request = lurek.debugbridge.poll()
if request then
    print("incoming request: " .. tostring(request.action or "unknown"))
    -- Typical actions: "eval" -> run a Lua string, "screenshot" -> capture
    if request.action == "eval" and request.code then
        print("  evaluating: " .. request.code)
    end
else
    print("no pending requests")
end

-- ---- Stub: lurek.debugbridge.getPerformance ------------------------------
--@api-stub: lurek.debugbridge.getPerformance
-- Gather frame timing and draw-call stats for the external profiler.  The
-- VS Code extension graphs these values over time to spot stutters.
local perf = lurek.debugbridge.getPerformance()
print("performance snapshot:")
if perf.fps then
    print(string.format("  fps:        %.1f", perf.fps))
end
if perf.frame_ms then
    print(string.format("  frame time: %.2f ms", perf.frame_ms))
end
if perf.draw_calls then
    print("  draw calls: " .. perf.draw_calls)
end
if perf.lua_memory then
    print(string.format("  lua memory: %.1f KB", perf.lua_memory / 1024))
end

-- ---- Stub: lurek.debugbridge.requestScreenshot ---------------------------
--@api-stub: lurek.debugbridge.requestScreenshot
-- Flag a screenshot request so the renderer captures the next frame.  The
-- VS Code extension triggers this to show a live preview thumbnail.
lurek.debugbridge.requestScreenshot(1.0)   -- 1.0 = full scale
print("screenshot requested at full scale")

-- Half-resolution for faster transfer over TCP:
-- lurek.debugbridge.requestScreenshot(0.5)

-- ---- Stub: lurek.debugbridge.isScreenshotRequested -----------------------
--@api-stub: lurek.debugbridge.isScreenshotRequested
-- The render loop checks this flag before encoding a frame as PNG.  Only
-- encode the screenshot if it was explicitly requested to avoid overhead.
local pending = lurek.debugbridge.isScreenshotRequested()
print("screenshot pending: " .. tostring(pending))
if pending then
    print("  -> renderer will capture this frame as PNG")
end

-- ---- Stub: lurek.debugbridge.broadcast -----------------------------------
--@api-stub: lurek.debugbridge.broadcast
-- Send a custom JSON event to all connected tools.  Use this for game-specific
-- telemetry: quest completions, death locations, performance milestones.
lurek.debugbridge.broadcast("quest_complete", '{"quest":"dragon_slayer","time_sec":342}')
lurek.debugbridge.broadcast("player_death",   '{"zone":"lava_caves","cause":"spike_trap"}')
print("broadcast 2 custom events to connected clients")

-- Useful for live dashboards that graph deaths-per-zone or quest completion rates

-- ---- Stub: lurek.debugbridge.stop ----------------------------------------
--@api-stub: lurek.debugbridge.stop
-- Shut down the debug server cleanly when leaving the dev menu or before
-- switching to a release configuration.
lurek.debugbridge.stop()
print("debug bridge stopped")
local still_running = lurek.debugbridge.isRunning()
print("still running: " .. tostring(still_running))
-- content/examples/debugbridge.lua
-- Lurek2D lurek.debugbridge API Reference
-- Run with: cargo run -- content/examples/debugbridge

-- =============================================================================
-- STUBS: 14 uncovered lurek.debugbridge API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.debugbridge.start ---------------------------------------
--@api-stub: lurek.debugbridge.start
-- Start the TCP debug server on 127.0.0.1:port.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.debugbridge.start([port])  -- -> boolean

-- ---- Stub: lurek.debugbridge.stop ----------------------------------------
--@api-stub: lurek.debugbridge.stop
-- Stop the TCP debug server and close all connections.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.debugbridge.stop()

-- ---- Stub: lurek.debugbridge.isRunning -----------------------------------
--@api-stub: lurek.debugbridge.isRunning
-- Returns whether the server is currently running.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.debugbridge.isRunning()  -- -> bool

-- ---- Stub: lurek.debugbridge.getPort -------------------------------------
--@api-stub: lurek.debugbridge.getPort
-- Returns the server port (0 if not running).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.debugbridge.getPort()  -- -> integer

-- ---- Stub: lurek.debugbridge.getClientCount ------------------------------
--@api-stub: lurek.debugbridge.getClientCount
-- Returns the number of connected TCP clients.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.debugbridge.getClientCount()  -- -> integer

-- ---- Stub: lurek.debugbridge.poll ----------------------------------------
--@api-stub: lurek.debugbridge.poll
-- Poll for pending Lua-dependent requests from TCP clients.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.debugbridge.poll()  -- -> table|nil

-- ---- Stub: lurek.debugbridge.capturePrint --------------------------------
--@api-stub: lurek.debugbridge.capturePrint
-- Captures a print message and broadcasts it to connected clients.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.debugbridge.capturePrint("level_complete", [source], [line])

-- ---- Stub: lurek.debugbridge.getPrintHistory -----------------------------
--@api-stub: lurek.debugbridge.getPrintHistory
-- Returns the print history.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.debugbridge.getPrintHistory([count])  -- -> table

-- ---- Stub: lurek.debugbridge.clearPrintHistory ---------------------------
--@api-stub: lurek.debugbridge.clearPrintHistory
-- Clears the print history.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.debugbridge.clearPrintHistory()

-- ---- Stub: lurek.debugbridge.setMaxPrintHistory --------------------------
--@api-stub: lurek.debugbridge.setMaxPrintHistory
-- Sets the maximum print history size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.debugbridge.setMaxPrintHistory(max)

-- ---- Stub: lurek.debugbridge.getPerformance ------------------------------
--@api-stub: lurek.debugbridge.getPerformance
-- Returns performance statistics.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.debugbridge.getPerformance()  -- -> table

-- ---- Stub: lurek.debugbridge.requestScreenshot ---------------------------
--@api-stub: lurek.debugbridge.requestScreenshot
-- Flags a screenshot request for the next frame.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.debugbridge.requestScreenshot([scale])

-- ---- Stub: lurek.debugbridge.isScreenshotRequested -----------------------
--@api-stub: lurek.debugbridge.isScreenshotRequested
-- Returns whether a screenshot is currently requested.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.debugbridge.isScreenshotRequested()  -- -> bool

-- ---- Stub: lurek.debugbridge.broadcast -----------------------------------
--@api-stub: lurek.debugbridge.broadcast
-- Broadcasts a JSON event to all connected clients.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.debugbridge.broadcast(event, json_data)
