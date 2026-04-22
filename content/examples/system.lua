-- content/examples/system.lua
-- Scaffolded coverage of the lurek.system API (26 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/system_api.rs   (Lua binding, arg types, return shape)
--   * src/system/                 (semantics, side effects)
--   * docs/specs/system.md        (canonical reference)
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
-- Run: cargo run -- content/examples/system.lua

-- ── lurek.system.* functions ──

--@api-stub: lurek.system.getOS
-- Returns the host operating system name ('Windows', 'Linux', 'macOS').
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getOS
  local _todo = "TODO: write a real lurek.system.getOS usage example"
  print(_todo)
end

--@api-stub: lurek.system.getVersion
-- Returns the Lurek2D engine version string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getVersion
  local _todo = "TODO: write a real lurek.system.getVersion usage example"
  print(_todo)
end

--@api-stub: lurek.system.getProcessorCount
-- Returns the number of logical CPU cores available.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getProcessorCount
  local _todo = "TODO: write a real lurek.system.getProcessorCount usage example"
  print(_todo)
end

--@api-stub: lurek.system.getMemorySize
-- Returns the total amount of installed system RAM in megabytes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getMemorySize
  local _todo = "TODO: write a real lurek.system.getMemorySize usage example"
  print(_todo)
end

--@api-stub: lurek.system.openURL
-- Opens a URL in the system's default browser.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.openURL
  local _todo = "TODO: write a real lurek.system.openURL usage example"
  print(_todo)
end

--@api-stub: lurek.system.getPreferredLocales
-- Returns an ordered list of the user's preferred locale strings (e.g.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getPreferredLocales
  local _todo = "TODO: write a real lurek.system.getPreferredLocales usage example"
  print(_todo)
end

--@api-stub: lurek.system.getPowerInfo
-- Returns battery state, percentage charged, and estimated time remaining.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getPowerInfo
  local _todo = "TODO: write a real lurek.system.getPowerInfo usage example"
  print(_todo)
end

--@api-stub: lurek.system.getInfo
-- Returns a table of system information including OS name, CPU model, and installed RAM.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getInfo
  local _todo = "TODO: write a real lurek.system.getInfo usage example"
  print(_todo)
end

--@api-stub: lurek.system.getMessage
-- Resolves a stable runtime message ID such as 'L001' to its human-readable text.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getMessage
  local _todo = "TODO: write a real lurek.system.getMessage usage example"
  print(_todo)
end

--@api-stub: lurek.system.hasMessage
-- Returns true when the runtime message catalog contains the given stable message ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.hasMessage
  local _todo = "TODO: write a real lurek.system.hasMessage usage example"
  print(_todo)
end

--@api-stub: lurek.system.getMessageCount
-- Returns the total number of message entries loaded into the runtime message catalog.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getMessageCount
  local _todo = "TODO: write a real lurek.system.getMessageCount usage example"
  print(_todo)
end

--@api-stub: lurek.system.setClipboardText
-- Replaces the system clipboard contents with the given string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.setClipboardText
  local _todo = "TODO: write a real lurek.system.setClipboardText usage example"
  print(_todo)
end

--@api-stub: lurek.system.getClipboardText
-- Returns the current contents of the system clipboard.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getClipboardText
  local _todo = "TODO: write a real lurek.system.getClipboardText usage example"
  print(_todo)
end

--@api-stub: lurek.system.setDebugOverlay
-- Shows or hides the FPS/draw-call debug overlay.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.setDebugOverlay
  local _todo = "TODO: write a real lurek.system.setDebugOverlay usage example"
  print(_todo)
end

--@api-stub: lurek.system.getDebugOverlay
-- Returns whether the debug overlay is currently visible.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getDebugOverlay
  local _todo = "TODO: write a real lurek.system.getDebugOverlay usage example"
  print(_todo)
end

--@api-stub: lurek.system.setLogLevel
-- Sets the minimum severity level for runtime log messages.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.setLogLevel
  local _todo = "TODO: write a real lurek.system.setLogLevel usage example"
  print(_todo)
end

--@api-stub: lurek.system.getLogLevel
-- Returns the name of the current minimum log level for runtime messages.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getLogLevel
  local _todo = "TODO: write a real lurek.system.getLogLevel usage example"
  print(_todo)
end

--@api-stub: lurek.system.log
-- Emit a log message from Lua at the specified level.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.log
  local _todo = "TODO: write a real lurek.system.log usage example"
  print(_todo)
end

--@api-stub: lurek.system.getLastError
-- Returns the last unhandled error message, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getLastError
  local _todo = "TODO: write a real lurek.system.getLastError usage example"
  print(_todo)
end

--@api-stub: lurek.system.errorSnapshot
-- Serialises an engine error message to a compact JSON string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.errorSnapshot
  local _todo = "TODO: write a real lurek.system.errorSnapshot usage example"
  print(_todo)
end

--@api-stub: lurek.system.getArch
-- Returns the CPU architecture string for the current machine.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getArch
  local _todo = "TODO: write a real lurek.system.getArch usage example"
  print(_todo)
end

--@api-stub: lurek.system.getEnv
-- Returns the value of an environment variable, or nil if not set.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getEnv
  local _todo = "TODO: write a real lurek.system.getEnv usage example"
  print(_todo)
end

--@api-stub: lurek.system.getArgs
-- Returns the command-line arguments as a table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getArgs
  local _todo = "TODO: write a real lurek.system.getArgs usage example"
  print(_todo)
end

--@api-stub: lurek.system.parseArgs
-- Parses a command-line argument string and returns a structured key/value table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.parseArgs
  local _todo = "TODO: write a real lurek.system.parseArgs usage example"
  print(_todo)
end

--@api-stub: lurek.system.runBatch
-- Runs a list of shell commands in parallel and returns immediately without blocking.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.runBatch
  local _todo = "TODO: write a real lurek.system.runBatch usage example"
  print(_todo)
end

--@api-stub: lurek.system.getBatchResults
-- Returns the output table from the most recently completed runBatch call.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/system_api.rs and docs/specs/system.md).
do  -- TODO: lurek.system.getBatchResults
  local _todo = "TODO: write a real lurek.system.getBatchResults usage example"
  print(_todo)
end

