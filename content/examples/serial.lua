-- content/examples/serial.lua
-- lurek.serial API examples.
-- Run: cargo run -- content/examples/serial.lua

--@api-stub: lurek.serial.fromJson
-- Parses a JSON string into a Lua table
do
  local data = lurek.serial.fromJson('{"name":"hero","hp":30}')
  lurek.log.info(data.name .. " hp=" .. data.hp, "serial")
end

--@api-stub: lurek.serial.toJson
-- Serializes a Lua value (table, string, number, boolean, or nil) into a JSON string
do
  local body = lurek.serial.toJson({ event = "level_up", level = 5 }, true)
  lurek.log.info(body, "serial")
end

--@api-stub: lurek.serial.fromToml
-- Parses a TOML string into a Lua table
do
  local cfg = lurek.serial.fromToml('title = "Forest"\n[window]\nwidth = 1280\n')
  lurek.log.info(cfg.title .. " width=" .. cfg.window.width, "serial")
end

--@api-stub: lurek.serial.toToml
-- Serializes a Lua table into a TOML-formatted string
do
  local text = lurek.serial.toToml({ audio = { master = 0.8 }, fullscreen = false })
  lurek.log.info(text, "serial")
end

--@api-stub: lurek.serial.fromIni
-- Parses an INI-format string into a Lua table
do
  local cfg = lurek.serial.fromIni("[player]\nname=hero\n")
  lurek.log.info(cfg.player.name, "serial")
end

--@api-stub: lurek.serial.fromCsv
-- Parses a CSV string into a Lua table (array of rows)
do
  local rows = lurek.serial.fromCsv("name,score\nada,10\nlin,20\n")
  lurek.log.info(rows[1].name .. " score=" .. rows[1].score, "serial")
end

--@api-stub: lurek.serial.toCsv
-- Serializes a Lua table (array of row tables) into a CSV-formatted string
do
  local csv = lurek.serial.toCsv({ { name = "ada", score = "10" } })
  lurek.log.info(csv, "serial")
end

--@api-stub: lurek.serial.encodeMsgPack
-- Encodes a Lua table into a compact binary MessagePack string
do
  local bytes = lurek.serial.encodeMsgPack({ tick = 100, hp = 75 })
  lurek.log.info("encoded bytes=" .. #bytes, "serial")
end

--@api-stub: lurek.serial.decodeMsgPack
-- Decodes a binary MessagePack string back into a Lua table
do
  local bytes = lurek.serial.encodeMsgPack({ tick = 100 })
  local data = lurek.serial.decodeMsgPack(bytes)
  lurek.log.info("tick=" .. data.tick, "serial")
end

--@api-stub: lurek.serial.decodeXml
-- Parses an XML string into a Lua table structure
do
  local node = lurek.serial.decodeXml('<root id="1"><child>ok</child></root>')
  lurek.log.info(node.tag .. " id=" .. node.attrs.id, "serial")
end

--@api-stub: lurek.serial.validate
-- Validates a Lua value against a schema table
do
  local ok, err = lurek.serial.validate({ hp = 30 }, { type = "table", fields = {
    hp = { type = "number", min = 1, max = 999 },
  }})
  lurek.log.info("ok=" .. tostring(ok) .. " err=" .. tostring(err), "serial")
end

--@api-stub: lurek.serial.detectFormat
-- Attempts to auto-detect the serialization format of a string by inspecting its content (e
do
  local kind = lurek.serial.detectFormat('{"k":1}')
  lurek.log.info("format=" .. tostring(kind), "serial")
end

--@api-stub: lurek.serial.decode
-- Universal decoder that parses a string payload into a Lua table using the specified format
do
  local a = lurek.serial.decode('{"k":1}')
  local b = lurek.serial.decode("title = \"demo\"", "toml")
  lurek.log.info(a.k .. " " .. b.title, "serial")
end

--@api-stub: lurek.serial.encode
-- Universal encoder that serializes a Lua value into the specified format
do
  local json = lurek.serial.encode({ hp = 10 }, "json", { pretty = true })
  local csv = lurek.serial.encode({ { name = "ada", score = "10" } }, "csv", { delimiter = ";" })
  lurek.log.info(json .. "\n" .. csv, "serial")
end

--@api-stub: lurek.serial.applyDefaults
-- Merges a schema's default values into a data table, filling in any missing fields without overwriting existing ones
do
  local schema = { type = "table", fields = {
    hp = { type = "number", default = 100 },
    name = { type = "string", default = "hero" },
  }}
  local patched = lurek.serial.applyDefaults({}, schema)
  lurek.log.info(patched.name .. " hp=" .. patched.hp, "serial")
end
