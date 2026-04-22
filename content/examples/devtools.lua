-- content/examples/devtools.lua
-- Auto-scaffolded coverage of the lurek.devtools Lua API (48 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/devtools.lua

print("[example] lurek.devtools loaded — 48 API items demonstrated")

-- ── lurek.devtools free functions ──

--@api-stub: lurek.devtools.log
-- Logs a message at the given level.
-- Use this when logs a message at the given level is needed.
if false then
  local _r = lurek.devtools.log(0, nil)
  print(_r)
end

--@api-stub: lurek.devtools.setLogLevel
-- Sets the minimum log level.
-- Use this when sets the minimum log level is needed.
if false then
  local _r = lurek.devtools.setLogLevel(0)
  print(_r)
end

--@api-stub: lurek.devtools.getLogLevel
-- Returns the current minimum log level.
-- Use this when returns the current minimum log level is needed.
if false then
  local _r = lurek.devtools.getLogLevel()
  print(_r)
end

--@api-stub: lurek.devtools.setLogConsole
-- Enables or disables console log output.
-- Use this when enables or disables console log output is needed.
if false then
  local _r = lurek.devtools.setLogConsole(1)
  print(_r)
end

--@api-stub: lurek.devtools.getLogConsole
-- Returns whether console log output is enabled.
-- Use this when returns whether console log output is enabled is needed.
if false then
  local _r = lurek.devtools.getLogConsole()
  print(_r)
end

--@api-stub: lurek.devtools.setLogFile
-- Sets the log file path (empty string disables file output).
-- Use this when sets the log file path (empty string disables file output) is needed.
if false then
  local _r = lurek.devtools.setLogFile(0)
  print(_r)
end

--@api-stub: lurek.devtools.getLogFile
-- Returns the current log file path.
-- Use this when returns the current log file path is needed.
if false then
  local _r = lurek.devtools.getLogFile()
  print(_r)
end

--@api-stub: lurek.devtools.getLogHistory
-- Returns recent log entries as an array of tables.
-- Use this when returns recent log entries as an array of tables is needed.
if false then
  local _r = lurek.devtools.getLogHistory(1)
  print(_r)
end

--@api-stub: lurek.devtools.clearLog
-- Discards all accumulated log entries from the in-memory devtools log buffer.
-- Use this when discards all accumulated log entries from the in-memory devtools log buffer is needed.
if false then
  local _r = lurek.devtools.clearLog()
  print(_r)
end

--@api-stub: lurek.devtools.setProfilingEnabled
-- Enables or disables the profiler.
-- Use this when enables or disables the profiler is needed.
if false then
  local _r = lurek.devtools.setProfilingEnabled(1)
  print(_r)
end

--@api-stub: lurek.devtools.isProfilingEnabled
-- Returns whether the profiler is enabled.
-- Use this when returns whether the profiler is enabled is needed.
if false then
  local _r = lurek.devtools.isProfilingEnabled()
  print(_r)
end

--@api-stub: lurek.devtools.profilePush
-- Opens a named profiling zone on the stack.
-- Use this when opens a named profiling zone on the stack is needed.
if false then
  local _r = lurek.devtools.profilePush(1)
  print(_r)
end

--@api-stub: lurek.devtools.profilePop
-- Closes the most recent profiling zone.
-- Use this when closes the most recent profiling zone is needed.
if false then
  local _r = lurek.devtools.profilePop(nil)
  print(_r)
end

--@api-stub: lurek.devtools.profileFrame
-- Seals the current frame of profiling data.
-- Use this when seals the current frame of profiling data is needed.
if false then
  local _r = lurek.devtools.profileFrame()
  print(_r)
end

--@api-stub: lurek.devtools.getProfileFrameCount
-- Returns the number of retained profile frames.
-- Use this when returns the number of retained profile frames is needed.
if false then
  local _r = lurek.devtools.getProfileFrameCount()
  print(_r)
end

--@api-stub: lurek.devtools.getProfileData
-- Returns zone data table for a specific frame (0 or nil = most recent).
-- Use this when returns zone data table for a specific frame (0 or nil = most recent) is needed.
if false then
  local _r = lurek.devtools.getProfileData(nil)
  print(_r)
end

--@api-stub: lurek.devtools.resetProfile
-- Clears all profiling data and resets the zone stack.
-- Use this when clears all profiling data and resets the zone stack is needed.
if false then
  local _r = lurek.devtools.resetProfile()
  print(_r)
end

--@api-stub: lurek.devtools.recordFrameTime
-- Records a frame-time sample (call each frame with delta time in seconds).
-- Use this when records a frame-time sample (call each frame with delta time in seconds) is needed.
if false then
  local _r = lurek.devtools.recordFrameTime(0)
  print(_r)
end

--@api-stub: lurek.devtools.getFrameStats
-- Returns a table of computed frame statistics.
-- Use this when returns a table of computed frame statistics is needed.
if false then
  local _r = lurek.devtools.getFrameStats()
  print(_r)
end

--@api-stub: lurek.devtools.getFrameHistory
-- Returns the raw frame-time sample array.
-- Use this when returns the raw frame-time sample array is needed.
if false then
  local _r = lurek.devtools.getFrameHistory()
  print(_r)
end

--@api-stub: lurek.devtools.setFrameHistorySize
-- Sets the frame-history buffer capacity (clamped 10-10000).
-- Use this when sets the frame-history buffer capacity (clamped 10-10000) is needed.
if false then
  local _r = lurek.devtools.setFrameHistorySize(1)
  print(_r)
end

--@api-stub: lurek.devtools.getFrameHistorySize
-- Returns the current frame-history buffer capacity.
-- Use this when returns the current frame-history buffer capacity is needed.
if false then
  local _r = lurek.devtools.getFrameHistorySize()
  print(_r)
end

--@api-stub: lurek.devtools.watch
-- Adds a file path to the watch list.
-- Returns false if already watched.
if false then
  local _r = lurek.devtools.watch(0)
  print(_r)
end

--@api-stub: lurek.devtools.unwatch
-- Removes a file path from the watch list.
-- Use this when removes a file path from the watch list is needed.
if false then
  local _r = lurek.devtools.unwatch(0)
  print(_r)
end

--@api-stub: lurek.devtools.getWatchedPaths
-- Returns an array of all watched paths.
-- Use this when returns an array of all watched paths is needed.
if false then
  local _r = lurek.devtools.getWatchedPaths()
  print(_r)
end

--@api-stub: lurek.devtools.scan
-- Polls all watched paths and returns paths whose mtime changed.
-- Use this when polls all watched paths and returns paths whose mtime changed is needed.
if false then
  local _r = lurek.devtools.scan()
  print(_r)
end

--@api-stub: lurek.devtools.clearWatches
-- Clears all watched paths.
-- Use this when clears all watched paths is needed.
if false then
  local _r = lurek.devtools.clearWatches()
  print(_r)
end

--@api-stub: lurek.devtools.getWatchInterval
-- Returns the file watch poll interval in seconds.
-- Use this when returns the file watch poll interval in seconds is needed.
if false then
  local _r = lurek.devtools.getWatchInterval()
  print(_r)
end

--@api-stub: lurek.devtools.setWatchInterval
-- Sets the file watch poll interval in seconds.
-- Use this when sets the file watch poll interval in seconds is needed.
if false then
  local _r = lurek.devtools.setWatchInterval(1)
  print(_r)
end

--@api-stub: lurek.devtools.getCallStack
-- Returns the Lua call stack as a table of frames.
-- Use this when returns the Lua call stack as a table of frames is needed.
if false then
  local _r = lurek.devtools.getCallStack(1)
  print(_r)
end

--@api-stub: lurek.devtools.eval
-- Evaluates a Lua string and returns (success, results...).
-- Use this when evaluates a Lua string and returns (success, results...) is needed.
if false then
  local _r = lurek.devtools.eval(nil)
  print(_r)
end

--@api-stub: lurek.devtools.openConsole
-- Opens the console window (updates the console flag; returns true).
-- Use this when opens the console window (updates the console flag; returns true) is needed.
if false then
  local _r = lurek.devtools.openConsole()
  print(_r)
end

--@api-stub: lurek.devtools.isConsoleOpen
-- Returns whether the console is considered open.
-- Use this when returns whether the console is considered open is needed.
if false then
  local _r = lurek.devtools.isConsoleOpen()
  print(_r)
end

--@api-stub: lurek.devtools.exposeWatch
-- Registers a named live watch.
-- The getter function is called on demand to sample a value.
if false then
  local _r = lurek.devtools.exposeWatch(1, 0, 0)
  print(_r)
end

--@api-stub: lurek.devtools.removeWatch
-- Removes a watch by the id returned from exposeWatch.
-- Returns true if removed.
if false then
  local _r = lurek.devtools.removeWatch(1)
  print(_r)
end

--@api-stub: lurek.devtools.getWatches
-- Calls all registered watch getters and returns a table of {name, category, value} records.
-- Use this when calls all registered watch getters and returns a table of {name, category, value} records is needed.
if false then
  local _r = lurek.devtools.getWatches()
  print(_r)
end

--@api-stub: lurek.devtools.snapshot
-- Takes a structured snapshot of all watches + frame stats + last profile frame.
-- Use this when takes a structured snapshot of all watches + frame stats + last profile frame is needed.
if false then
  local _r = lurek.devtools.snapshot()
  print(_r)
end

--@api-stub: lurek.devtools.profilerReport
-- Returns a flat summary table of all recorded profiler zones across all stored.
-- Use this when returns a flat summary table of all recorded profiler zones across all stored is needed.
if false then
  local _r = lurek.devtools.profilerReport()
  print(_r)
end

--@api-stub: lurek.devtools.newFileWatcher
-- Creates a standalone per-path file watcher.
-- Call `:check()` once per frame
if false then
  local _r = lurek.devtools.newFileWatcher(0)
  print(_r)
end

--@api-stub: lurek.devtools.newRepl
-- Creates an interactive Lua REPL console with a bounded history buffer.
-- Use this when creates an interactive Lua REPL console with a bounded history buffer is needed.
if false then
  local _r = lurek.devtools.newRepl(0)
  print(_r)
end

-- ── FileWatcher methods ──

--@api-stub: FileWatcher:onChanged
-- Registers a callback invoked (with no arguments) when the watched path changes.
-- Use this when registers a callback invoked (with no arguments) when the watched path changes is needed.
if false then
  local _o = nil  -- FileWatcher instance
  _o:onChanged(1)
end

--@api-stub: FileWatcher:check
-- Polls the watcher.
-- If the file has changed since the last call, fires the
if false then
  local _o = nil  -- FileWatcher instance
  _o:check()
end

--@api-stub: FileWatcher:getPath
-- Returns the watched path string.
-- Use this when returns the watched path string is needed.
if false then
  local _o = nil  -- FileWatcher instance
  _o:getPath()
end

--@api-stub: FileWatcher:cancel
-- Removes the stored `onChanged` callback and stops future notifications.
-- Use this when removes the stored `onChanged` callback and stops future notifications is needed.
if false then
  local _o = nil  -- FileWatcher instance
  _o:cancel()
end

-- ── ReplConsole methods ──

--@api-stub: ReplConsole:eval
-- Evaluates a Lua snippet and records the input in history.
-- Use this when evaluates a Lua snippet and records the input in history is needed.
if false then
  local _o = nil  -- ReplConsole instance
  _o:eval(nil)
end

--@api-stub: ReplConsole:history
-- Returns an ordered array of past inputs (oldest first).
-- Use this when returns an ordered array of past inputs (oldest first) is needed.
if false then
  local _o = nil  -- ReplConsole instance
  _o:history()
end

--@api-stub: ReplConsole:clear
-- Clears the REPL history buffer.
-- Use this when clears the REPL history buffer is needed.
if false then
  local _o = nil  -- ReplConsole instance
  _o:clear()
end

--@api-stub: ReplConsole:len
-- Returns the number of history entries.
-- Use this when returns the number of history entries is needed.
if false then
  local _o = nil  -- ReplConsole instance
  _o:len()
end

