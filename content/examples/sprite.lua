-- content/examples/sprite.lua
-- Practical usage examples for the lurek.sprite API (18 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.sprite.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/sprite.lua

print("[example] lurek.sprite — 18 API entries")

-- ── lurek.sprite.* free functions ──

--@api-stub: lurek.sprite.newSheet
-- Creates a sprite sheet with a uniform grid of `frame_w Ă— frame_h` frames.
-- Call when you need to create a new sheet.
local ok, obj = pcall(function() return lurek.sprite.newSheet(nil, nil, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.sprite.newSheet ok=", ok)

--@api-stub: lurek.sprite.newRPGMakerSheet
-- Creates an RPGMaker VX/Ace character sheet (3 cols Ă— 4 rows) with "down", "left", "right", "up" groups.
-- Call when you need to create a new r p g maker sheet.
local ok, obj = pcall(function() return lurek.sprite.newRPGMakerSheet(nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.sprite.newRPGMakerSheet ok=", ok)

--@api-stub: lurek.sprite.parseAtlas
-- Parses a TexturePacker JSON string (hash or array format) and returns a SpriteAtlas.
-- Call when you need to invoke parse atlas.
local ok, result = pcall(function() return lurek.sprite.parseAtlas("json_str value") end)
if ok then print("lurek.sprite.parseAtlas ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.sprite.newAtlasSheet
-- Builds a SpriteSheet whose frames come from named entries in a SpriteAtlas.
-- Call when you need to create a new atlas sheet.
local ok, obj = pcall(function() return lurek.sprite.newAtlasSheet(nil, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.sprite.newAtlasSheet ok=", ok)

--@api-stub: lurek.sprite.parseAsepriteAtlas
-- Parses an Aseprite JSON export string and returns a `SpriteAtlas`.
-- Call when you need to invoke parse aseprite atlas.
local ok, result = pcall(function() return lurek.sprite.parseAsepriteAtlas("json_str value") end)
if ok then print("lurek.sprite.parseAsepriteAtlas ->", result)
else print("unavailable:", result) end

-- ── SpriteSheet methods ──

--@api-stub: SpriteSheet:getFrame
-- Returns the quad for the 0-based frame index, or nil if out of range.
-- Call when you need to read frame.
-- Build a SpriteSheet via the appropriate lurek.sprite.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.sprite.newSpriteSheet(...)
if instance then
  local ok, result = pcall(function() return instance:getFrame(1) end)
  print("SpriteSheet:getFrame ->", ok, result)
end

--@api-stub: SpriteSheet:getFrameCount
-- Returns the total number of frames in the sheet.
-- Call when you need to read frame count.
-- Build a SpriteSheet via the appropriate lurek.sprite.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.sprite.newSpriteSheet(...)
if instance then
  local ok, result = pcall(function() return instance:getFrameCount() end)
  print("SpriteSheet:getFrameCount ->", ok, result)
end

--@api-stub: SpriteSheet:getRow
-- Returns a sequential table of quad tables for every frame in the given row.
-- Call when you need to read row.
-- Build a SpriteSheet via the appropriate lurek.sprite.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.sprite.newSpriteSheet(...)
if instance then
  local ok, result = pcall(function() return instance:getRow(nil) end)
  print("SpriteSheet:getRow ->", ok, result)
end

--@api-stub: SpriteSheet:getColumn
-- Returns a sequential table of quad tables for every frame in the given column.
-- Call when you need to read column.
-- Build a SpriteSheet via the appropriate lurek.sprite.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.sprite.newSpriteSheet(...)
if instance then
  local ok, result = pcall(function() return instance:getColumn(nil) end)
  print("SpriteSheet:getColumn ->", ok, result)
end

--@api-stub: SpriteSheet:getGroupFrames
-- Returns a sequential table of quad tables for the named frame group, or nil.
-- Call when you need to read group frames.
-- Build a SpriteSheet via the appropriate lurek.sprite.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.sprite.newSpriteSheet(...)
if instance then
  local ok, result = pcall(function() return instance:getGroupFrames("name") end)
  print("SpriteSheet:getGroupFrames ->", ok, result)
end

--@api-stub: SpriteSheet:getGroupNames
-- Returns a sequential table of all defined group names.
-- Call when you need to read group names.
-- Build a SpriteSheet via the appropriate lurek.sprite.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.sprite.newSpriteSheet(...)
if instance then
  local ok, result = pcall(function() return instance:getGroupNames() end)
  print("SpriteSheet:getGroupNames ->", ok, result)
end

--@api-stub: SpriteSheet:getFrameSize
-- Returns the width and height of a single frame cell in pixels.
-- Call when you need to read frame size.
-- Build a SpriteSheet via the appropriate lurek.sprite.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.sprite.newSpriteSheet(...)
if instance then
  local ok, result = pcall(function() return instance:getFrameSize() end)
  print("SpriteSheet:getFrameSize ->", ok, result)
end

--@api-stub: SpriteSheet:getGridSize
-- Returns the number of columns and rows in the grid.
-- Call when you need to read grid size.
-- Build a SpriteSheet via the appropriate lurek.sprite.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.sprite.newSpriteSheet(...)
if instance then
  local ok, result = pcall(function() return instance:getGridSize() end)
  print("SpriteSheet:getGridSize ->", ok, result)
end

--@api-stub: SpriteSheet:drawToImage
-- Renders the sheet grid as a debug view into a new ImageData.
-- Call when you need to render to image.
-- Build a SpriteSheet via the appropriate lurek.sprite.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.sprite.newSpriteSheet(...)
if instance then
  local ok, result = pcall(function() return instance:drawToImage(100, 100) end)
  print("SpriteSheet:drawToImage ->", ok, result)
end

-- ── SpriteAtlas methods ──

--@api-stub: SpriteAtlas:getEntry
-- Returns the named region as a table `{name, x, y, w, h, rotated}`, or nil.
-- Call when you need to read entry.
-- Build a SpriteAtlas via the appropriate lurek.sprite.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.sprite.newSpriteAtlas(...)
if instance then
  local ok, result = pcall(function() return instance:getEntry("name") end)
  print("SpriteAtlas:getEntry ->", ok, result)
end

--@api-stub: SpriteAtlas:getByIndex
-- Returns the region at the given 1-based insertion index, or nil.
-- Call when you need to read by index.
-- Build a SpriteAtlas via the appropriate lurek.sprite.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.sprite.newSpriteAtlas(...)
if instance then
  local ok, result = pcall(function() return instance:getByIndex(1) end)
  print("SpriteAtlas:getByIndex ->", ok, result)
end

--@api-stub: SpriteAtlas:entryCount
-- Returns the total number of named regions in the atlas.
-- Call when you need to invoke entry count.
-- Build a SpriteAtlas via the appropriate lurek.sprite.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.sprite.newSpriteAtlas(...)
if instance then
  local ok, result = pcall(function() return instance:entryCount() end)
  print("SpriteAtlas:entryCount ->", ok, result)
end

--@api-stub: SpriteAtlas:entryNames
-- Returns a sequential table of all region names.
-- Call when you need to invoke entry names.
-- Build a SpriteAtlas via the appropriate lurek.sprite.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.sprite.newSpriteAtlas(...)
if instance then
  local ok, result = pcall(function() return instance:entryNames() end)
  print("SpriteAtlas:entryNames ->", ok, result)
end

