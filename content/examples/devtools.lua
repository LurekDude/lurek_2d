-- content/examples/devtools.lua
-- Practical usage examples for the lurek.devtools API (48 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.devtools.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/devtools.lua

print("[example] lurek.devtools — 48 API entries")

-- ── lurek.devtools.* free functions ──

--@api-stub: lurek.devtools.log
-- Logs a message at the given level.
-- Call when you need to invoke log.
local ok, result = pcall(function() return lurek.devtools.log(nil, nil) end)
if ok then print("lurek.devtools.log ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.devtools.setLogLevel
-- Sets the minimum log level.
-- Call when you need to assign log level.
local ok, err = pcall(function() lurek.devtools.setLogLevel(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.devtools.setLogLevel applied=", ok)

--@api-stub: lurek.devtools.getLogLevel
-- Returns the current minimum log level.
-- Call when you need to read log level.
local ok, value = pcall(function() return lurek.devtools.getLogLevel() end)
local v = ok and value or "(unavailable)"
print("lurek.devtools.getLogLevel ->", v)

--@api-stub: lurek.devtools.setLogConsole
-- Enables or disables console log output.
-- Call when you need to assign log console.
local ok, err = pcall(function() lurek.devtools.setLogConsole(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.devtools.setLogConsole applied=", ok)

--@api-stub: lurek.devtools.getLogConsole
-- Returns whether console log output is enabled.
-- Call when you need to read log console.
local ok, value = pcall(function() return lurek.devtools.getLogConsole() end)
local v = ok and value or "(unavailable)"
print("lurek.devtools.getLogConsole ->", v)

--@api-stub: lurek.devtools.setLogFile
-- Sets the log file path (empty string disables file output).
-- Call when you need to assign log file.
local ok, err = pcall(function() lurek.devtools.setLogFile("path") end)
if not ok then print("set skipped:", err) end
print("lurek.devtools.setLogFile applied=", ok)

--@api-stub: lurek.devtools.getLogFile
-- Returns the current log file path.
-- Call when you need to read log file.
local ok, value = pcall(function() return lurek.devtools.getLogFile() end)
local v = ok and value or "(unavailable)"
print("lurek.devtools.getLogFile ->", v)

--@api-stub: lurek.devtools.getLogHistory
-- Returns recent log entries as an array of tables.
-- Call when you need to read log history.
local ok, value = pcall(function() return lurek.devtools.getLogHistory(10) end)
local v = ok and value or "(unavailable)"
print("lurek.devtools.getLogHistory ->", v)

--@api-stub: lurek.devtools.clearLog
-- Discards all accumulated log entries from the in-memory devtools log buffer.
-- Call when you need to invoke clear log.
local ok, err = pcall(function() lurek.devtools.clearLog() end)
if not ok then print("skipped:", err) end
print("lurek.devtools.clearLog cleared=", ok)

--@api-stub: lurek.devtools.setProfilingEnabled
-- Enables or disables the profiler.
-- Call when you need to assign profiling enabled.
local ok, err = pcall(function() lurek.devtools.setProfilingEnabled(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.devtools.setProfilingEnabled applied=", ok)

--@api-stub: lurek.devtools.isProfilingEnabled
-- Returns whether the profiler is enabled.
-- Call when you need to check is profiling enabled.
local ok, result = pcall(function() return lurek.devtools.isProfilingEnabled() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.devtools.isProfilingEnabled ok=", ok)

--@api-stub: lurek.devtools.profilePush
-- Opens a named profiling zone on the stack.
-- Call when you need to invoke profile push.
local ok, result = pcall(function() return lurek.devtools.profilePush("name") end)
if ok then print("lurek.devtools.profilePush ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.devtools.profilePop
-- Closes the most recent profiling zone.
-- Call when you need to invoke profile pop.
local ok, result = pcall(function() return lurek.devtools.profilePop() end)
if ok then print("lurek.devtools.profilePop ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.devtools.profileFrame
-- Seals the current frame of profiling data.
-- Call when you need to invoke profile frame.
local ok, result = pcall(function() return lurek.devtools.profileFrame() end)
if ok then print("lurek.devtools.profileFrame ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.devtools.getProfileFrameCount
-- Returns the number of retained profile frames.
-- Call when you need to read profile frame count.
local ok, value = pcall(function() return lurek.devtools.getProfileFrameCount() end)
local v = ok and value or "(unavailable)"
print("lurek.devtools.getProfileFrameCount ->", v)

--@api-stub: lurek.devtools.getProfileData
-- Returns zone data table for a specific frame (0 or nil = most recent).
-- Call when you need to read profile data.
local ok, value = pcall(function() return lurek.devtools.getProfileData(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.devtools.getProfileData ->", v)

--@api-stub: lurek.devtools.resetProfile
-- Clears all profiling data and resets the zone stack.
-- Call when you need to invoke reset profile.
local ok, err = pcall(function() lurek.devtools.resetProfile() end)
if not ok then print("skipped:", err) end
print("lurek.devtools.resetProfile cleared=", ok)

--@api-stub: lurek.devtools.recordFrameTime
-- Records a frame-time sample (call each frame with delta time in seconds).
-- Call when you need to invoke record frame time.
local ok, result = pcall(function() return lurek.devtools.recordFrameTime(nil) end)
if ok then print("lurek.devtools.recordFrameTime ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.devtools.getFrameStats
-- Returns a table of computed frame statistics.
-- Call when you need to read frame stats.
local ok, value = pcall(function() return lurek.devtools.getFrameStats() end)
local v = ok and value or "(unavailable)"
print("lurek.devtools.getFrameStats ->", v)

--@api-stub: lurek.devtools.getFrameHistory
-- Returns the raw frame-time sample array.
-- Call when you need to read frame history.
local ok, value = pcall(function() return lurek.devtools.getFrameHistory() end)
local v = ok and value or "(unavailable)"
print("lurek.devtools.getFrameHistory ->", v)

--@api-stub: lurek.devtools.setFrameHistorySize
-- Sets the frame-history buffer capacity (clamped 10-10000).
-- Call when you need to assign frame history size.
local ok, err = pcall(function() lurek.devtools.setFrameHistorySize(10) end)
if not ok then print("set skipped:", err) end
print("lurek.devtools.setFrameHistorySize applied=", ok)

--@api-stub: lurek.devtools.getFrameHistorySize
-- Returns the current frame-history buffer capacity.
-- Call when you need to read frame history size.
local ok, value = pcall(function() return lurek.devtools.getFrameHistorySize() end)
local v = ok and value or "(unavailable)"
print("lurek.devtools.getFrameHistorySize ->", v)

--@api-stub: lurek.devtools.watch
-- Adds a file path to the watch list.
-- Returns false if already watched.
local ok, result = pcall(function() return lurek.devtools.watch("path") end)
if ok then print("lurek.devtools.watch ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.devtools.unwatch
-- Removes a file path from the watch list.
-- Call when you need to invoke unwatch.
local ok, result = pcall(function() return lurek.devtools.unwatch("path") end)
if ok then print("lurek.devtools.unwatch ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.devtools.getWatchedPaths
-- Returns an array of all watched paths.
-- Call when you need to read watched paths.
local ok, value = pcall(function() return lurek.devtools.getWatchedPaths() end)
local v = ok and value or "(unavailable)"
print("lurek.devtools.getWatchedPaths ->", v)

--@api-stub: lurek.devtools.scan
-- Polls all watched paths and returns paths whose mtime changed.
-- Call when you need to invoke scan.
local ok, result = pcall(function() return lurek.devtools.scan() end)
if ok then print("lurek.devtools.scan ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.devtools.clearWatches
-- Clears all watched paths.
-- Call when you need to invoke clear watches.
local ok, err = pcall(function() lurek.devtools.clearWatches() end)
if not ok then print("skipped:", err) end
print("lurek.devtools.clearWatches cleared=", ok)

--@api-stub: lurek.devtools.getWatchInterval
-- Returns the file watch poll interval in seconds.
-- Call when you need to read watch interval.
local ok, value = pcall(function() return lurek.devtools.getWatchInterval() end)
local v = ok and value or "(unavailable)"
print("lurek.devtools.getWatchInterval ->", v)

--@api-stub: lurek.devtools.setWatchInterval
-- Sets the file watch poll interval in seconds.
-- Call when you need to assign watch interval.
local ok, err = pcall(function() lurek.devtools.setWatchInterval(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.devtools.setWatchInterval applied=", ok)

--@api-stub: lurek.devtools.getCallStack
-- Returns the Lua call stack as a table of frames.
-- Call when you need to read call stack.
local ok, value = pcall(function() return lurek.devtools.getCallStack(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.devtools.getCallStack ->", v)

--@api-stub: lurek.devtools.eval
-- Evaluates a Lua string and returns (success, results...).
-- Call when you need to invoke eval.
local ok, result = pcall(function() return lurek.devtools.eval(nil) end)
if ok then print("lurek.devtools.eval ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.devtools.openConsole
-- Opens the console window (updates the console flag; returns true).
-- Call when you need to invoke open console.
local ok, obj = pcall(function() return lurek.devtools.openConsole() end)
if ok and obj then print("created:", obj) end
print("lurek.devtools.openConsole ok=", ok)

--@api-stub: lurek.devtools.isConsoleOpen
-- Returns whether the console is considered open.
-- Call when you need to check is console open.
local ok, result = pcall(function() return lurek.devtools.isConsoleOpen() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.devtools.isConsoleOpen ok=", ok)

--@api-stub: lurek.devtools.exposeWatch
-- Registers a named live watch.
-- The getter function is called on demand to sample a value.
local ok, result = pcall(function() return lurek.devtools.exposeWatch("name", nil, nil) end)
if ok then print("lurek.devtools.exposeWatch ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.devtools.removeWatch
-- Removes a watch by the id returned from exposeWatch.
-- Returns true if removed.
local ok, err = pcall(function() lurek.devtools.removeWatch(1) end)
if not ok then print("skipped:", err) end
print("lurek.devtools.removeWatch cleared=", ok)

--@api-stub: lurek.devtools.getWatches
-- Calls all registered watch getters and returns a table of {name, category, value} records.
-- Call when you need to read watches.
local ok, value = pcall(function() return lurek.devtools.getWatches() end)
local v = ok and value or "(unavailable)"
print("lurek.devtools.getWatches ->", v)

--@api-stub: lurek.devtools.snapshot
-- Takes a structured snapshot of all watches + frame stats + last profile frame.
-- Call when you need to invoke snapshot.
local ok, result = pcall(function() return lurek.devtools.snapshot() end)
if ok then print("lurek.devtools.snapshot ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.devtools.profilerReport
-- Returns a flat summary table of all recorded profiler zones across all stored.
-- Call when you need to invoke profiler report.
local ok, result = pcall(function() return lurek.devtools.profilerReport() end)
if ok then print("lurek.devtools.profilerReport ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.devtools.newFileWatcher
-- Creates a standalone per-path file watcher.
-- Call `:check()` once per frame.
local ok, obj = pcall(function() return lurek.devtools.newFileWatcher("path") end)
if ok and obj then print("created:", obj) end
print("lurek.devtools.newFileWatcher ok=", ok)

--@api-stub: lurek.devtools.newRepl
-- Creates an interactive Lua REPL console with a bounded history buffer.
-- Call when you need to create a new repl.
local ok, obj = pcall(function() return lurek.devtools.newRepl(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.devtools.newRepl ok=", ok)

-- ── FileWatcher methods ──

--@api-stub: FileWatcher:onChanged
-- Registers a callback invoked (with no arguments) when the watched path changes.
-- Call when you need to invoke on changed.
-- Build a FileWatcher via the appropriate lurek.devtools.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.devtools.newFileWatcher(...)
if instance then
  local ok, result = pcall(function() return instance:onChanged(function() end) end)
  print("FileWatcher:onChanged ->", ok, result)
end

--@api-stub: FileWatcher:check
-- Polls the watcher.
-- If the file has changed since the last call, fires the.
-- Build a FileWatcher via the appropriate lurek.devtools.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.devtools.newFileWatcher(...)
if instance then
  local ok, result = pcall(function() return instance:check() end)
  print("FileWatcher:check ->", ok, result)
end

--@api-stub: FileWatcher:getPath
-- Returns the watched path string.
-- Call when you need to read path.
-- Build a FileWatcher via the appropriate lurek.devtools.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.devtools.newFileWatcher(...)
if instance then
  local ok, result = pcall(function() return instance:getPath() end)
  print("FileWatcher:getPath ->", ok, result)
end

--@api-stub: FileWatcher:cancel
-- Removes the stored `onChanged` callback and stops future notifications.
-- Call when you need to invoke cancel.
-- Build a FileWatcher via the appropriate lurek.devtools.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.devtools.newFileWatcher(...)
if instance then
  local ok, result = pcall(function() return instance:cancel() end)
  print("FileWatcher:cancel ->", ok, result)
end

-- ── ReplConsole methods ──

--@api-stub: ReplConsole:eval
-- Evaluates a Lua snippet and records the input in history.
-- Call when you need to invoke eval.
-- Build a ReplConsole via the appropriate lurek.devtools.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.devtools.newReplConsole(...)
if instance then
  local ok, result = pcall(function() return instance:eval(nil) end)
  print("ReplConsole:eval ->", ok, result)
end

--@api-stub: ReplConsole:history
-- Returns an ordered array of past inputs (oldest first).
-- Call when you need to invoke history.
-- Build a ReplConsole via the appropriate lurek.devtools.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.devtools.newReplConsole(...)
if instance then
  local ok, result = pcall(function() return instance:history() end)
  print("ReplConsole:history ->", ok, result)
end

--@api-stub: ReplConsole:clear
-- Clears the REPL history buffer.
-- Call when you need to invoke clear.
-- Build a ReplConsole via the appropriate lurek.devtools.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.devtools.newReplConsole(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("ReplConsole:clear ->", ok, result)
end

--@api-stub: ReplConsole:len
-- Returns the number of history entries.
-- Call when you need to invoke len.
-- Build a ReplConsole via the appropriate lurek.devtools.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.devtools.newReplConsole(...)
if instance then
  local ok, result = pcall(function() return instance:len() end)
  print("ReplConsole:len ->", ok, result)
end

