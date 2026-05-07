-- content/examples/serial.lua
-- Practical API stubs for lurek.serial.
--
-- Run: cargo run -- content/examples/serial.lua

--@api-stub: lurek.serial.fromJson
-- Parses JSON text and returns a Lua table.
-- Use this when loading interop payloads from tools or web services.
-- if false then
--   local data = lurek.serial.fromJson('{"name":"hero","hp":30}')
--   lurek.log.info(data.name .. " hp=" .. data.hp, "serial")
-- end

--@api-stub: lurek.serial.toJson
-- Serializes a Lua value to JSON text.
-- Use pretty=true for human-readable debug dumps.
-- if false then
--   local body = lurek.serial.toJson({ event = "level_up", level = 5 }, true)
--   lurek.log.info(body, "serial")
-- end

--@api-stub: lurek.serial.fromToml
-- Parses TOML text and returns a Lua table.
-- Prefer TOML for hand-authored config files.
-- if false then
--   local cfg = lurek.serial.fromToml('title = "Forest"\n[window]\nwidth = 1280\n')
--   lurek.log.info(cfg.title .. " width=" .. cfg.window.width, "serial")
-- end

--@api-stub: lurek.serial.toToml
-- Serializes a Lua table to TOML text.
-- Nested tables become TOML sections.
-- if false then
--   local text = lurek.serial.toToml({ audio = { master = 0.8 }, fullscreen = false })
--   lurek.log.info(text, "serial")
-- end

--@api-stub: lurek.serial.fromIni
-- Parses INI text and returns a Lua table.
-- Use this for legacy config imports.
-- if false then
--   local cfg = lurek.serial.fromIni("[player]\nname=hero\n")
--   lurek.log.info(cfg.player.name, "serial")
-- end

--@api-stub: lurek.serial.fromCsv
-- Parses CSV text into rows.
-- With headers=true each row is keyed by column names.
-- if false then
--   local rows = lurek.serial.fromCsv("name,score\nada,10\nlin,20\n")
--   lurek.log.info(rows[1].name .. " score=" .. rows[1].score, "serial")
-- end

--@api-stub: lurek.serial.toCsv
-- Serializes rows to CSV text.
-- Useful for exporting score tables to spreadsheets.
-- if false then
--   local csv = lurek.serial.toCsv({ { name = "ada", score = "10" } })
--   lurek.log.info(csv, "serial")
-- end

--@api-stub: lurek.serial.encodeMsgPack
-- Encodes a Lua table to MessagePack bytes.
-- Use this for compact binary save payloads.
-- if false then
--   local bytes = lurek.serial.encodeMsgPack({ tick = 100, hp = 75 })
--   lurek.log.info("encoded bytes=" .. #bytes, "serial")
-- end

--@api-stub: lurek.serial.decodeMsgPack
-- Decodes MessagePack bytes into a Lua table.
-- Pair with encodeMsgPack for binary round-trips.
-- if false then
--   local bytes = lurek.serial.encodeMsgPack({ tick = 100 })
--   local data = lurek.serial.decodeMsgPack(bytes)
--   lurek.log.info("tick=" .. data.tick, "serial")
-- end

--@api-stub: lurek.serial.decodeXml
-- Parses XML text into nested tag/attrs/text/children tables.
-- Useful for legacy import flows.
-- if false then
--   local node = lurek.serial.decodeXml('<root id="1"><child>ok</child></root>')
--   lurek.log.info(node.tag .. " id=" .. node.attrs.id, "serial")
-- end

--@api-stub: lurek.serial.validate
-- Validates a value against a schema.
-- Returns (ok, err) instead of throwing for validation mismatch.
-- if false then
--   local ok, err = lurek.serial.validate({ hp = 30 }, { type = "table", fields = {
--     hp = { type = "number", min = 1, max = 999 },
--   }})
--   lurek.log.info("ok=" .. tostring(ok) .. " err=" .. tostring(err), "serial")
-- end

--@api-stub: lurek.serial.detectFormat
-- Detects text format from content.
-- Auto-detect supports json, toml, csv, and xml.
-- if false then
--   local kind = lurek.serial.detectFormat('{"k":1}')
--   lurek.log.info("format=" .. tostring(kind), "serial")
-- end

--@api-stub: lurek.serial.decode
-- Unified decode entry point for text and msgpack.
-- Pass nil format to auto-detect text formats.
-- if false then
--   local a = lurek.serial.decode('{"k":1}')
--   local b = lurek.serial.decode("title = \"demo\"", "toml")
--   lurek.log.info(a.k .. " " .. b.title, "serial")
-- end

--@api-stub: lurek.serial.encode
-- Unified encode entry point for json, toml, csv, and msgpack.
-- CSV and JSON tuning can be passed with opts table.
-- if false then
--   local json = lurek.serial.encode({ hp = 10 }, "json", { pretty = true })
--   local csv = lurek.serial.encode({ { name = "ada", score = "10" } }, "csv", { delimiter = ";" })
--   lurek.log.info(json .. "\n" .. csv, "serial")
-- end

--@api-stub: lurek.serial.applyDefaults
-- Applies schema defaults recursively and returns patched value.
-- Use this after decode to fill optional config fields.
-- if false then
--   local schema = { type = "table", fields = {
--     hp = { type = "number", default = 100 },
--     name = { type = "string", default = "hero" },
--   }}
--   local patched = lurek.serial.applyDefaults({}, schema)
--   lurek.log.info(patched.name .. " hp=" .. patched.hp, "serial")
-- end
