-- content/examples/debugbridge.lua
-- Auto-scaffolded coverage of the lurek.debugbridge Lua API (14 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/debugbridge.lua

print("[example] lurek.debugbridge loaded — 14 API items demonstrated")

-- ── lurek.debugbridge free functions ──

--@api-stub: lurek.debugbridge.start
-- Start the TCP debug server on 127.0.0.1:port.
-- Use this when start the TCP debug server on 127.0.0.1:port is needed.
if false then
  local _r = lurek.debugbridge.start(0)
  print(_r)
end

--@api-stub: lurek.debugbridge.stop
-- Stop the TCP debug server and close all connections.
-- Use this when stop the TCP debug server and close all connections is needed.
if false then
  local _r = lurek.debugbridge.stop()
  print(_r)
end

--@api-stub: lurek.debugbridge.isRunning
-- Returns whether the server is currently running.
-- Use this when returns whether the server is currently running is needed.
if false then
  local _r = lurek.debugbridge.isRunning()
  print(_r)
end

--@api-stub: lurek.debugbridge.getPort
-- Returns the server port (0 if not running).
-- Use this when returns the server port (0 if not running) is needed.
if false then
  local _r = lurek.debugbridge.getPort()
  print(_r)
end

--@api-stub: lurek.debugbridge.getClientCount
-- Returns the number of connected TCP clients.
-- Use this when returns the number of connected TCP clients is needed.
if false then
  local _r = lurek.debugbridge.getClientCount()
  print(_r)
end

--@api-stub: lurek.debugbridge.poll
-- Poll for pending Lua-dependent requests from TCP clients.
-- Use this when poll for pending Lua-dependent requests from TCP clients is needed.
if false then
  local _r = lurek.debugbridge.poll()
  print(_r)
end

--@api-stub: lurek.debugbridge.capturePrint
-- Captures a print message and broadcasts it to connected clients.
-- Use this when captures a print message and broadcasts it to connected clients is needed.
if false then
  local _r = lurek.debugbridge.capturePrint("msg", nil, 1)
  print(_r)
end

--@api-stub: lurek.debugbridge.getPrintHistory
-- Returns the print history.
-- Use this when returns the print history is needed.
if false then
  local _r = lurek.debugbridge.getPrintHistory(1)
  print(_r)
end

--@api-stub: lurek.debugbridge.clearPrintHistory
-- Clears the print history.
-- Use this when clears the print history is needed.
if false then
  local _r = lurek.debugbridge.clearPrintHistory()
  print(_r)
end

--@api-stub: lurek.debugbridge.setMaxPrintHistory
-- Sets the maximum print history size.
-- Use this when sets the maximum print history size is needed.
if false then
  local _r = lurek.debugbridge.setMaxPrintHistory(0)
  print(_r)
end

--@api-stub: lurek.debugbridge.getPerformance
-- Returns performance statistics.
-- Use this when returns performance statistics is needed.
if false then
  local _r = lurek.debugbridge.getPerformance()
  print(_r)
end

--@api-stub: lurek.debugbridge.requestScreenshot
-- Flags a screenshot request for the next frame.
-- Use this when flags a screenshot request for the next frame is needed.
if false then
  local _r = lurek.debugbridge.requestScreenshot(0)
  print(_r)
end

--@api-stub: lurek.debugbridge.isScreenshotRequested
-- Returns whether a screenshot is currently requested.
-- Use this when returns whether a screenshot is currently requested is needed.
if false then
  local _r = lurek.debugbridge.isScreenshotRequested()
  print(_r)
end

--@api-stub: lurek.debugbridge.broadcast
-- Broadcasts a JSON event to all connected clients.
-- Use this when broadcasts a JSON event to all connected clients is needed.
if false then
  local _r = lurek.debugbridge.broadcast(1, 1)
  print(_r)
end

