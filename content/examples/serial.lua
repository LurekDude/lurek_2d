-- examples/serial.lua
-- lurek.codec — Serialization and deserialization: JSON, TOML, CSV.

-- ── JSON ──────────────────────────────────────────────────────────────────────

-- fromJson(s) → table | value   — deserialize a JSON string to Lua value
local json_str = '{"name":"hero","hp":100,"items":["sword","shield"]}'
local data = lurek.codec.fromJson(json_str)
print(data.name)         -- "hero"
print(data.hp)           -- 100
print(data.items[1])     -- "sword"

-- toJson(value, pretty?) → string   — serialize a Lua table (or any serializable value) to JSON
-- pretty = true adds indentation
local result = lurek.codec.toJson({ id = 42, score = 9999 })
print(result)            -- {"id":42,"score":9999}

local pretty = lurek.codec.toJson({ id = 42, score = 9999 }, true)
print(pretty)
-- {
"id": 42,
"score": 9999
-- }

-- Round-trip JSON
local original = { level = 3, pos = { x = 100, y = 200 } }
local encoded  = lurek.codec.toJson(original)
local decoded  = lurek.codec.fromJson(encoded)
assert(decoded.level == 3)
assert(decoded.pos.x == 100)

-- ── TOML ──────────────────────────────────────────────────────────────────────

-- fromToml(s) → table   — parse TOML text to Lua table
local toml_str = [[
title = "Luna Demo"
version = 1

[window]
width  = 1280
height = 720
]]
local cfg = lurek.codec.fromToml(toml_str)
print(cfg.title)           -- "Luna Demo"
print(cfg.window.width)    -- 1280

-- toToml(value) → string   — serialize a Lua table to TOML
local toml_out = lurek.codec.toToml({
    title = "My Game",
    version = 2,
    window = { width = 800, height = 600 }
})
print(toml_out)

-- ── CSV ───────────────────────────────────────────────────────────────────────

-- fromCsv(s, delimiter?, has_headers?) → table of tables
-- Each inner table is one row; if has_headers=true, inner tables are keyed by column name.
-- delimiter defaults to ","  |  has_headers defaults to true

local csv_str = "name,hp,level\nhero,100,5\nvillain,200,10"
local rows_keyed = lurek.codec.fromCsv(csv_str)        -- has_headers = true by default
print(rows_keyed[1].name)    -- "hero"
print(rows_keyed[2].hp)      -- "200" (values are strings)

-- Without headers — each row becomes an array
local rows_array = lurek.codec.fromCsv("a,b\nc,d", ",", false)
print(rows_array[1][1])  -- "a"
print(rows_array[2][2])  -- "d"

-- Custom delimiter (tab-separated)
local tsv = "sword\t10\ndagger\t5"
local items_tsv = lurek.codec.fromCsv(tsv, "\t", false)
print(items_tsv[1][1])   -- "sword"

-- toCsv(value, delimiter?, has_headers?) → string
-- Converts an array of arrays (or array of keyed tables) back to CSV text.
-- has_headers=true (default) — use keys from first row as header row.

local data_table = {
    { name = "axe",   damage = 15 },
    { name = "staff", damage = 8  },
}
local csv_out = lurek.codec.toCsv(data_table)
print(csv_out)
-- damage,name
-- 15,axe
-- 8,staff

-- Use has_headers=false with array-of-arrays
local arr_out = lurek.codec.toCsv({ {"r1c1","r1c2"}, {"r2c1","r2c2"} }, ",", false)
print(arr_out)
-- r1c1,r1c2
-- r2c1,r2c2

-- ── Common Patterns ───────────────────────────────────────────────────────────

-- Save/load settings with JSON
--[[
local function save_settings(path, settings)
    lurek.fs.write(path, lurek.codec.toJson(settings, true))
end

local function load_settings(path)
    if lurek.fs.exists(path) then
        return lurek.codec.fromJson(lurek.fs.read(path))
    end
    return { volume = 1.0, fullscreen = false }
end
]]

-- Parse game data from TOML config
--[[
local config_text = lurek.fs.read("data/config.toml")
local game_config = lurek.codec.fromToml(config_text)
local target_fps  = game_config.performance.target_fps or 60
]]

-- Export leaderboard as CSV
--[[
local scores = {
    { name = "Alice", score = 1200, time = 98 },
    { name = "Bob",   score =  900, time = 115 },
}
lurek.fs.write("save/scores.csv", lurek.codec.toCsv(scores))
]]

-- ── MessagePack ───────────────────────────────────────────────────────────────

-- encodeMsgPack(value) → string (binary)
-- Encodes a Lua table to a compact binary MessagePack payload.
local save_data = { level = 3, hp = 80, items = { "sword", "shield" } }
local packed = lurek.codec.encodeMsgPack(save_data)
print(type(packed))   -- "string"  (binary bytes)
print(#packed)        -- smaller than equivalent JSON

-- decodeMsgPack(bytes) → table
-- Decodes a MessagePack binary string back to a Lua table.
local unpacked = lurek.codec.decodeMsgPack(packed)
print(unpacked.level)      -- 3
print(unpacked.items[1])   -- "sword"

-- Round-trip
assert(unpacked.hp == save_data.hp)

-- ── XML decode ────────────────────────────────────────────────────────────────

-- decodeXml(s) → table
-- Parses XML into a nested Lua table.
-- Each element → { tag=..., attrs={...}, text=..., children={...} }
-- attrs/text/children are omitted when absent.

local xml_str = [[
<map version="1" orientation="orthogonal">
  <layer name="ground" width="10" height="10">
    <tile id="3"/>
    <tile id="7"/>
  </layer>
</map>
]]

local map_tbl = lurek.codec.decodeXml(xml_str)
print(map_tbl.tag)                          -- "map"
print(map_tbl.attrs.version)               -- "1"
local layer = map_tbl.children[1]
print(layer.attrs.name)                    -- "ground"
print(layer.children[1].attrs.id)         -- "3"

-- ── Schema Validation ─────────────────────────────────────────────────────────

-- validate(value, schema) → boolean, string?
-- Returns true (+ nil) when valid, or false + error_message when invalid.
-- Schema keys: type, required, min, max, minlen, maxlen, fields, items.

local hero_schema = {
  type = "table",
  fields = {
    name  = { type = "string",  required = true, minlen = 1, maxlen = 32 },
    level = { type = "number",  required = true, min = 1, max = 100 },
    alive = { type = "boolean" },
    items = { type = "table",   items = { type = "string" } },
  }
}

-- Valid hero: passes
local ok, err = lurek.codec.validate(
  { name = "Aria", level = 12, alive = true, items = { "bow", "quiver" } },
  hero_schema
)
print(ok, err)   -- true   nil

-- Missing required field: fails
local ok2, err2 = lurek.codec.validate(
  { level = 12 },
  hero_schema
)
print(ok2, err2)  -- false   "name: required field is nil"

-- Level out of range: fails
local ok3, err3 = lurek.codec.validate(
  { name = "Aria", level = 200 },
  hero_schema
)
print(ok3, err3)  -- false   "level: value 200 is greater than max 100"

