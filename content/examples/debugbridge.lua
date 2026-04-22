-- content/examples/debugbridge.lua
-- Practical usage examples for the lurek.debugbridge API (14 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.debugbridge.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/debugbridge.lua

print("[example] lurek.debugbridge — 14 API entries")

-- ── lurek.debugbridge.* free functions ──

--@api-stub: lurek.debugbridge.start
-- Start the TCP debug server on 127.0.0.1:port.
-- Call when you need to invoke start.
local ok, result = pcall(function() return lurek.debugbridge.start(nil) end)
if not ok then print("action skipped:", result) end
print("lurek.debugbridge.start fired=", ok)

--@api-stub: lurek.debugbridge.stop
-- Stop the TCP debug server and close all connections.
-- Call when you need to invoke stop.
local ok, result = pcall(function() return lurek.debugbridge.stop() end)
if not ok then print("action skipped:", result) end
print("lurek.debugbridge.stop fired=", ok)

--@api-stub: lurek.debugbridge.isRunning
-- Returns whether the server is currently running.
-- Call when you need to check is running.
local ok, result = pcall(function() return lurek.debugbridge.isRunning() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.debugbridge.isRunning ok=", ok)

--@api-stub: lurek.debugbridge.getPort
-- Returns the server port (0 if not running).
-- Call when you need to read port.
local ok, value = pcall(function() return lurek.debugbridge.getPort() end)
local v = ok and value or "(unavailable)"
print("lurek.debugbridge.getPort ->", v)

--@api-stub: lurek.debugbridge.getClientCount
-- Returns the number of connected TCP clients.
-- Call when you need to read client count.
local ok, value = pcall(function() return lurek.debugbridge.getClientCount() end)
local v = ok and value or "(unavailable)"
print("lurek.debugbridge.getClientCount ->", v)

--@api-stub: lurek.debugbridge.poll
-- Poll for pending Lua-dependent requests from TCP clients.
-- Call when you need to invoke poll.
local ok, result = pcall(function() return lurek.debugbridge.poll() end)
if ok then print("lurek.debugbridge.poll ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.debugbridge.capturePrint
-- Captures a print message and broadcasts it to connected clients.
-- Call when you need to invoke capture print.
local ok, result = pcall(function() return lurek.debugbridge.capturePrint("msg value", nil, nil) end)
if ok then print("lurek.debugbridge.capturePrint ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.debugbridge.getPrintHistory
-- Returns the print history.
-- Call when you need to read print history.
local ok, value = pcall(function() return lurek.debugbridge.getPrintHistory(10) end)
local v = ok and value or "(unavailable)"
print("lurek.debugbridge.getPrintHistory ->", v)

--@api-stub: lurek.debugbridge.clearPrintHistory
-- Clears the print history.
-- Call when you need to invoke clear print history.
local ok, err = pcall(function() lurek.debugbridge.clearPrintHistory() end)
if not ok then print("skipped:", err) end
print("lurek.debugbridge.clearPrintHistory cleared=", ok)

--@api-stub: lurek.debugbridge.setMaxPrintHistory
-- Sets the maximum print history size.
-- Call when you need to assign max print history.
local ok, err = pcall(function() lurek.debugbridge.setMaxPrintHistory(100) end)
if not ok then print("set skipped:", err) end
print("lurek.debugbridge.setMaxPrintHistory applied=", ok)

--@api-stub: lurek.debugbridge.getPerformance
-- Returns performance statistics.
-- Call when you need to read performance.
local ok, value = pcall(function() return lurek.debugbridge.getPerformance() end)
local v = ok and value or "(unavailable)"
print("lurek.debugbridge.getPerformance ->", v)

--@api-stub: lurek.debugbridge.requestScreenshot
-- Flags a screenshot request for the next frame.
-- Call when you need to invoke request screenshot.
local ok, result = pcall(function() return lurek.debugbridge.requestScreenshot(1) end)
if ok then print("lurek.debugbridge.requestScreenshot ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.debugbridge.isScreenshotRequested
-- Returns whether a screenshot is currently requested.
-- Call when you need to check is screenshot requested.
local ok, result = pcall(function() return lurek.debugbridge.isScreenshotRequested() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.debugbridge.isScreenshotRequested ok=", ok)

--@api-stub: lurek.debugbridge.broadcast
-- Broadcasts a JSON event to all connected clients.
-- Call when you need to invoke broadcast.
local ok, result = pcall(function() return lurek.debugbridge.broadcast(nil, {}) end)
if ok then print("lurek.debugbridge.broadcast ->", result)
else print("unavailable:", result) end

