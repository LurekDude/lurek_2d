-- content/examples/log.lua
-- Scaffolded coverage of the lurek.log API (18 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/log_api.rs   (Lua binding, arg types, return shape)
--   * src/log/                 (semantics, side effects)
--   * docs/specs/log.md        (canonical reference)
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
-- Run: cargo run -- content/examples/log.lua

-- ── lurek.log.* functions ──

--@api-stub: lurek.log.debug
-- Emits a debug-severity log message.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.debug
  local _todo = "TODO: write a real lurek.log.debug usage example"
  print(_todo)
end

--@api-stub: lurek.log.info
-- Emits an info-severity log message.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.info
  local _todo = "TODO: write a real lurek.log.info usage example"
  print(_todo)
end

--@api-stub: lurek.log.warn
-- Emits a warn-severity log message.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.warn
  local _todo = "TODO: write a real lurek.log.warn usage example"
  print(_todo)
end

--@api-stub: lurek.log.error
-- Emits an error-severity log message.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.error
  local _todo = "TODO: write a real lurek.log.error usage example"
  print(_todo)
end

--@api-stub: lurek.log.print
-- Emits a log message at the specified level.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.print
  local _todo = "TODO: write a real lurek.log.print usage example"
  print(_todo)
end

--@api-stub: lurek.log.setLevel
-- Sets the minimum severity level for the default log channel.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.setLevel
  local _todo = "TODO: write a real lurek.log.setLevel usage example"
  print(_todo)
end

--@api-stub: lurek.log.getLevel
-- Returns the name of the currently active minimum log level.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.getLevel
  local _todo = "TODO: write a real lurek.log.getLevel usage example"
  print(_todo)
end

--@api-stub: lurek.log.addSink
-- Registers a new output sink.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.addSink
  local _todo = "TODO: write a real lurek.log.addSink usage example"
  print(_todo)
end

--@api-stub: lurek.log.removeSink
-- Removes a sink by id.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.removeSink
  local _todo = "TODO: write a real lurek.log.removeSink usage example"
  print(_todo)
end

--@api-stub: lurek.log.clearSinks
-- Removes all registered sinks (the default stderr channel is unaffected).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.clearSinks
  local _todo = "TODO: write a real lurek.log.clearSinks usage example"
  print(_todo)
end

--@api-stub: lurek.log.listSinks
-- Returns a table describing all registered sinks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.listSinks
  local _todo = "TODO: write a real lurek.log.listSinks usage example"
  print(_todo)
end

--@api-stub: lurek.log.readMemory
-- Reads entries from a memory sink.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.readMemory
  local _todo = "TODO: write a real lurek.log.readMemory usage example"
  print(_todo)
end

--@api-stub: lurek.log.flushFile
-- Flushes the OS write buffer for a file sink.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.flushFile
  local _todo = "TODO: write a real lurek.log.flushFile usage example"
  print(_todo)
end

--@api-stub: lurek.log.struct
-- Emits a structured log message with key-value fields.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.struct
  local _todo = "TODO: write a real lurek.log.struct usage example"
  print(_todo)
end

--@api-stub: lurek.log.debug_fields
-- Emits a debug structured log message.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.debug_fields
  local _todo = "TODO: write a real lurek.log.debug_fields usage example"
  print(_todo)
end

--@api-stub: lurek.log.info_fields
-- Emits an info structured log message.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.info_fields
  local _todo = "TODO: write a real lurek.log.info_fields usage example"
  print(_todo)
end

--@api-stub: lurek.log.warn_fields
-- Emits a warn structured log message.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.warn_fields
  local _todo = "TODO: write a real lurek.log.warn_fields usage example"
  print(_todo)
end

--@api-stub: lurek.log.error_fields
-- Emits an error structured log message.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/log_api.rs and docs/specs/log.md).
do  -- TODO: lurek.log.error_fields
  local _todo = "TODO: write a real lurek.log.error_fields usage example"
  print(_todo)
end

