-- content/examples/system.lua
-- Practical usage examples for the lurek.system API (26 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.system.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/system.lua

print("[example] lurek.system — 26 API entries")

-- ── lurek.system.* free functions ──

--@api-stub: lurek.system.getOS
-- Returns the host operating system name ('Windows', 'Linux', 'macOS').
-- Call when you need to read o s.
local ok, value = pcall(function() return lurek.system.getOS() end)
local v = ok and value or "(unavailable)"
print("lurek.system.getOS ->", v)

--@api-stub: lurek.system.getVersion
-- Returns the Lurek2D engine version string.
-- Call when you need to read version.
local ok, value = pcall(function() return lurek.system.getVersion() end)
local v = ok and value or "(unavailable)"
print("lurek.system.getVersion ->", v)

--@api-stub: lurek.system.getProcessorCount
-- Returns the number of logical CPU cores available.
-- Call when you need to read processor count.
local ok, value = pcall(function() return lurek.system.getProcessorCount() end)
local v = ok and value or "(unavailable)"
print("lurek.system.getProcessorCount ->", v)

--@api-stub: lurek.system.getMemorySize
-- Returns the total amount of installed system RAM in megabytes.
-- Call when you need to read memory size.
local ok, value = pcall(function() return lurek.system.getMemorySize() end)
local v = ok and value or "(unavailable)"
print("lurek.system.getMemorySize ->", v)

--@api-stub: lurek.system.openURL
-- Opens a URL in the system's default browser.
-- Call when you need to invoke open u r l.
local ok, obj = pcall(function() return lurek.system.openURL("url") end)
if ok and obj then print("created:", obj) end
print("lurek.system.openURL ok=", ok)

--@api-stub: lurek.system.getPreferredLocales
-- Returns an ordered list of the user's preferred locale strings (e.g.
-- 'en-US').
local ok, value = pcall(function() return lurek.system.getPreferredLocales() end)
local v = ok and value or "(unavailable)"
print("lurek.system.getPreferredLocales ->", v)

--@api-stub: lurek.system.getPowerInfo
-- Returns battery state, percentage charged, and estimated time remaining.
-- Call when you need to read power info.
local ok, value = pcall(function() return lurek.system.getPowerInfo() end)
local v = ok and value or "(unavailable)"
print("lurek.system.getPowerInfo ->", v)

--@api-stub: lurek.system.getInfo
-- Returns a table of system information including OS name, CPU model, and installed RAM.
-- Call when you need to read info.
local ok, value = pcall(function() return lurek.system.getInfo() end)
local v = ok and value or "(unavailable)"
print("lurek.system.getInfo ->", v)

--@api-stub: lurek.system.getMessage
-- Resolves a stable runtime message ID such as 'L001' to its human-readable text.
-- Call when you need to read message.
local ok, value = pcall(function() return lurek.system.getMessage(1) end)
local v = ok and value or "(unavailable)"
print("lurek.system.getMessage ->", v)

--@api-stub: lurek.system.hasMessage
-- Returns true when the runtime message catalog contains the given stable message ID.
-- Call when you need to check has message.
local ok, result = pcall(function() return lurek.system.hasMessage(1) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.system.hasMessage ok=", ok)

--@api-stub: lurek.system.getMessageCount
-- Returns the total number of message entries loaded into the runtime message catalog.
-- Call when you need to read message count.
local ok, value = pcall(function() return lurek.system.getMessageCount() end)
local v = ok and value or "(unavailable)"
print("lurek.system.getMessageCount ->", v)

--@api-stub: lurek.system.setClipboardText
-- Replaces the system clipboard contents with the given string.
-- Call when you need to assign clipboard text.
local ok, err = pcall(function() lurek.system.setClipboardText("text value") end)
if not ok then print("set skipped:", err) end
print("lurek.system.setClipboardText applied=", ok)

--@api-stub: lurek.system.getClipboardText
-- Returns the current contents of the system clipboard.
-- Call when you need to read clipboard text.
local ok, value = pcall(function() return lurek.system.getClipboardText() end)
local v = ok and value or "(unavailable)"
print("lurek.system.getClipboardText ->", v)

--@api-stub: lurek.system.setDebugOverlay
-- Shows or hides the FPS/draw-call debug overlay.
-- Call when you need to assign debug overlay.
local ok, err = pcall(function() lurek.system.setDebugOverlay(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.system.setDebugOverlay applied=", ok)

--@api-stub: lurek.system.getDebugOverlay
-- Returns whether the debug overlay is currently visible.
-- Call when you need to read debug overlay.
local ok, value = pcall(function() return lurek.system.getDebugOverlay() end)
local v = ok and value or "(unavailable)"
print("lurek.system.getDebugOverlay ->", v)

--@api-stub: lurek.system.setLogLevel
-- Sets the minimum severity level for runtime log messages.
-- Call when you need to assign log level.
local ok, err = pcall(function() lurek.system.setLogLevel(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.system.setLogLevel applied=", ok)

--@api-stub: lurek.system.getLogLevel
-- Returns the name of the current minimum log level for runtime messages.
-- Call when you need to read log level.
local ok, value = pcall(function() return lurek.system.getLogLevel() end)
local v = ok and value or "(unavailable)"
print("lurek.system.getLogLevel ->", v)

--@api-stub: lurek.system.log
-- Emit a log message from Lua at the specified level.
-- Call when you need to invoke log.
local ok, result = pcall(function() return lurek.system.log(nil, nil) end)
if ok then print("lurek.system.log ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.system.getLastError
-- Returns the last unhandled error message, or nil.
-- Call when you need to read last error.
local ok, value = pcall(function() return lurek.system.getLastError() end)
local v = ok and value or "(unavailable)"
print("lurek.system.getLastError ->", v)

--@api-stub: lurek.system.errorSnapshot
-- Serialises an engine error message to a compact JSON string.
-- Call when you need to invoke error snapshot.
local ok, result = pcall(function() return lurek.system.errorSnapshot("msg value") end)
if ok then print("lurek.system.errorSnapshot ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.system.getArch
-- Returns the CPU architecture string for the current machine.
-- Call when you need to read arch.
local ok, value = pcall(function() return lurek.system.getArch() end)
local v = ok and value or "(unavailable)"
print("lurek.system.getArch ->", v)

--@api-stub: lurek.system.getEnv
-- Returns the value of an environment variable, or nil if not set.
-- Call when you need to read env.
local ok, value = pcall(function() return lurek.system.getEnv("name") end)
local v = ok and value or "(unavailable)"
print("lurek.system.getEnv ->", v)

--@api-stub: lurek.system.getArgs
-- Returns the command-line arguments as a table.
-- Call when you need to read args.
local ok, value = pcall(function() return lurek.system.getArgs() end)
local v = ok and value or "(unavailable)"
print("lurek.system.getArgs ->", v)

--@api-stub: lurek.system.parseArgs
-- Parses a command-line argument string and returns a structured key/value table.
-- Call when you need to invoke parse args.
local ok, result = pcall(function() return lurek.system.parseArgs({}) end)
if ok then print("lurek.system.parseArgs ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.system.runBatch
-- Runs a list of shell commands in parallel and returns immediately without blocking.
-- Call when you need to invoke run batch.
local ok, result = pcall(function() return lurek.system.runBatch(nil, {}) end)
if not ok then print("action skipped:", result) end
print("lurek.system.runBatch fired=", ok)

--@api-stub: lurek.system.getBatchResults
-- Returns the output table from the most recently completed runBatch call.
-- Call when you need to read batch results.
local ok, value = pcall(function() return lurek.system.getBatchResults(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.system.getBatchResults ->", v)

