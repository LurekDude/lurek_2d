-- content/examples/devtools.lua
-- Scaffolded coverage of the lurek.devtools API (48 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/devtools_api.rs   (Lua binding, arg types, return shape)
--   * src/devtools/                 (semantics, side effects)
--   * docs/specs/devtools.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/devtools.lua

-- ── lurek.devtools.* functions ──

--@api-stub: lurek.devtools.log
-- Logs a message at the given level.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.log
  local _todo = "TODO: write a real lurek.devtools.log usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.setLogLevel
-- Sets the minimum log level.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.setLogLevel
  local _todo = "TODO: write a real lurek.devtools.setLogLevel usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.getLogLevel
-- Returns the current minimum log level.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.getLogLevel
  local _todo = "TODO: write a real lurek.devtools.getLogLevel usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.setLogConsole
-- Enables or disables console log output.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.setLogConsole
  local _todo = "TODO: write a real lurek.devtools.setLogConsole usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.getLogConsole
-- Returns whether console log output is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.getLogConsole
  local _todo = "TODO: write a real lurek.devtools.getLogConsole usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.setLogFile
-- Sets the log file path (empty string disables file output).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.setLogFile
  local _todo = "TODO: write a real lurek.devtools.setLogFile usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.getLogFile
-- Returns the current log file path.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.getLogFile
  local _todo = "TODO: write a real lurek.devtools.getLogFile usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.getLogHistory
-- Returns recent log entries as an array of tables.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.getLogHistory
  local _todo = "TODO: write a real lurek.devtools.getLogHistory usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.clearLog
-- Discards all accumulated log entries from the in-memory devtools log buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.clearLog
  local _todo = "TODO: write a real lurek.devtools.clearLog usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.setProfilingEnabled
-- Enables or disables the profiler.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.setProfilingEnabled
  local _todo = "TODO: write a real lurek.devtools.setProfilingEnabled usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.isProfilingEnabled
-- Returns whether the profiler is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.isProfilingEnabled
  local _todo = "TODO: write a real lurek.devtools.isProfilingEnabled usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.profilePush
-- Opens a named profiling zone on the stack.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.profilePush
  local _todo = "TODO: write a real lurek.devtools.profilePush usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.profilePop
-- Closes the most recent profiling zone.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.profilePop
  local _todo = "TODO: write a real lurek.devtools.profilePop usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.profileFrame
-- Seals the current frame of profiling data.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.profileFrame
  local _todo = "TODO: write a real lurek.devtools.profileFrame usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.getProfileFrameCount
-- Returns the number of retained profile frames.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.getProfileFrameCount
  local _todo = "TODO: write a real lurek.devtools.getProfileFrameCount usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.getProfileData
-- Returns zone data table for a specific frame (0 or nil = most recent).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.getProfileData
  local _todo = "TODO: write a real lurek.devtools.getProfileData usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.resetProfile
-- Clears all profiling data and resets the zone stack.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.resetProfile
  local _todo = "TODO: write a real lurek.devtools.resetProfile usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.recordFrameTime
-- Records a frame-time sample (call each frame with delta time in seconds).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.recordFrameTime
  local _todo = "TODO: write a real lurek.devtools.recordFrameTime usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.getFrameStats
-- Returns a table of computed frame statistics.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.getFrameStats
  local _todo = "TODO: write a real lurek.devtools.getFrameStats usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.getFrameHistory
-- Returns the raw frame-time sample array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.getFrameHistory
  local _todo = "TODO: write a real lurek.devtools.getFrameHistory usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.setFrameHistorySize
-- Sets the frame-history buffer capacity (clamped 10-10000).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.setFrameHistorySize
  local _todo = "TODO: write a real lurek.devtools.setFrameHistorySize usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.getFrameHistorySize
-- Returns the current frame-history buffer capacity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.getFrameHistorySize
  local _todo = "TODO: write a real lurek.devtools.getFrameHistorySize usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.watch
-- Adds a file path to the watch list.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.watch
  local _todo = "TODO: write a real lurek.devtools.watch usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.unwatch
-- Removes a file path from the watch list.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.unwatch
  local _todo = "TODO: write a real lurek.devtools.unwatch usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.getWatchedPaths
-- Returns an array of all watched paths.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.getWatchedPaths
  local _todo = "TODO: write a real lurek.devtools.getWatchedPaths usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.scan
-- Polls all watched paths and returns paths whose mtime changed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.scan
  local _todo = "TODO: write a real lurek.devtools.scan usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.clearWatches
-- Clears all watched paths.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.clearWatches
  local _todo = "TODO: write a real lurek.devtools.clearWatches usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.getWatchInterval
-- Returns the file watch poll interval in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.getWatchInterval
  local _todo = "TODO: write a real lurek.devtools.getWatchInterval usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.setWatchInterval
-- Sets the file watch poll interval in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.setWatchInterval
  local _todo = "TODO: write a real lurek.devtools.setWatchInterval usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.getCallStack
-- Returns the Lua call stack as a table of frames.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.getCallStack
  local _todo = "TODO: write a real lurek.devtools.getCallStack usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.eval
-- Evaluates a Lua string and returns (success, results...).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.eval
  local _todo = "TODO: write a real lurek.devtools.eval usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.openConsole
-- Opens the console window (updates the console flag; returns true).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.openConsole
  local _todo = "TODO: write a real lurek.devtools.openConsole usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.isConsoleOpen
-- Returns whether the console is considered open.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.isConsoleOpen
  local _todo = "TODO: write a real lurek.devtools.isConsoleOpen usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.exposeWatch
-- Registers a named live watch.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.exposeWatch
  local _todo = "TODO: write a real lurek.devtools.exposeWatch usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.removeWatch
-- Removes a watch by the id returned from exposeWatch.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.removeWatch
  local _todo = "TODO: write a real lurek.devtools.removeWatch usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.getWatches
-- Calls all registered watch getters and returns a table of {name, category, value} records.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.getWatches
  local _todo = "TODO: write a real lurek.devtools.getWatches usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.snapshot
-- Takes a structured snapshot of all watches + frame stats + last profile frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.snapshot
  local _todo = "TODO: write a real lurek.devtools.snapshot usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.profilerReport
-- Returns a flat summary table of all recorded profiler zones across all stored.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.profilerReport
  local _todo = "TODO: write a real lurek.devtools.profilerReport usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.newFileWatcher
-- Creates a standalone per-path file watcher.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.newFileWatcher
  local _todo = "TODO: write a real lurek.devtools.newFileWatcher usage example"
  print(_todo)
end

--@api-stub: lurek.devtools.newRepl
-- Creates an interactive Lua REPL console with a bounded history buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: lurek.devtools.newRepl
  local _todo = "TODO: write a real lurek.devtools.newRepl usage example"
  print(_todo)
end

-- ── FileWatcher methods ──

--@api-stub: FileWatcher:onChanged
-- Registers a callback invoked (with no arguments) when the watched path changes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: FileWatcher:onChanged
  local _todo = "TODO: write a real FileWatcher:onChanged usage example"
  print(_todo)
end

--@api-stub: FileWatcher:check
-- Polls the watcher.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: FileWatcher:check
  local _todo = "TODO: write a real FileWatcher:check usage example"
  print(_todo)
end

--@api-stub: FileWatcher:getPath
-- Returns the watched path string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: FileWatcher:getPath
  local _todo = "TODO: write a real FileWatcher:getPath usage example"
  print(_todo)
end

--@api-stub: FileWatcher:cancel
-- Removes the stored `onChanged` callback and stops future notifications.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: FileWatcher:cancel
  local _todo = "TODO: write a real FileWatcher:cancel usage example"
  print(_todo)
end

-- ── ReplConsole methods ──

--@api-stub: ReplConsole:eval
-- Evaluates a Lua snippet and records the input in history.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: ReplConsole:eval
  local _todo = "TODO: write a real ReplConsole:eval usage example"
  print(_todo)
end

--@api-stub: ReplConsole:history
-- Returns an ordered array of past inputs (oldest first).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: ReplConsole:history
  local _todo = "TODO: write a real ReplConsole:history usage example"
  print(_todo)
end

--@api-stub: ReplConsole:clear
-- Clears the REPL history buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: ReplConsole:clear
  local _todo = "TODO: write a real ReplConsole:clear usage example"
  print(_todo)
end

--@api-stub: ReplConsole:len
-- Returns the number of history entries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/devtools_api.rs and docs/specs/devtools.md).
do  -- TODO: ReplConsole:len
  local _todo = "TODO: write a real ReplConsole:len usage example"
  print(_todo)
end

