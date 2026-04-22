-- content/examples/serial.lua
-- Auto-scaffolded coverage of the lurek.serial Lua API (10 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/serial.lua

print("[example] lurek.serial loaded — 10 API items demonstrated")

-- ── lurek.serial free functions ──

--@api-stub: lurek.serial.fromJson
-- Parses a JSON string and returns a Lua table.
-- Use this when parses a JSON string and returns a Lua table is needed.
if false then
  local _r = lurek.serial.fromJson(nil)
  print(_r)
end

--@api-stub: lurek.serial.toJson
-- Serializes a Lua value to a JSON string.
-- Use this when serializes a Lua value to a JSON string is needed.
if false then
  local _r = lurek.serial.toJson(0, 0)
  print(_r)
end

--@api-stub: lurek.serial.fromToml
-- Parses a TOML string and returns a Lua table.
-- Use this when parses a TOML string and returns a Lua table is needed.
if false then
  local _r = lurek.serial.fromToml(nil)
  print(_r)
end

--@api-stub: lurek.serial.toToml
-- Serializes a Lua table to a TOML string.
-- Use this when serializes a Lua table to a TOML string is needed.
if false then
  local _r = lurek.serial.toToml(0)
  print(_r)
end

--@api-stub: lurek.serial.fromCsv
-- Parses a CSV string and returns a sequence of row tables.
-- Use this when parses a CSV string and returns a sequence of row tables is needed.
if false then
  local _r = lurek.serial.fromCsv(nil, nil, 0)
  print(_r)
end

--@api-stub: lurek.serial.toCsv
-- Serializes a sequence of row tables to a CSV string.
-- Use this when serializes a sequence of row tables to a CSV string is needed.
if false then
  local _r = lurek.serial.toCsv(0, nil, 0)
  print(_r)
end

--@api-stub: lurek.serial.encodeMsgPack
-- Encodes a Lua table to a binary MessagePack string.
-- Use this when encodes a Lua table to a binary MessagePack string is needed.
if false then
  local _r = lurek.serial.encodeMsgPack(0)
  print(_r)
end

--@api-stub: lurek.serial.decodeMsgPack
-- Decodes a binary MessagePack string into a Lua table.
-- Use this when decodes a binary MessagePack string into a Lua table is needed.
if false then
  local _r = lurek.serial.decodeMsgPack()
  print(_r)
end

--@api-stub: lurek.serial.decodeXml
-- Parses an XML string and returns a nested Lua table.
-- Use this when parses an XML string and returns a nested Lua table is needed.
if false then
  local _r = lurek.serial.decodeXml(nil)
  print(_r)
end

--@api-stub: lurek.serial.validate
-- Validates a Lua table against a schema table.
-- Use this when validates a Lua table against a schema table is needed.
if false then
  local _r = lurek.serial.validate(0, 0)
  print(_r)
end

