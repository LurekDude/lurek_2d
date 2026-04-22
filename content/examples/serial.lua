-- content/examples/serial.lua
-- Practical usage examples for the lurek.serial API (10 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.serial.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/serial.lua

print("[example] lurek.serial — 10 API entries")

-- ── lurek.serial.* free functions ──

--@api-stub: lurek.serial.fromJson
-- Parses a JSON string and returns a Lua table.
-- Call when you need to invoke from json.
local ok, obj = pcall(function() return lurek.serial.fromJson(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.serial.fromJson ok=", ok)

--@api-stub: lurek.serial.toJson
-- Serializes a Lua value to a JSON string.
-- Call when you need to invoke to json.
local ok, result = pcall(function() return lurek.serial.toJson(nil, nil) end)
if ok then print("lurek.serial.toJson ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.serial.fromToml
-- Parses a TOML string and returns a Lua table.
-- Call when you need to invoke from toml.
local ok, obj = pcall(function() return lurek.serial.fromToml(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.serial.fromToml ok=", ok)

--@api-stub: lurek.serial.toToml
-- Serializes a Lua table to a TOML string.
-- Call when you need to invoke to toml.
local ok, result = pcall(function() return lurek.serial.toToml(nil) end)
if ok then print("lurek.serial.toToml ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.serial.fromCsv
-- Parses a CSV string and returns a sequence of row tables.
-- Call when you need to invoke from csv.
local ok, obj = pcall(function() return lurek.serial.fromCsv(nil, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.serial.fromCsv ok=", ok)

--@api-stub: lurek.serial.toCsv
-- Serializes a sequence of row tables to a CSV string.
-- Call when you need to invoke to csv.
local ok, result = pcall(function() return lurek.serial.toCsv(nil, nil, nil) end)
if ok then print("lurek.serial.toCsv ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.serial.encodeMsgPack
-- Encodes a Lua table to a binary MessagePack string.
-- Call when you need to invoke encode msg pack.
local ok, result = pcall(function() return lurek.serial.encodeMsgPack(nil) end)
if ok then print("lurek.serial.encodeMsgPack ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.serial.decodeMsgPack
-- Decodes a binary MessagePack string into a Lua table.
-- Call when you need to invoke decode msg pack.
local ok, result = pcall(function() return lurek.serial.decodeMsgPack() end)
if ok then print("lurek.serial.decodeMsgPack ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.serial.decodeXml
-- Parses an XML string and returns a nested Lua table.
-- Call when you need to invoke decode xml.
local ok, result = pcall(function() return lurek.serial.decodeXml(nil) end)
if ok then print("lurek.serial.decodeXml ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.serial.validate
-- Validates a Lua table against a schema table.
-- Call when you need to invoke validate.
local ok, result = pcall(function() return lurek.serial.validate(nil, nil) end)
if ok then print("lurek.serial.validate ->", result)
else print("unavailable:", result) end

