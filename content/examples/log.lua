-- content/examples/log.lua
-- Practical usage examples for the lurek.log API (18 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.log.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/log.lua

print("[example] lurek.log — 18 API entries")

-- ── lurek.log.* free functions ──

--@api-stub: lurek.log.debug
-- Emits a debug-severity log message.
-- Also dispatches to configured sinks.
local ok, result = pcall(function() return lurek.log.debug(nil, "tag") end)
if ok then print("lurek.log.debug ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.log.info
-- Emits an info-severity log message.
-- Also dispatches to configured sinks.
local ok, result = pcall(function() return lurek.log.info(nil, "tag") end)
if ok then print("lurek.log.info ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.log.warn
-- Emits a warn-severity log message.
-- Also dispatches to configured sinks.
local ok, result = pcall(function() return lurek.log.warn(nil, "tag") end)
if ok then print("lurek.log.warn ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.log.error
-- Emits an error-severity log message.
-- Also dispatches to configured sinks.
local ok, result = pcall(function() return lurek.log.error(nil, "tag") end)
if ok then print("lurek.log.error ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.log.print
-- Emits a log message at the specified level.
-- Also dispatches to sinks.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.log.print(nil, nil, "tag") end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.log.print drawn=", ok)

--@api-stub: lurek.log.setLevel
-- Sets the minimum severity level for the default log channel.
-- Call when you need to assign level.
local ok, err = pcall(function() lurek.log.setLevel(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.log.setLevel applied=", ok)

--@api-stub: lurek.log.getLevel
-- Returns the name of the currently active minimum log level.
-- Call when you need to read level.
local ok, value = pcall(function() return lurek.log.getLevel() end)
local v = ok and value or "(unavailable)"
print("lurek.log.getLevel ->", v)

--@api-stub: lurek.log.addSink
-- Registers a new output sink.
-- Returns its numeric id.
local ok, err = pcall(function() lurek.log.addSink({}) end)
if not ok then print("mutator skipped:", err) end
print("lurek.log.addSink done=", ok)

--@api-stub: lurek.log.removeSink
-- Removes a sink by id.
-- Returns true if one was removed.
local ok, err = pcall(function() lurek.log.removeSink(1) end)
if not ok then print("skipped:", err) end
print("lurek.log.removeSink cleared=", ok)

--@api-stub: lurek.log.clearSinks
-- Removes all registered sinks (the default stderr channel is unaffected).
-- Call when you need to invoke clear sinks.
local ok, err = pcall(function() lurek.log.clearSinks() end)
if not ok then print("skipped:", err) end
print("lurek.log.clearSinks cleared=", ok)

--@api-stub: lurek.log.listSinks
-- Returns a table describing all registered sinks.
-- Call when you need to invoke list sinks.
local ok, result = pcall(function() return lurek.log.listSinks() end)
if ok then print("lurek.log.listSinks ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.log.readMemory
-- Reads entries from a memory sink.
-- If drain=true the buffer is cleared.
local ok, value = pcall(function() return lurek.log.readMemory(1, nil) end)
local v = ok and value or "(unavailable)"
print("lurek.log.readMemory ->", v)

--@api-stub: lurek.log.flushFile
-- Flushes the OS write buffer for a file sink.
-- Call when you need to invoke flush file.
local ok, result = pcall(function() return lurek.log.flushFile(1) end)
if ok then print("lurek.log.flushFile ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.log.struct
-- Emits a structured log message with key-value fields.
-- Call when you need to invoke struct.
local ok, result = pcall(function() return lurek.log.struct("level_str value", nil, {}) end)
if ok then print("lurek.log.struct ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.log.debug_fields
-- Emits a debug structured log message.
-- Shorthand for `struct("debug", ...)`.
local ok, result = pcall(function() return lurek.log.debug_fields(nil, {}) end)
if ok then print("lurek.log.debug_fields ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.log.info_fields
-- Emits an info structured log message.
-- Shorthand for `struct("info", ...)`.
local ok, result = pcall(function() return lurek.log.info_fields(nil, {}) end)
if ok then print("lurek.log.info_fields ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.log.warn_fields
-- Emits a warn structured log message.
-- Shorthand for `struct("warn", ...)`.
local ok, result = pcall(function() return lurek.log.warn_fields(nil, {}) end)
if ok then print("lurek.log.warn_fields ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.log.error_fields
-- Emits an error structured log message.
-- Shorthand for `struct("error", ...)`.
local ok, result = pcall(function() return lurek.log.error_fields(nil, {}) end)
if ok then print("lurek.log.error_fields ->", result)
else print("unavailable:", result) end

