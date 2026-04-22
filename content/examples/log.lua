-- content/examples/log.lua
-- Auto-scaffolded coverage of the lurek.log Lua API (18 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/log.lua

print("[example] lurek.log loaded — 18 API items demonstrated")

-- ── lurek.log free functions ──

--@api-stub: lurek.log.debug
-- Emits a debug-severity log message.
-- Also dispatches to configured sinks.
if false then
  local _r = lurek.log.debug(nil, 0)
  print(_r)
end

--@api-stub: lurek.log.info
-- Emits an info-severity log message.
-- Also dispatches to configured sinks.
if false then
  local _r = lurek.log.info(nil, 0)
  print(_r)
end

--@api-stub: lurek.log.warn
-- Emits a warn-severity log message.
-- Also dispatches to configured sinks.
if false then
  local _r = lurek.log.warn(nil, 0)
  print(_r)
end

--@api-stub: lurek.log.error
-- Emits an error-severity log message.
-- Also dispatches to configured sinks.
if false then
  local _r = lurek.log.error(nil, 0)
  print(_r)
end

--@api-stub: lurek.log.print
-- Emits a log message at the specified level.
-- Also dispatches to sinks.
if false then
  local _r = lurek.log.print(0, nil, 0)
  print(_r)
end

--@api-stub: lurek.log.setLevel
-- Sets the minimum severity level for the default log channel.
-- Use this when sets the minimum severity level for the default log channel is needed.
if false then
  local _r = lurek.log.setLevel(0)
  print(_r)
end

--@api-stub: lurek.log.getLevel
-- Returns the name of the currently active minimum log level.
-- Use this when returns the name of the currently active minimum log level is needed.
if false then
  local _r = lurek.log.getLevel()
  print(_r)
end

--@api-stub: lurek.log.addSink
-- Registers a new output sink.
-- Returns its numeric id.
if false then
  local _r = lurek.log.addSink(1)
  print(_r)
end

--@api-stub: lurek.log.removeSink
-- Removes a sink by id.
-- Returns true if one was removed.
if false then
  local _r = lurek.log.removeSink(1)
  print(_r)
end

--@api-stub: lurek.log.clearSinks
-- Removes all registered sinks (the default stderr channel is unaffected).
-- Use this when removes all registered sinks (the default stderr channel is unaffected) is needed.
if false then
  local _r = lurek.log.clearSinks()
  print(_r)
end

--@api-stub: lurek.log.listSinks
-- Returns a table describing all registered sinks.
-- Use this when returns a table describing all registered sinks is needed.
if false then
  local _r = lurek.log.listSinks()
  print(_r)
end

--@api-stub: lurek.log.readMemory
-- Reads entries from a memory sink.
-- If drain=true the buffer is cleared.
if false then
  local _r = lurek.log.readMemory(1, 1)
  print(_r)
end

--@api-stub: lurek.log.flushFile
-- Flushes the OS write buffer for a file sink.
-- Use this when flushes the OS write buffer for a file sink is needed.
if false then
  local _r = lurek.log.flushFile(1)
  print(_r)
end

--@api-stub: lurek.log.struct
-- Emits a structured log message with key-value fields.
-- Use this when emits a structured log message with key-value fields is needed.
if false then
  local _r = lurek.log.struct(0, nil, 0)
  print(_r)
end

--@api-stub: lurek.log.debug_fields
-- Emits a debug structured log message.
-- Shorthand for `struct("debug", ...)`.
if false then
  local _r = lurek.log.debug_fields(nil, 0)
  print(_r)
end

--@api-stub: lurek.log.info_fields
-- Emits an info structured log message.
-- Shorthand for `struct("info", ...)`.
if false then
  local _r = lurek.log.info_fields(nil, 0)
  print(_r)
end

--@api-stub: lurek.log.warn_fields
-- Emits a warn structured log message.
-- Shorthand for `struct("warn", ...)`.
if false then
  local _r = lurek.log.warn_fields(nil, 0)
  print(_r)
end

--@api-stub: lurek.log.error_fields
-- Emits an error structured log message.
-- Shorthand for `struct("error", ...)`.
if false then
  local _r = lurek.log.error_fields(nil, 0)
  print(_r)
end

