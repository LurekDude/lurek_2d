-- content/examples/debugbridge.lua
-- Scaffolded coverage of the lurek.debugbridge API (14 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/debugbridge_api.rs   (Lua binding, arg types, return shape)
--   * src/debugbridge/                 (semantics, side effects)
--   * docs/specs/debugbridge.md        (canonical reference)
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
-- Run: cargo run -- content/examples/debugbridge.lua

-- ── lurek.debugbridge.* functions ──

--@api-stub: lurek.debugbridge.start
-- Start the TCP debug server on 127.0.0.1:port.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/debugbridge_api.rs and docs/specs/debugbridge.md).
do  -- TODO: lurek.debugbridge.start
  local _todo = "TODO: write a real lurek.debugbridge.start usage example"
  print(_todo)
end

--@api-stub: lurek.debugbridge.stop
-- Stop the TCP debug server and close all connections.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/debugbridge_api.rs and docs/specs/debugbridge.md).
do  -- TODO: lurek.debugbridge.stop
  local _todo = "TODO: write a real lurek.debugbridge.stop usage example"
  print(_todo)
end

--@api-stub: lurek.debugbridge.isRunning
-- Returns whether the server is currently running.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/debugbridge_api.rs and docs/specs/debugbridge.md).
do  -- TODO: lurek.debugbridge.isRunning
  local _todo = "TODO: write a real lurek.debugbridge.isRunning usage example"
  print(_todo)
end

--@api-stub: lurek.debugbridge.getPort
-- Returns the server port (0 if not running).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/debugbridge_api.rs and docs/specs/debugbridge.md).
do  -- TODO: lurek.debugbridge.getPort
  local _todo = "TODO: write a real lurek.debugbridge.getPort usage example"
  print(_todo)
end

--@api-stub: lurek.debugbridge.getClientCount
-- Returns the number of connected TCP clients.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/debugbridge_api.rs and docs/specs/debugbridge.md).
do  -- TODO: lurek.debugbridge.getClientCount
  local _todo = "TODO: write a real lurek.debugbridge.getClientCount usage example"
  print(_todo)
end

--@api-stub: lurek.debugbridge.poll
-- Poll for pending Lua-dependent requests from TCP clients.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/debugbridge_api.rs and docs/specs/debugbridge.md).
do  -- TODO: lurek.debugbridge.poll
  local _todo = "TODO: write a real lurek.debugbridge.poll usage example"
  print(_todo)
end

--@api-stub: lurek.debugbridge.capturePrint
-- Captures a print message and broadcasts it to connected clients.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/debugbridge_api.rs and docs/specs/debugbridge.md).
do  -- TODO: lurek.debugbridge.capturePrint
  local _todo = "TODO: write a real lurek.debugbridge.capturePrint usage example"
  print(_todo)
end

--@api-stub: lurek.debugbridge.getPrintHistory
-- Returns the print history.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/debugbridge_api.rs and docs/specs/debugbridge.md).
do  -- TODO: lurek.debugbridge.getPrintHistory
  local _todo = "TODO: write a real lurek.debugbridge.getPrintHistory usage example"
  print(_todo)
end

--@api-stub: lurek.debugbridge.clearPrintHistory
-- Clears the print history.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/debugbridge_api.rs and docs/specs/debugbridge.md).
do  -- TODO: lurek.debugbridge.clearPrintHistory
  local _todo = "TODO: write a real lurek.debugbridge.clearPrintHistory usage example"
  print(_todo)
end

--@api-stub: lurek.debugbridge.setMaxPrintHistory
-- Sets the maximum print history size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/debugbridge_api.rs and docs/specs/debugbridge.md).
do  -- TODO: lurek.debugbridge.setMaxPrintHistory
  local _todo = "TODO: write a real lurek.debugbridge.setMaxPrintHistory usage example"
  print(_todo)
end

--@api-stub: lurek.debugbridge.getPerformance
-- Returns performance statistics.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/debugbridge_api.rs and docs/specs/debugbridge.md).
do  -- TODO: lurek.debugbridge.getPerformance
  local _todo = "TODO: write a real lurek.debugbridge.getPerformance usage example"
  print(_todo)
end

--@api-stub: lurek.debugbridge.requestScreenshot
-- Flags a screenshot request for the next frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/debugbridge_api.rs and docs/specs/debugbridge.md).
do  -- TODO: lurek.debugbridge.requestScreenshot
  local _todo = "TODO: write a real lurek.debugbridge.requestScreenshot usage example"
  print(_todo)
end

--@api-stub: lurek.debugbridge.isScreenshotRequested
-- Returns whether a screenshot is currently requested.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/debugbridge_api.rs and docs/specs/debugbridge.md).
do  -- TODO: lurek.debugbridge.isScreenshotRequested
  local _todo = "TODO: write a real lurek.debugbridge.isScreenshotRequested usage example"
  print(_todo)
end

--@api-stub: lurek.debugbridge.broadcast
-- Broadcasts a JSON event to all connected clients.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/debugbridge_api.rs and docs/specs/debugbridge.md).
do  -- TODO: lurek.debugbridge.broadcast
  local _todo = "TODO: write a real lurek.debugbridge.broadcast usage example"
  print(_todo)
end

