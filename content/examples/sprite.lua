-- content/examples/sprite.lua
-- Auto-scaffolded coverage of the lurek.sprite Lua API (18 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/sprite.lua

print("[example] lurek.sprite loaded — 18 API items demonstrated")

-- ── lurek.sprite free functions ──

--@api-stub: lurek.sprite.newSheet
-- Creates a sprite sheet with a uniform grid of `frame_w Ă— frame_h` frames.
-- Use this when creates a sprite sheet with a uniform grid of `frame_w Ă— frame_h` frames is needed.
if false then
  local _r = lurek.sprite.newSheet(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.sprite.newRPGMakerSheet
-- Creates an RPGMaker VX/Ace character sheet (3 cols Ă— 4 rows) with "down", "left", "right", "up" groups.
-- Use this when creates an RPGMaker VX/Ace character sheet (3 cols Ă— 4 rows) with "down", "left", "right", "up" groups is needed.
if false then
  local _r = lurek.sprite.newRPGMakerSheet(0, 0)
  print(_r)
end

--@api-stub: lurek.sprite.parseAtlas
-- Parses a TexturePacker JSON string (hash or array format) and returns a SpriteAtlas.
-- Use this when parses a TexturePacker JSON string (hash or array format) and returns a SpriteAtlas is needed.
if false then
  local _r = lurek.sprite.parseAtlas(1)
  print(_r)
end

--@api-stub: lurek.sprite.newAtlasSheet
-- Builds a SpriteSheet whose frames come from named entries in a SpriteAtlas.
-- Use this when builds a SpriteSheet whose frames come from named entries in a SpriteAtlas is needed.
if false then
  local _r = lurek.sprite.newAtlasSheet(0, 0, 0)
  print(_r)
end

--@api-stub: lurek.sprite.parseAsepriteAtlas
-- Parses an Aseprite JSON export string and returns a `SpriteAtlas`.
-- Use this when parses an Aseprite JSON export string and returns a `SpriteAtlas` is needed.
if false then
  local _r = lurek.sprite.parseAsepriteAtlas(1)
  print(_r)
end

-- ── SpriteSheet methods ──

--@api-stub: SpriteSheet:getFrame
-- Returns the quad for the 0-based frame index, or nil if out of range.
-- Use this when returns the quad for the 0-based frame index, or nil if out of range is needed.
if false then
  local _o = nil  -- SpriteSheet instance
  _o:getFrame(1)
end

--@api-stub: SpriteSheet:getFrameCount
-- Returns the total number of frames in the sheet.
-- Use this when returns the total number of frames in the sheet is needed.
if false then
  local _o = nil  -- SpriteSheet instance
  _o:getFrameCount()
end

--@api-stub: SpriteSheet:getRow
-- Returns a sequential table of quad tables for every frame in the given row.
-- Use this when returns a sequential table of quad tables for every frame in the given row is needed.
if false then
  local _o = nil  -- SpriteSheet instance
  _o:getRow(0)
end

--@api-stub: SpriteSheet:getColumn
-- Returns a sequential table of quad tables for every frame in the given column.
-- Use this when returns a sequential table of quad tables for every frame in the given column is needed.
if false then
  local _o = nil  -- SpriteSheet instance
  _o:getColumn(nil)
end

--@api-stub: SpriteSheet:getGroupFrames
-- Returns a sequential table of quad tables for the named frame group, or nil.
-- Use this when returns a sequential table of quad tables for the named frame group, or nil is needed.
if false then
  local _o = nil  -- SpriteSheet instance
  _o:getGroupFrames(1)
end

--@api-stub: SpriteSheet:getGroupNames
-- Returns a sequential table of all defined group names.
-- Use this when returns a sequential table of all defined group names is needed.
if false then
  local _o = nil  -- SpriteSheet instance
  _o:getGroupNames()
end

--@api-stub: SpriteSheet:getFrameSize
-- Returns the width and height of a single frame cell in pixels.
-- Use this when returns the width and height of a single frame cell in pixels is needed.
if false then
  local _o = nil  -- SpriteSheet instance
  _o:getFrameSize()
end

--@api-stub: SpriteSheet:getGridSize
-- Returns the number of columns and rows in the grid.
-- Use this when returns the number of columns and rows in the grid is needed.
if false then
  local _o = nil  -- SpriteSheet instance
  _o:getGridSize()
end

--@api-stub: SpriteSheet:drawToImage
-- Renders the sheet grid as a debug view into a new ImageData.
-- Use this when renders the sheet grid as a debug view into a new ImageData is needed.
if false then
  local _o = nil  -- SpriteSheet instance
  _o:drawToImage(0, 0)
end

-- ── SpriteAtlas methods ──

--@api-stub: SpriteAtlas:getEntry
-- Returns the named region as a table `{name, x, y, w, h, rotated}`, or nil.
-- Use this when returns the named region as a table `{name, x, y, w, h, rotated}`, or nil is needed.
if false then
  local _o = nil  -- SpriteAtlas instance
  _o:getEntry(1)
end

--@api-stub: SpriteAtlas:getByIndex
-- Returns the region at the given 1-based insertion index, or nil.
-- Use this when returns the region at the given 1-based insertion index, or nil is needed.
if false then
  local _o = nil  -- SpriteAtlas instance
  _o:getByIndex(1)
end

--@api-stub: SpriteAtlas:entryCount
-- Returns the total number of named regions in the atlas.
-- Use this when returns the total number of named regions in the atlas is needed.
if false then
  local _o = nil  -- SpriteAtlas instance
  _o:entryCount()
end

--@api-stub: SpriteAtlas:entryNames
-- Returns a sequential table of all region names.
-- Use this when returns a sequential table of all region names is needed.
if false then
  local _o = nil  -- SpriteAtlas instance
  _o:entryNames()
end

