-- content/examples/sprite.lua
-- Hand-written coverage of the lurek.sprite API (18 items).
--
-- The sprite namespace is a pure layout/data API: it computes UV
-- quad tables `{x, y, w, h}` from a sprite-sheet grid or atlas,
-- registers named frame groups (e.g. "walk_down"), and parses
-- TexturePacker / Aseprite JSON. Drawing is done by feeding those
-- quads to lurek.render.draw — the snippets here focus on the
-- sprite side and stay CPU-only so the file loads without a GPU.
--
-- Run: cargo run -- content/examples/sprite.lua

-- Helper: return file contents or nil (lurek.filesystem.read throws on missing files).
local function tryRead(path)
  local ok, data = pcall(lurek.filesystem.read, path)
  return ok and data or nil
end

-- ── lurek.sprite.* functions ──

--@api-stub: lurek.sprite.newSheet
-- Creates a sprite sheet with a uniform grid of `frame_w × frame_h` frames.
-- Use for hand-rolled sheets where every frame is the same size; texture w/h must be exact multiples of frame w/h.
do  -- lurek.sprite.newSheet
  -- 256x192 texture sliced into 32x32 cells → 8 cols × 6 rows = 48 frames.
  local sheet = lurek.sprite.newSheet(256, 192, 32, 32)
  local cols, rows = sheet:getGridSize()
  lurek.log.info("sheet ready: " .. cols .. "x" .. rows .. " (" .. sheet:getFrameCount() .. " frames)", "sprite")
end

--@api-stub: lurek.sprite.newRPGMakerSheet
-- Creates an RPGMaker VX/Ace character sheet (3 cols × 4 rows) with "down", "left", "right", "up" groups.
-- Pass the texture pixel size; the helper derives the 12-frame layout and pre-names the four direction groups.
do  -- lurek.sprite.newRPGMakerSheet
  local hero = lurek.sprite.newRPGMakerSheet(96, 128)
  for _, dir in ipairs({ "down", "left", "right", "up" }) do
    local frames = hero:getGroupFrames(dir)
    lurek.log.info("hero." .. dir .. " has " .. #frames .. " walk frames", "sprite")
  end
end

--@api-stub: lurek.sprite.parseAtlas
-- Parses a TexturePacker JSON string (hash or array format) and returns a SpriteAtlas.
-- Read the .json off disk with lurek.filesystem.read first; raises a Lua error on malformed JSON.
do  -- lurek.sprite.parseAtlas
  pcall(function()
    local json = tryRead("img/ui_atlas.json")
    if json then
      local atlas = lurek.sprite.parseAtlas(json)
      lurek.log.info("ui atlas loaded with " .. atlas:entryCount() .. " regions", "sprite")
    end
  end)
end

--@api-stub: lurek.sprite.newAtlasSheet
-- Builds a SpriteSheet whose frames come from named entries in a SpriteAtlas.
-- Use when the artist exported a packed atlas instead of a uniform grid; each region also becomes a single-frame named group.
do  -- lurek.sprite.newAtlasSheet
  pcall(function()
    local json = tryRead("img/items.json")
    if json then
      local atlas = lurek.sprite.parseAtlas(json)
      local sheet = lurek.sprite.newAtlasSheet(atlas, 512, 512)
      local sword = sheet:getGroupFrames("sword_iron")
      if sword then lurek.log.info("sword frame at " .. sword[1].x .. "," .. sword[1].y, "sprite") end
    end
  end)
end

--@api-stub: lurek.sprite.parseAsepriteAtlas
-- Parses an Aseprite JSON export string and returns a `SpriteAtlas`.
-- Use the "Export Sprite Sheet" command in Aseprite; both array and hash JSON layouts are accepted.
do  -- lurek.sprite.parseAsepriteAtlas
  pcall(function()
    local json = tryRead("img/hero.json")
    if json then
      local atlas = lurek.sprite.parseAsepriteAtlas(json)
      for _, name in ipairs(atlas:entryNames()) do
        lurek.log.debug("aseprite tag: " .. name, "sprite")
      end
    end
  end)
end

-- ── SpriteSheet methods ──

--@api-stub: SpriteSheet:getFrame
-- Returns the quad for the 0-based frame index, or nil if out of range.
-- Index 0 is the top-left frame; pair with lurek.render.draw(image, quad, x, y) to blit a single frame.
do  -- SpriteSheet:getFrame
  local sheet = lurek.sprite.newSheet(128, 64, 32, 32)  -- 4 cols × 2 rows
  local quad = sheet:getFrame(0)
  if quad then
    lurek.log.info("frame 0 uv = " .. quad.x .. "," .. quad.y .. " " .. quad.w .. "x" .. quad.h, "sprite")
  end
end

--@api-stub: SpriteSheet:getFrameCount
-- Returns the total number of frames in the sheet.
-- Use to drive an animation index modulo: `local f = math.floor(t * fps) % sheet:getFrameCount()`.
do  -- SpriteSheet:getFrameCount
  local sheet = lurek.sprite.newSheet(192, 32, 32, 32)
  local count = sheet:getFrameCount()
  local frame_at_t = math.floor(1.5 * 8) % count  -- 8 fps, t=1.5s
  lurek.log.info("animating " .. count .. " frames; current=" .. frame_at_t, "sprite")
end

--@api-stub: SpriteSheet:getRow
-- Returns a sequential table of quad tables for every frame in the given row.
-- Handy for direction strips: row 0 = walk-down, row 1 = walk-left, etc. — pass the row a character is facing.
do  -- SpriteSheet:getRow
  local sheet = lurek.sprite.newSheet(96, 128, 32, 32)  -- 3 cols × 4 rows
  local walk_down = sheet:getRow(0)
  for i, q in ipairs(walk_down) do
    lurek.log.debug("walk_down[" .. i .. "] x=" .. q.x, "sprite")
  end
end

--@api-stub: SpriteSheet:getColumn
-- Returns a sequential table of quad tables for every frame in the given column.
-- Useful for "stance" strips where each column stacks one pose across animation states (idle/run/jump).
do  -- SpriteSheet:getColumn
  local sheet = lurek.sprite.newSheet(96, 128, 32, 32)
  local first_col = sheet:getColumn(0)
  lurek.log.info("column 0 holds " .. #first_col .. " stacked poses", "sprite")
end

--@api-stub: SpriteSheet:getGroupFrames
-- Returns a sequential table of quad tables for the named frame group, or nil.
-- Returns nil if the group was never registered — guard with `if frames then` before iterating.
do  -- SpriteSheet:getGroupFrames
  local sheet = lurek.sprite.newRPGMakerSheet(96, 128)
  local frames = sheet:getGroupFrames("up")
  if frames then
    local current = frames[1 + (os.time() % #frames)]
    lurek.log.info("hero up-frame uv x=" .. current.x .. " y=" .. current.y, "sprite")
  end
end

--@api-stub: SpriteSheet:getGroupNames
-- Returns a sequential table of all defined group names.
-- Iterate to build a debug menu of available animations or to validate that an artist named every clip.
do  -- SpriteSheet:getGroupNames
  local sheet = lurek.sprite.newRPGMakerSheet(96, 128)
  local names = sheet:getGroupNames()
  table.sort(names)
  lurek.log.info("animation groups: " .. table.concat(names, ", "), "sprite")
end

--@api-stub: SpriteSheet:getFrameSize
-- Returns the width and height of a single frame cell in pixels.
-- Use as the draw size when computing hitboxes or centring sprites around their pivot.
do  -- SpriteSheet:getFrameSize
  local sheet = lurek.sprite.newSheet(256, 256, 64, 64)
  local fw, fh = sheet:getFrameSize()
  local hitbox = { w = fw - 8, h = fh - 4 }  -- shrink a few px around the sprite
  lurek.log.info("hitbox derived: " .. hitbox.w .. "x" .. hitbox.h, "sprite")
end

--@api-stub: SpriteSheet:getGridSize
-- Returns the number of columns and rows in the grid.
-- Validate at load time that the artist's sheet matches expected dimensions before using row/column lookups.
do  -- SpriteSheet:getGridSize
  local sheet = lurek.sprite.newSheet(96, 128, 32, 32)
  local cols, rows = sheet:getGridSize()
  if cols ~= 3 or rows ~= 4 then
    lurek.log.error("expected 3x4 grid, got " .. cols .. "x" .. rows, "sprite")
  end
end

--@api-stub: SpriteSheet:drawToImage
-- Renders the sheet grid as a debug view into a new ImageData.
-- Frame borders are red, group-start frames green; save with imgdata:encode("png", path) for an offline overview.
do  -- SpriteSheet:drawToImage
  local sheet = lurek.sprite.newRPGMakerSheet(96, 128)
  local debug_img = sheet:drawToImage(192, 256)  -- 2x scale preview
  lurek.log.info("debug overlay generated: " .. tostring(debug_img), "sprite")
end

-- ── SpriteAtlas methods ──

--@api-stub: SpriteAtlas:getEntry
-- Returns the named region as a table `{name, x, y, w, h, rotated}`, or nil.
-- The `rotated` flag tells the renderer to draw the source quad 90° CCW (TexturePacker rotation packing).
do  -- SpriteAtlas:getEntry
  local json = tryRead("img/ui.json")
  if json then
    local atlas = lurek.sprite.parseAtlas(json)
    local btn = atlas:getEntry("button_play")
    if btn then
      lurek.log.info("button_play at " .. btn.x .. "," .. btn.y .. " rotated=" .. tostring(btn.rotated), "sprite")
    end
  end
end

--@api-stub: SpriteAtlas:getByIndex
-- Returns the region at the given 1-based insertion index, or nil.
-- Use to iterate atlas regions in export order (handy for cycling through tiles in a tileset preview).
do  -- SpriteAtlas:getByIndex
  local json = tryRead("img/tiles.json")
  if json then
    local atlas = lurek.sprite.parseAtlas(json)
    for i = 1, math.min(atlas:entryCount(), 5) do
      local e = atlas:getByIndex(i)
      lurek.log.debug("tile #" .. i .. " = " .. e.name, "sprite")
    end
  end
end

--@api-stub: SpriteAtlas:entryCount
-- Returns the total number of named regions in the atlas.
-- Use to size preallocated tables, paginate a debug atlas viewer, or sanity-check that an export was complete.
do  -- SpriteAtlas:entryCount
  local json = tryRead("img/ui.json")
  if json then
    local atlas = lurek.sprite.parseAtlas(json)
    local n = atlas:entryCount()
    if n == 0 then lurek.log.warn("ui atlas is empty — check exporter settings", "sprite") end
    lurek.log.info("atlas has " .. n .. " regions", "sprite")
  end
end

--@api-stub: SpriteAtlas:entryNames
-- Returns a sequential table of all region names.
-- Build an in-game asset browser by sorting these names and filtering by prefix (e.g. "icon_*").
do  -- SpriteAtlas:entryNames
  local json = tryRead("img/ui.json")
  if json then
    local atlas = lurek.sprite.parseAtlas(json)
    local icons = {}
    for _, n in ipairs(atlas:entryNames()) do
      if n:sub(1, 5) == "icon_" then table.insert(icons, n) end
    end
    lurek.log.info("found " .. #icons .. " icon regions", "sprite")
  end
end
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
--     `function lurek.draw() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/sprite.lua

-- ── lurek.sprite.* functions ──

--@api-stub: SpriteAtlas:getFlipped
-- Returns a flipped variant entry (flipped-X, flipped-Y, or both) for a sprite name.
-- Use for mirroring walk cycles without duplicate atlas entries.
do  -- SpriteAtlas:getFlipped
  local atlas = lurek.sprite.parseAtlas('{"frames":{},"meta":{"app":"TexturePacker","version":"1.0","image":"sheet.png","format":"RGBA8888","size":{"w":256,"h":256},"scale":"1"}}')
  local entry = atlas:getFlipped("hero_run_01", true, false)
  lurek.log.info("flipped entry: " .. tostring(entry ~= nil), "sprite")
end

--@api-stub: SpriteSheet:nameGroup
-- Assigns a friendly group name to a row of frames for convenient clip building.
-- After naming, getGroupFrames("walk") returns that row's frame indices.
do  -- SpriteSheet:nameGroup
  local sheet = lurek.sprite.newSheet(256, 256, 32, 32)
  sheet:nameGroup("walk", 0, 4)
  sheet:nameGroup("run",  4, 4)
  local frames = sheet:getGroupFrames("walk")
  lurek.log.info("walk frames: " .. #frames, "sprite")
end

-- =============================================================================
-- STUBS: 4 uncovered lurek.sprite API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SpriteAtlas methods
-- -----------------------------------------------------------------------------

-- ---- Stub: SpriteAtlas:type ----------------------------------------------
--@api-stub: SpriteAtlas:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- spriteAtlas_stub:type()  -- -> string
-- (replace spriteAtlas_stub with your real SpriteAtlas instance above)

-- ---- Stub: SpriteAtlas:typeOf --------------------------------------------
--@api-stub: SpriteAtlas:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- spriteAtlas_stub:typeOf("hero")  -- -> boolean
-- (replace spriteAtlas_stub with your real SpriteAtlas instance above)

-- -----------------------------------------------------------------------------
-- SpriteSheet methods
-- -----------------------------------------------------------------------------

-- ---- Stub: SpriteSheet:type ----------------------------------------------
--@api-stub: SpriteSheet:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- spriteSheet_stub:type()  -- -> string
-- (replace spriteSheet_stub with your real SpriteSheet instance above)

-- ---- Stub: SpriteSheet:typeOf --------------------------------------------
--@api-stub: SpriteSheet:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- spriteSheet_stub:typeOf("hero")  -- -> boolean
-- (replace spriteSheet_stub with your real SpriteSheet instance above)
