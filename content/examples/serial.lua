-- content/examples/serial.lua
-- Lurek2D lurek.serial API Reference
-- Run with: cargo run -- content/examples/serial

-- =============================================================================
-- lurek.serial — Data serialization and deserialization
--
-- This module converts Lua tables to and from common text formats: JSON, TOML,
-- CSV, MessagePack, and XML.  It also provides schema validation for incoming
-- data.  Typical uses: saving config files, loading level data exported from
-- editors, exchanging data over the network, and validating mod payloads.
-- =============================================================================

-- ---- Stub: lurek.serial.fromJson -----------------------------------------
--@api-stub: lurek.serial.fromJson
-- Parse a JSON string received from a remote leaderboard server into a Lua
-- table so we can display the top-ten scores in the UI.
local leaderboard_json = '{"scores":[{"name":"Alice","pts":9200},{"name":"Bob","pts":8750}]}'
local leaderboard = lurek.serial.fromJson(leaderboard_json)

for i, entry in ipairs(leaderboard.scores) do
    print(string.format("#%d  %s — %d pts", i, entry.name, entry.pts))
end
print("total entries: " .. #leaderboard.scores)

-- ---- Stub: lurek.serial.toJson -------------------------------------------
--@api-stub: lurek.serial.toJson
-- Serialize the player's key-bindings table to pretty-printed JSON so it can
-- be sent to a web dashboard or pasted into a config sharing tool.
local keybindings = {
    move_up    = "W",
    move_down  = "S",
    move_left  = "A",
    move_right = "D",
    fire       = "Space",
    dash       = "LShift",
}
local json_str = lurek.serial.toJson(keybindings, true)   -- true = pretty print
print("exported keybindings JSON:")
print(json_str)
print("JSON length: " .. #json_str .. " bytes")

-- ---- Stub: lurek.serial.fromToml -----------------------------------------
--@api-stub: lurek.serial.fromToml
-- Load a hand-authored level descriptor written in TOML (the preferred config
-- format for Lurek2D) and extract spawn positions for enemies.
local level_toml = [[
[meta]
name    = "Dungeon Floor 3"
author  = "level_team"
version = 2

[[enemies]]
type = "skeleton"
x    = 120
y    = 340

[[enemies]]
type = "bat"
x    = 400
y    = 180
]]

local level = lurek.serial.fromToml(level_toml)
print("level name: " .. level.meta.name)
for i, enemy in ipairs(level.enemies) do
    print(string.format("  spawn %s at (%d, %d)", enemy.type, enemy.x, enemy.y))
end

-- ---- Stub: lurek.serial.toToml -------------------------------------------
--@api-stub: lurek.serial.toToml
-- Serialize current game settings to TOML so they can be written to conf.toml
-- by the options menu.
local settings = {
    video = {
        fullscreen = false,
        vsync      = true,
        resolution = "1280x720",
    },
    audio = {
        master_volume = 0.8,
        music_volume  = 0.6,
        sfx_volume    = 1.0,
    },
}
local toml_str = lurek.serial.toToml(settings)
print("settings TOML output:")
print(toml_str)

-- ---- Stub: lurek.serial.fromCsv ------------------------------------------
--@api-stub: lurek.serial.fromCsv
-- Import a CSV item database exported from a spreadsheet.  The first row is
-- treated as column headers so each row becomes a named-field table.
local item_csv = "id,name,cost,damage\n1,Wooden Sword,50,8\n2,Iron Shield,120,0\n3,Health Potion,30,0"
local items = lurek.serial.fromCsv(item_csv, ",", true)   -- delimiter, headers

for _, item in ipairs(items) do
    print(string.format("  [%s] %s  cost=%s  dmg=%s",
        item.id, item.name, item.cost, item.damage))
end
print("loaded " .. #items .. " items from CSV")

-- ---- Stub: lurek.serial.toCsv --------------------------------------------
--@api-stub: lurek.serial.toCsv
-- Export the current inventory to CSV so it can be loaded into a spreadsheet
-- for balancing analysis.
local inventory = {
    { slot = 1, item = "Wooden Sword", qty = 1 },
    { slot = 2, item = "Health Potion", qty = 5 },
    { slot = 3, item = "Iron Shield",   qty = 1 },
}
local csv_out = lurek.serial.toCsv(inventory, ",", { "slot", "item", "qty" })
print("inventory CSV:")
print(csv_out)

-- ---- Stub: lurek.serial.encodeMsgPack ------------------------------------
--@api-stub: lurek.serial.encodeMsgPack
-- Encode a compact snapshot of the player state into MessagePack for fast
-- binary storage in the save system or network transmission.
local player_state = {
    hp     = 85,
    max_hp = 100,
    pos_x  = 312.5,
    pos_y  = 780.0,
    level  = 7,
    buffs  = { "haste", "shield" },
}
local packed = lurek.serial.encodeMsgPack(player_state)
print("msgpack size: " .. #packed .. " bytes")
print("(compare to JSON: " .. #lurek.serial.toJson(player_state) .. " bytes)")

-- ---- Stub: lurek.serial.decodeMsgPack ------------------------------------
--@api-stub: lurek.serial.decodeMsgPack
-- Decode the MessagePack blob back into a Lua table and verify the round-trip
-- preserved the player state.
local restored = lurek.serial.decodeMsgPack(packed)
print("restored HP: " .. restored.hp .. "/" .. restored.max_hp)
print("position:    " .. restored.pos_x .. ", " .. restored.pos_y)
print("level:       " .. restored.level)
print("buffs:       " .. table.concat(restored.buffs, ", "))

-- ---- Stub: lurek.serial.decodeXml ----------------------------------------
--@api-stub: lurek.serial.decodeXml
-- Parse an XML tileset descriptor exported from an external map editor like
-- Tiled.  XML is read-only in Lurek2D -- use it for importing third-party
-- data, never for authoring config (use TOML instead).
local tileset_xml = [[
<tileset name="dungeon" tilewidth="16" tileheight="16">
  <tile id="0"><properties><property name="solid" value="true"/></properties></tile>
  <tile id="1"><properties><property name="solid" value="false"/></properties></tile>
</tileset>
]]
local tileset = lurek.serial.decodeXml(tileset_xml)
print("tileset root tag: " .. (tileset.tag or tileset.name or "unknown"))
-- Walk the parsed tree to extract tile properties
if tileset.children then
    for _, child in ipairs(tileset.children) do
        print("  tile element found")
    end
end

-- ---- Stub: lurek.serial.validate -----------------------------------------
--@api-stub: lurek.serial.validate
-- Validate incoming mod data against a schema before loading it into the game.
-- This prevents malformed mods from crashing the item system.
local mod_payload = {
    name    = "Epic Axe",
    damage  = 25,
    rarity  = "legendary",
    weight  = 3.5,
}

local item_schema = {
    name   = "string",
    damage = "number",
    rarity = "string",
    weight = "number",
}

local ok, err = lurek.serial.validate(mod_payload, item_schema)
if ok then
    print("mod item validated -- safe to load")
else
    print("validation failed: " .. tostring(err))
end

-- Intentionally bad payload to show validation catching errors
local bad_payload = { name = 42, damage = "not_a_number" }
local ok2, err2 = lurek.serial.validate(bad_payload, item_schema)
print("bad payload valid? " .. tostring(ok2) .. "  reason: " .. tostring(err2))
-- content/examples/serial.lua
-- Lurek2D lurek.serial API Reference
-- Run with: cargo run -- content/examples/serial

-- =============================================================================
-- STUBS: 10 uncovered lurek.serial API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.serial.fromJson -----------------------------------------
--@api-stub: lurek.serial.fromJson
-- Parses a JSON string and returns a Lua table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.serial.fromJson(s)  -- -> table

-- ---- Stub: lurek.serial.toJson -------------------------------------------
--@api-stub: lurek.serial.toJson
-- Serializes a Lua value to a JSON string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.serial.toJson(42, [pretty])  -- -> string

-- ---- Stub: lurek.serial.fromToml -----------------------------------------
--@api-stub: lurek.serial.fromToml
-- Parses a TOML string and returns a Lua table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.serial.fromToml(s)  -- -> table

-- ---- Stub: lurek.serial.toToml -------------------------------------------
--@api-stub: lurek.serial.toToml
-- Serializes a Lua table to a TOML string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.serial.toToml(42)  -- -> string

-- ---- Stub: lurek.serial.fromCsv ------------------------------------------
--@api-stub: lurek.serial.fromCsv
-- Parses a CSV string and returns a sequence of row tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.serial.fromCsv(s, [delim], [headers])  -- -> table

-- ---- Stub: lurek.serial.toCsv --------------------------------------------
--@api-stub: lurek.serial.toCsv
-- Serializes a sequence of row tables to a CSV string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.serial.toCsv(42, [delim], [headers])  -- -> string

-- ---- Stub: lurek.serial.encodeMsgPack ------------------------------------
--@api-stub: lurek.serial.encodeMsgPack
-- Encodes a Lua table to a binary MessagePack string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.serial.encodeMsgPack(42)  -- -> string

-- ---- Stub: lurek.serial.decodeMsgPack ------------------------------------
--@api-stub: lurek.serial.decodeMsgPack
-- Decodes a binary MessagePack string into a Lua table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.serial.decodeMsgPack()  -- -> table

-- ---- Stub: lurek.serial.decodeXml ----------------------------------------
--@api-stub: lurek.serial.decodeXml
-- Parses an XML string and returns a nested Lua table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.serial.decodeXml(s)  -- -> table

-- ---- Stub: lurek.serial.validate -----------------------------------------
--@api-stub: lurek.serial.validate
-- Validates a Lua table against a schema table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.serial.validate(42, schema)
