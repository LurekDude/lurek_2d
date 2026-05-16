-- content/examples/sprite.lua
-- lurek.sprite API examples.
-- Run: cargo run -- content/examples/sprite.lua

--@api-stub: lurek.sprite.newSheet
-- Creates a new sprite sheet by dividing a texture of the given pixel size into a grid of equal-sized frames
do
  -- 256x192 texture sliced into 32x32 cells â†’ 8 cols Ă— 6 rows = 48 frames.
  local sheet = lurek.sprite.newSheet(256, 192, 32, 32)
  local cols, rows = sheet:getGridSize()
  lurek.log.info("sheet ready: " .. cols .. "x" .. rows .. " (" .. sheet:getFrameCount() .. " frames)", "sprite")
end

--@api-stub: lurek.sprite.newRPGMakerSheet
-- Creates a sprite sheet using RPG Maker's standard character layout (4 columns × 4 rows per character block)
do
  local hero = lurek.sprite.newRPGMakerSheet(96, 128)
  for _, dir in ipairs({ "down", "left", "right", "up" }) do
    local frames = hero:getGroupFrames(dir)
    lurek.log.info("hero." .. dir .. " has " .. #frames .. " walk frames", "sprite")
  end
end

--@api-stub: lurek.sprite.parseAtlas
-- Parses a TexturePacker JSON atlas string and returns a sprite atlas object
do
  pcall(function()
    local json = tryRead("img/ui_atlas.json")
    if json then
      local atlas = lurek.sprite.parseAtlas(json)
      lurek.log.info("ui atlas loaded with " .. atlas:entryCount() .. " regions", "sprite")
    end
  end)
end

--@api-stub: lurek.sprite.newAtlasSheet
-- Creates a sprite sheet from an existing atlas, treating each atlas entry as a frame within the given sheet dimensions
do
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
-- Parses an Aseprite JSON atlas string and returns a sprite atlas object
do
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

-- SpriteSheet methods

--@api-stub: SpriteSheet:getFrame
-- Returns the frame of this sprite sheet.
do
  local sheet = lurek.sprite.newSheet(128, 64, 32, 32)  -- 4 cols Ă— 2 rows
  local quad = sheet:getFrame(0)
  if quad then
    lurek.log.info("frame 0 uv = " .. quad.x .. "," .. quad.y .. " " .. quad.w .. "x" .. quad.h, "sprite")
  end
end

--@api-stub: SpriteSheet:getFrameCount
-- Returns the number of frame items in this sprite sheet.
do
  local sheet = lurek.sprite.newSheet(192, 32, 32, 32)
  local count = sheet:getFrameCount()
  local frame_at_t = math.floor(1.5 * 8) % count  -- 8 fps, t=1.5s
  lurek.log.info("animating " .. count .. " frames; current=" .. frame_at_t, "sprite")
end

--@api-stub: SpriteSheet:getRow
-- Returns the row of this sprite sheet.
do
  local sheet = lurek.sprite.newSheet(96, 128, 32, 32)  -- 3 cols Ă— 4 rows
  local walk_down = sheet:getRow(0)
  for i, q in ipairs(walk_down) do
    lurek.log.debug("walk_down[" .. i .. "] x=" .. q.x, "sprite")
  end
end

--@api-stub: SpriteSheet:getColumn
-- Returns the column of this sprite sheet.
do
  local sheet = lurek.sprite.newSheet(96, 128, 32, 32)
  local first_col = sheet:getColumn(0)
  lurek.log.info("column 0 holds " .. #first_col .. " stacked poses", "sprite")
end

--@api-stub: SpriteSheet:getGroupFrames
-- Returns the group frames of this sprite sheet.
do
  local sheet = lurek.sprite.newRPGMakerSheet(96, 128)
  local frames = sheet:getGroupFrames("up")
  if frames then
    local current = frames[1 + (os.time() % #frames)]
    lurek.log.info("hero up-frame uv x=" .. current.x .. " y=" .. current.y, "sprite")
  end
end

--@api-stub: SpriteSheet:getGroupNames
-- Returns the group names of this sprite sheet.
do
  local sheet = lurek.sprite.newRPGMakerSheet(96, 128)
  local names = sheet:getGroupNames()
  table.sort(names)
  lurek.log.info("animation groups: " .. table.concat(names, ", "), "sprite")
end

--@api-stub: SpriteSheet:getFrameSize
-- Returns the frame size of this sprite sheet.
do
  local sheet = lurek.sprite.newSheet(256, 256, 64, 64)
  local fw, fh = sheet:getFrameSize()
  local hitbox = { w = fw - 8, h = fh - 4 }  -- shrink a few px around the sprite
  lurek.log.info("hitbox derived: " .. hitbox.w .. "x" .. hitbox.h, "sprite")
end

--@api-stub: SpriteSheet:getGridSize
-- Returns the grid size of this sprite sheet.
do
  local sheet = lurek.sprite.newSheet(96, 128, 32, 32)
  local cols, rows = sheet:getGridSize()
  if cols ~= 3 or rows ~= 4 then
    lurek.log.error("expected 3x4 grid, got " .. cols .. "x" .. rows, "sprite")
  end
end

--@api-stub: SpriteSheet:drawToImage
-- Draws or renders this sprite sheet to the current render target.
do
  local sheet = lurek.sprite.newRPGMakerSheet(96, 128)
  local debug_img = sheet:drawToImage(192, 256)  -- 2x scale preview
  lurek.log.info("debug overlay generated: " .. tostring(debug_img), "sprite")
end

-- SpriteAtlas methods

--@api-stub: SpriteAtlas:getEntry
-- Returns the entry of this sprite atlas.
do
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
-- Returns the by index of this sprite atlas.
do
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
-- Performs the entry count operation on this sprite atlas.
do
  local json = tryRead("img/ui.json")
  if json then
    local atlas = lurek.sprite.parseAtlas(json)
    local n = atlas:entryCount()
    if n == 0 then lurek.log.warn("ui atlas is empty â€” check exporter settings", "sprite") end
    lurek.log.info("atlas has " .. n .. " regions", "sprite")
  end
end

--@api-stub: SpriteAtlas:entryNames
-- Performs the entry names operation on this sprite atlas.
do
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
-- EXAMPLEed coverage of the lurek.sprite API (18 items).
--
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

-- lurek.sprite.* functions

--@api-stub: SpriteAtlas:getFlipped
-- Returns the flipped of this sprite atlas.
do
  local atlas = lurek.sprite.parseAtlas('{"frames":{},"meta":{"app":"TexturePacker","version":"1.0","image":"sheet.png","format":"RGBA8888","size":{"w":256,"h":256},"scale":"1"}}')
  local entry = atlas:getFlipped("hero_run_01", true, false)
  lurek.log.info("flipped entry: " .. tostring(entry ~= nil), "sprite")
end

--@api-stub: SpriteSheet:nameGroup
-- Performs the name group operation on this sprite sheet.
do
  local sheet = lurek.sprite.newSheet(256, 256, 32, 32)
  sheet:nameGroup("walk", 0, 4)
  sheet:nameGroup("run",  4, 4)
  local frames = sheet:getGroupFrames("walk")
  lurek.log.info("walk frames: " .. #frames, "sprite")
end

-- -----------------------------------------------------------------------------
-- SpriteSheet methods
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- LSpriteAtlas methods
-- -----------------------------------------------------------------------------

--@api-stub: LSpriteAtlas:type
-- Returns the type name of this object
do
  local ok_a ---@type boolean
  local sprite_atlas_obj ---@type LSpriteAtlas?
  ok_a, sprite_atlas_obj = pcall(lurek.sprite.parseAtlas, "sprites/atlas.png")
  if not ok_a then sprite_atlas_obj = nil end
  local t = sprite_atlas_obj and sprite_atlas_obj:type() or "LSpriteAtlas"
  lurek.log.info("LSpriteAtlas:type = " .. t, "sprite")
end
--@api-stub: LSpriteAtlas:typeOf
-- Checks whether this object matches the given type name
do
  local ok_a ---@type boolean
  local sprite_atlas_obj ---@type LSpriteAtlas?
  ok_a, sprite_atlas_obj = pcall(lurek.sprite.parseAtlas, "sprites/atlas.png")
  if not ok_a then sprite_atlas_obj = nil end
  lurek.log.info("is LSpriteAtlas: dummy", "sprite")
end
--@api-stub: LSpriteSheet:type
-- Returns the type name of this object
do
  local ok_s ---@type boolean
  local sprite_sheet_obj ---@type LSpriteSheet?
  ok_s, sprite_sheet_obj = pcall(lurek.sprite.newSheet, "sprites/sheet.png", 32, 32)
  if not ok_s then sprite_sheet_obj = nil end
  local t = sprite_sheet_obj and sprite_sheet_obj:type() or "LSpriteSheet"
  lurek.log.info("LSpriteSheet:type = " .. t, "sprite")
end
--@api-stub: LSpriteSheet:typeOf
-- Checks whether this object matches the given type name
do
  local ok_s ---@type boolean
  local sprite_sheet_obj ---@type LSpriteSheet?
  ok_s, sprite_sheet_obj = pcall(lurek.sprite.newSheet, "sprites/sheet.png", 32, 32)
  if not ok_s then sprite_sheet_obj = nil end
  lurek.log.info("is LSpriteSheet: " .. tostring(sprite_sheet_obj and sprite_sheet_obj:typeOf("LSpriteSheet") or false), "sprite")
  lurek.log.info("is wrong: " .. tostring(sprite_sheet_obj and sprite_sheet_obj:typeOf("Unknown") or false), "sprite")
end


--@api-stub: LGroupedFrame:type
-- Returns the Lua-visible type name string for this grouped frame handle.
do
  local batch = lurek.sprite.newBatch("assets/sheet.png", 32, 32)
  local gf = batch:addGroup(1, 2)
  lurek.log.info(gf:type(), "sprite")
end

--@api-stub: LGroupedFrame:typeOf
-- Returns true if this grouped frame handle matches the given type name string.
do
  local batch = lurek.sprite.newBatch("assets/sheet.png", 32, 32)
  local gf = batch:addGroup(1, 2)
  lurek.log.info(tostring(gf:typeOf("LGroupedFrame")), "sprite")
end
