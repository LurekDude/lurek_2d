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

