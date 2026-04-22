-- content/examples/sprite.lua
-- Scaffolded coverage of the lurek.sprite API (18 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/sprite_api.rs   (Lua binding, arg types, return shape)
--   * src/sprite/                 (semantics, side effects)
--   * docs/specs/sprite.md        (canonical reference)
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
-- Run: cargo run -- content/examples/sprite.lua

-- ── lurek.sprite.* functions ──

--@api-stub: lurek.sprite.newSheet
-- Creates a sprite sheet with a uniform grid of `frame_w Ă— frame_h` frames.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: lurek.sprite.newSheet
  local _todo = "TODO: write a real lurek.sprite.newSheet usage example"
  print(_todo)
end

--@api-stub: lurek.sprite.newRPGMakerSheet
-- Creates an RPGMaker VX/Ace character sheet (3 cols Ă— 4 rows) with "down", "left", "right", "up" groups.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: lurek.sprite.newRPGMakerSheet
  local _todo = "TODO: write a real lurek.sprite.newRPGMakerSheet usage example"
  print(_todo)
end

--@api-stub: lurek.sprite.parseAtlas
-- Parses a TexturePacker JSON string (hash or array format) and returns a SpriteAtlas.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: lurek.sprite.parseAtlas
  local _todo = "TODO: write a real lurek.sprite.parseAtlas usage example"
  print(_todo)
end

--@api-stub: lurek.sprite.newAtlasSheet
-- Builds a SpriteSheet whose frames come from named entries in a SpriteAtlas.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: lurek.sprite.newAtlasSheet
  local _todo = "TODO: write a real lurek.sprite.newAtlasSheet usage example"
  print(_todo)
end

--@api-stub: lurek.sprite.parseAsepriteAtlas
-- Parses an Aseprite JSON export string and returns a `SpriteAtlas`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: lurek.sprite.parseAsepriteAtlas
  local _todo = "TODO: write a real lurek.sprite.parseAsepriteAtlas usage example"
  print(_todo)
end

-- ── SpriteSheet methods ──

--@api-stub: SpriteSheet:getFrame
-- Returns the quad for the 0-based frame index, or nil if out of range.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: SpriteSheet:getFrame
  local _todo = "TODO: write a real SpriteSheet:getFrame usage example"
  print(_todo)
end

--@api-stub: SpriteSheet:getFrameCount
-- Returns the total number of frames in the sheet.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: SpriteSheet:getFrameCount
  local _todo = "TODO: write a real SpriteSheet:getFrameCount usage example"
  print(_todo)
end

--@api-stub: SpriteSheet:getRow
-- Returns a sequential table of quad tables for every frame in the given row.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: SpriteSheet:getRow
  local _todo = "TODO: write a real SpriteSheet:getRow usage example"
  print(_todo)
end

--@api-stub: SpriteSheet:getColumn
-- Returns a sequential table of quad tables for every frame in the given column.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: SpriteSheet:getColumn
  local _todo = "TODO: write a real SpriteSheet:getColumn usage example"
  print(_todo)
end

--@api-stub: SpriteSheet:getGroupFrames
-- Returns a sequential table of quad tables for the named frame group, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: SpriteSheet:getGroupFrames
  local _todo = "TODO: write a real SpriteSheet:getGroupFrames usage example"
  print(_todo)
end

--@api-stub: SpriteSheet:getGroupNames
-- Returns a sequential table of all defined group names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: SpriteSheet:getGroupNames
  local _todo = "TODO: write a real SpriteSheet:getGroupNames usage example"
  print(_todo)
end

--@api-stub: SpriteSheet:getFrameSize
-- Returns the width and height of a single frame cell in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: SpriteSheet:getFrameSize
  local _todo = "TODO: write a real SpriteSheet:getFrameSize usage example"
  print(_todo)
end

--@api-stub: SpriteSheet:getGridSize
-- Returns the number of columns and rows in the grid.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: SpriteSheet:getGridSize
  local _todo = "TODO: write a real SpriteSheet:getGridSize usage example"
  print(_todo)
end

--@api-stub: SpriteSheet:drawToImage
-- Renders the sheet grid as a debug view into a new ImageData.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: SpriteSheet:drawToImage
  local _todo = "TODO: write a real SpriteSheet:drawToImage usage example"
  print(_todo)
end

-- ── SpriteAtlas methods ──

--@api-stub: SpriteAtlas:getEntry
-- Returns the named region as a table `{name, x, y, w, h, rotated}`, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: SpriteAtlas:getEntry
  local _todo = "TODO: write a real SpriteAtlas:getEntry usage example"
  print(_todo)
end

--@api-stub: SpriteAtlas:getByIndex
-- Returns the region at the given 1-based insertion index, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: SpriteAtlas:getByIndex
  local _todo = "TODO: write a real SpriteAtlas:getByIndex usage example"
  print(_todo)
end

--@api-stub: SpriteAtlas:entryCount
-- Returns the total number of named regions in the atlas.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: SpriteAtlas:entryCount
  local _todo = "TODO: write a real SpriteAtlas:entryCount usage example"
  print(_todo)
end

--@api-stub: SpriteAtlas:entryNames
-- Returns a sequential table of all region names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/sprite_api.rs and docs/specs/sprite.md).
do  -- TODO: SpriteAtlas:entryNames
  local _todo = "TODO: write a real SpriteAtlas:entryNames usage example"
  print(_todo)
end

