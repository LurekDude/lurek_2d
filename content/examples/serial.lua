-- content/examples/serial.lua
-- Hand-written coverage of the lurek.serial API (10 items).
--
-- The lurek.serial namespace converts between Lua tables and common
-- text / binary formats (JSON, TOML, CSV, MessagePack, XML) and
-- validates tables against a schema. All parsers raise a Lua error
-- on malformed input; validate() returns (ok, err) instead.
--
-- Run: cargo run -- content/examples/serial.lua

-- ── lurek.serial.* functions ──

--@api-stub: lurek.serial.fromJson
-- Parses a JSON string and returns a Lua table.
-- Use this to load data shipped from a tool or web service; expect a Lua error on malformed JSON.
do  -- lurek.serial.fromJson
  local raw = '{"name":"goblin","hp":30,"loot":["coin","dagger"]}'
  local enemy = lurek.serial.fromJson(raw)
  lurek.log.info("spawned " .. enemy.name .. " hp=" .. enemy.hp .. " drops=" .. #enemy.loot, "spawn")
end

--@api-stub: lurek.serial.toJson
-- Serializes a Lua value to a JSON string.
-- Use for interop with external tools or HTTP bodies; arrays must be 1-indexed contiguous sequences.
do  -- lurek.serial.toJson
  local payload = { event = "level_complete", time_s = 124.5, deaths = 2 }
  local body = lurek.serial.toJson(payload)
  lurek.log.info("telemetry body=" .. body, "net")
end

--@api-stub: lurek.serial.fromToml
-- Parses a TOML string and returns a Lua table.
-- Prefer TOML for hand-edited config: it preserves comments visually and is friendlier than JSON.
do  -- lurek.serial.fromToml
  local conf = lurek.serial.fromToml([[
title = "Forest Keep"
[window]
width = 1280
height = 720
]])
  lurek.log.info("loaded '" .. conf.title .. "' " .. conf.window.width .. "x" .. conf.window.height, "boot")
end

--@api-stub: lurek.serial.toToml
-- Serializes a Lua table to a TOML string.
-- Use to write back human-edited config; nested tables become [section] headers.
do  -- lurek.serial.toToml
  local settings = { audio = { master = 0.8, music = 0.6 }, fullscreen = true }
  local text = lurek.serial.toToml(settings)
  lurek.log.info("settings.toml:\n" .. text, "config")
end

--@api-stub: lurek.serial.fromCsv
-- Parses a CSV string and returns a sequence of row tables.
-- With has_headers=true (default) each row is keyed by header; pass delimiter=";" for European exports.
do  -- lurek.serial.fromCsv
  local rows = lurek.serial.fromCsv("name,hp,xp\ngoblin,30,15\norc,80,50\n")
  for _, row in ipairs(rows) do
    lurek.log.info(row.name .. " hp=" .. row.hp .. " xp=" .. row.xp, "bestiary")
  end
end

--@api-stub: lurek.serial.toCsv
-- Serializes a sequence of row tables to a CSV string.
-- Useful for exporting telemetry or high-score tables that designers will open in a spreadsheet.
do  -- lurek.serial.toCsv
  local scores = {
    { player = "ada", score = 1280, level = 4 },
    { player = "lin", score = 980,  level = 3 },
  }
  local csv = lurek.serial.toCsv(scores)
  lurek.log.info("scores.csv:\n" .. csv, "export")
end

--@api-stub: lurek.serial.encodeMsgPack
-- Encodes a Lua table to a binary MessagePack string.
-- Prefer over JSON for save files or network packets when size matters; binary is not human-readable.
do  -- lurek.serial.encodeMsgPack
  local snapshot = { tick = 4821, player = { x = 128.5, y = 64.0, hp = 87 } }
  local bytes = lurek.serial.encodeMsgPack(snapshot)
  lurek.log.info("snapshot encoded " .. #bytes .. " bytes", "save")
end

--@api-stub: lurek.serial.decodeMsgPack
-- Decodes a binary MessagePack string into a Lua table.
-- Pair with encodeMsgPack for save/load round-trips; the byte string is what fs.read returns.
do  -- lurek.serial.decodeMsgPack
  local bytes = lurek.serial.encodeMsgPack({ tick = 100, player = { hp = 50 } })
  local snapshot = lurek.serial.decodeMsgPack(bytes)
  lurek.log.info("restored tick=" .. snapshot.tick .. " hp=" .. snapshot.player.hp, "save")
end

--@api-stub: lurek.serial.decodeXml
-- Parses an XML string and returns a nested Lua table.
-- Each node has tag/attrs/text/children fields; use it for legacy formats like Tiled .tmx or Spine atlases.
do  -- lurek.serial.decodeXml
  local doc = lurek.serial.decodeXml('<map width="32" height="24"><tile id="1"/></map>')
  lurek.log.info("root=" .. doc.tag .. " w=" .. doc.attrs.width .. " h=" .. doc.attrs.height, "tilemap")
  lurek.log.info("first child tag=" .. doc.children[1].tag, "tilemap")
end

--@api-stub: lurek.serial.validate
-- Validates a Lua table against a schema table.
-- Run after fromJson/fromToml on untrusted input so a malformed save file fails loudly with a path.
do  -- lurek.serial.validate
  local schema = { type = "table", fields = {
    name = { type = "string", required = true },
    hp   = { type = "number", min = 1, max = 999 },
  }}
  local ok, err = lurek.serial.validate({ name = "goblin", hp = 30 }, schema)
  lurek.log.info("valid=" .. tostring(ok) .. " err=" .. tostring(err), "schema")
end
-- content/examples/serial.lua
-- Scaffolded coverage of the lurek.serial API (10 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/serial_api.rs   (Lua binding, arg types, return shape)
--   * src/serial/                 (semantics, side effects)
--   * docs/specs/serial.md        (canonical reference)
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
-- Run: cargo run -- content/examples/serial.lua

-- ── lurek.serial.* functions ──

--@api-stub: lurek.serial.fromJson
-- Parses a JSON string and returns a Lua table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/serial_api.rs and docs/specs/serial.md).
do  -- TODO: lurek.serial.fromJson
  local _todo = "TODO: write a real lurek.serial.fromJson usage example"
  print(_todo)
end

--@api-stub: lurek.serial.toJson
-- Serializes a Lua value to a JSON string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/serial_api.rs and docs/specs/serial.md).
do  -- TODO: lurek.serial.toJson
  local _todo = "TODO: write a real lurek.serial.toJson usage example"
  print(_todo)
end

--@api-stub: lurek.serial.fromToml
-- Parses a TOML string and returns a Lua table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/serial_api.rs and docs/specs/serial.md).
do  -- TODO: lurek.serial.fromToml
  local _todo = "TODO: write a real lurek.serial.fromToml usage example"
  print(_todo)
end

--@api-stub: lurek.serial.toToml
-- Serializes a Lua table to a TOML string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/serial_api.rs and docs/specs/serial.md).
do  -- TODO: lurek.serial.toToml
  local _todo = "TODO: write a real lurek.serial.toToml usage example"
  print(_todo)
end

--@api-stub: lurek.serial.fromCsv
-- Parses a CSV string and returns a sequence of row tables.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/serial_api.rs and docs/specs/serial.md).
do  -- TODO: lurek.serial.fromCsv
  local _todo = "TODO: write a real lurek.serial.fromCsv usage example"
  print(_todo)
end

--@api-stub: lurek.serial.toCsv
-- Serializes a sequence of row tables to a CSV string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/serial_api.rs and docs/specs/serial.md).
do  -- TODO: lurek.serial.toCsv
  local _todo = "TODO: write a real lurek.serial.toCsv usage example"
  print(_todo)
end

--@api-stub: lurek.serial.encodeMsgPack
-- Encodes a Lua table to a binary MessagePack string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/serial_api.rs and docs/specs/serial.md).
do  -- TODO: lurek.serial.encodeMsgPack
  local _todo = "TODO: write a real lurek.serial.encodeMsgPack usage example"
  print(_todo)
end

--@api-stub: lurek.serial.decodeMsgPack
-- Decodes a binary MessagePack string into a Lua table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/serial_api.rs and docs/specs/serial.md).
do  -- TODO: lurek.serial.decodeMsgPack
  local _todo = "TODO: write a real lurek.serial.decodeMsgPack usage example"
  print(_todo)
end

--@api-stub: lurek.serial.decodeXml
-- Parses an XML string and returns a nested Lua table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/serial_api.rs and docs/specs/serial.md).
do  -- TODO: lurek.serial.decodeXml
  local _todo = "TODO: write a real lurek.serial.decodeXml usage example"
  print(_todo)
end

--@api-stub: lurek.serial.validate
-- Validates a Lua table against a schema table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/serial_api.rs and docs/specs/serial.md).
do  -- TODO: lurek.serial.validate
  local _todo = "TODO: write a real lurek.serial.validate usage example"
  print(_todo)
end

