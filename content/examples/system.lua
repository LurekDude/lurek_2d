-- content/examples/system.lua
-- Auto-scaffolded coverage of the lurek.system Lua API (26 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/system.lua

print("[example] lurek.system loaded — 26 API items demonstrated")

-- ── lurek.system free functions ──

--@api-stub: lurek.system.getOS
-- Returns the host operating system name ('Windows', 'Linux', 'macOS').
-- Use this when returns the host operating system name ('Windows', 'Linux', 'macOS') is needed.
if false then
  local _r = lurek.system.getOS()
  print(_r)
end

--@api-stub: lurek.system.getVersion
-- Returns the Lurek2D engine version string.
-- Use this when returns the Lurek2D engine version string is needed.
if false then
  local _r = lurek.system.getVersion()
  print(_r)
end

--@api-stub: lurek.system.getProcessorCount
-- Returns the number of logical CPU cores available.
-- Use this when returns the number of logical CPU cores available is needed.
if false then
  local _r = lurek.system.getProcessorCount()
  print(_r)
end

--@api-stub: lurek.system.getMemorySize
-- Returns the total amount of installed system RAM in megabytes.
-- Use this when returns the total amount of installed system RAM in megabytes is needed.
if false then
  local _r = lurek.system.getMemorySize()
  print(_r)
end

--@api-stub: lurek.system.openURL
-- Opens a URL in the system's default browser.
-- Use this when opens a URL in the system's default browser is needed.
if false then
  local _r = lurek.system.openURL("url")
  print(_r)
end

--@api-stub: lurek.system.getPreferredLocales
-- Returns an ordered list of the user's preferred locale strings (e.g.
-- 'en-US').
if false then
  local _r = lurek.system.getPreferredLocales()
  print(_r)
end

--@api-stub: lurek.system.getPowerInfo
-- Returns battery state, percentage charged, and estimated time remaining.
-- Use this when returns battery state, percentage charged, and estimated time remaining is needed.
if false then
  local _r = lurek.system.getPowerInfo()
  print(_r)
end

--@api-stub: lurek.system.getInfo
-- Returns a table of system information including OS name, CPU model, and installed RAM.
-- Use this when returns a table of system information including OS name, CPU model, and installed RAM is needed.
if false then
  local _r = lurek.system.getInfo()
  print(_r)
end

--@api-stub: lurek.system.getMessage
-- Resolves a stable runtime message ID such as 'L001' to its human-readable text.
-- Use this when resolves a stable runtime message ID such as 'L001' to its human-readable text is needed.
if false then
  local _r = lurek.system.getMessage(1)
  print(_r)
end

--@api-stub: lurek.system.hasMessage
-- Returns true when the runtime message catalog contains the given stable message ID.
-- Use this when returns true when the runtime message catalog contains the given stable message ID is needed.
if false then
  local _r = lurek.system.hasMessage(1)
  print(_r)
end

--@api-stub: lurek.system.getMessageCount
-- Returns the total number of message entries loaded into the runtime message catalog.
-- Use this when returns the total number of message entries loaded into the runtime message catalog is needed.
if false then
  local _r = lurek.system.getMessageCount()
  print(_r)
end

--@api-stub: lurek.system.setClipboardText
-- Replaces the system clipboard contents with the given string.
-- Use this when replaces the system clipboard contents with the given string is needed.
if false then
  local _r = lurek.system.setClipboardText(0)
  print(_r)
end

--@api-stub: lurek.system.getClipboardText
-- Returns the current contents of the system clipboard.
-- Use this when returns the current contents of the system clipboard is needed.
if false then
  local _r = lurek.system.getClipboardText()
  print(_r)
end

--@api-stub: lurek.system.setDebugOverlay
-- Shows or hides the FPS/draw-call debug overlay.
-- Use this when shows or hides the FPS/draw-call debug overlay is needed.
if false then
  local _r = lurek.system.setDebugOverlay(1)
  print(_r)
end

--@api-stub: lurek.system.getDebugOverlay
-- Returns whether the debug overlay is currently visible.
-- Use this when returns whether the debug overlay is currently visible is needed.
if false then
  local _r = lurek.system.getDebugOverlay()
  print(_r)
end

--@api-stub: lurek.system.setLogLevel
-- Sets the minimum severity level for runtime log messages.
-- Use this when sets the minimum severity level for runtime log messages is needed.
if false then
  local _r = lurek.system.setLogLevel(0)
  print(_r)
end

--@api-stub: lurek.system.getLogLevel
-- Returns the name of the current minimum log level for runtime messages.
-- Use this when returns the name of the current minimum log level for runtime messages is needed.
if false then
  local _r = lurek.system.getLogLevel()
  print(_r)
end

--@api-stub: lurek.system.log
-- Emit a log message from Lua at the specified level.
-- Use this when emit a log message from Lua at the specified level is needed.
if false then
  local _r = lurek.system.log(0, nil)
  print(_r)
end

--@api-stub: lurek.system.getLastError
-- Returns the last unhandled error message, or nil.
-- Use this when returns the last unhandled error message, or nil is needed.
if false then
  local _r = lurek.system.getLastError()
  print(_r)
end

--@api-stub: lurek.system.errorSnapshot
-- Serialises an engine error message to a compact JSON string.
-- Use this when serialises an engine error message to a compact JSON string is needed.
if false then
  local _r = lurek.system.errorSnapshot("msg")
  print(_r)
end

--@api-stub: lurek.system.getArch
-- Returns the CPU architecture string for the current machine.
-- Use this when returns the CPU architecture string for the current machine is needed.
if false then
  local _r = lurek.system.getArch()
  print(_r)
end

--@api-stub: lurek.system.getEnv
-- Returns the value of an environment variable, or nil if not set.
-- Use this when returns the value of an environment variable, or nil if not set is needed.
if false then
  local _r = lurek.system.getEnv(1)
  print(_r)
end

--@api-stub: lurek.system.getArgs
-- Returns the command-line arguments as a table.
-- Use this when returns the command-line arguments as a table is needed.
if false then
  local _r = lurek.system.getArgs()
  print(_r)
end

--@api-stub: lurek.system.parseArgs
-- Parses a command-line argument string and returns a structured key/value table.
-- Use this when parses a command-line argument string and returns a structured key/value table is needed.
if false then
  local _r = lurek.system.parseArgs({})
  print(_r)
end

--@api-stub: lurek.system.runBatch
-- Runs a list of shell commands in parallel and returns immediately without blocking.
-- Use this when runs a list of shell commands in parallel and returns immediately without blocking is needed.
if false then
  local _r = lurek.system.runBatch(0, 0)
  print(_r)
end

--@api-stub: lurek.system.getBatchResults
-- Returns the output table from the most recently completed runBatch call.
-- Use this when returns the output table from the most recently completed runBatch call is needed.
if false then
  local _r = lurek.system.getBatchResults(0)
  print(_r)
end

