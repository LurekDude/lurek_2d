-- content/examples/sprite.lua
-- Full coverage of the lurek.sprite API: sprite sheets, atlases, and frame utilities.
-- Run: cargo run -- content/examples/sprite.lua

--@api-stub: lurek.sprite.newSheet
-- Creates a new sprite sheet by dividing a texture into a grid of equal-sized frames
do
  -- A 256x192 pixel texture sliced into 32x32 cells gives 8 columns x 6 rows = 48 frames.
  -- This is the most common way to set up a character or tileset sprite sheet.
  local sheet = lurek.sprite.newSheet(256, 192, 32, 32)
  local cols, rows = sheet:getGridSize()
  lurek.log.info("sheet ready: " .. cols .. "x" .. rows .. " (" .. sheet:getFrameCount() .. " frames)", "sprite")
end

--@api-stub: lurek.sprite.newRPGMakerSheet
-- Creates a sprite sheet using RPG Maker's standard character layout (4 columns x 4 rows per character)
do
  -- RPG Maker character sheets have a fixed layout: 4 directions, 3 walk frames each.
  -- Pass the full texture dimensions; the engine calculates frame size automatically.
  local hero = lurek.sprite.newRPGMakerSheet(96, 128)
  for _, dir in ipairs({"down", "left", "right", "up"}) do
    local frames = hero:getGroupFrames(dir)
    lurek.log.info("hero." .. dir .. " has " .. #frames .. " walk frames", "sprite")
  end
end

--@api-stub: lurek.sprite.parseAtlas
-- Parses a TexturePacker JSON atlas string and returns a sprite atlas with named regions
do
  -- TexturePacker exports a JSON file listing every packed sprite's position and size.
  -- Parse the raw JSON string to get an LSpriteAtlas for named region lookups.
  local json_data = '{"frames":{"btn_play":{"frame":{"x":0,"y":0,"w":64,"h":32},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":64,"h":32},"sourceSize":{"w":64,"h":32}},"btn_quit":{"frame":{"x":64,"y":0,"w":64,"h":32},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":64,"h":32},"sourceSize":{"w":64,"h":32}}},"meta":{"app":"TexturePacker","version":"1.0","image":"ui.png","format":"RGBA8888","size":{"w":128,"h":32},"scale":"1"}}'
  local atlas = lurek.sprite.parseAtlas(json_data)
  lurek.log.info("ui atlas loaded with " .. atlas:entryCount() .. " regions", "sprite")
end

--@api-stub: lurek.sprite.newAtlasSheet
-- Creates a sprite sheet from an existing atlas, treating each atlas entry as a frame
do
  -- Useful when you have a packed atlas but still want grid-style frame indexing.
  -- Each atlas entry becomes one frame in the resulting sheet.
  local json_data = '{"frames":{"sword_01":{"frame":{"x":0,"y":0,"w":32,"h":32},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":32,"h":32},"sourceSize":{"w":32,"h":32}},"sword_02":{"frame":{"x":32,"y":0,"w":32,"h":32},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":32,"h":32},"sourceSize":{"w":32,"h":32}}},"meta":{"app":"TexturePacker","version":"1.0","image":"items.png","format":"RGBA8888","size":{"w":64,"h":32},"scale":"1"}}'
  local atlas = lurek.sprite.parseAtlas(json_data)
  local sheet = lurek.sprite.newAtlasSheet(atlas, 64, 32)
  lurek.log.info("atlas-sheet has " .. sheet:getFrameCount() .. " frames", "sprite")
end

--@api-stub: lurek.sprite.parseAsepriteAtlas
-- Parses an Aseprite JSON atlas string and returns a sprite atlas with frame tags as entries
do
  -- Aseprite exports animation data as JSON. Each frame tag (idle, run, attack) becomes
  -- a named entry in the atlas, making it easy to look up animation regions by tag name.
  local json_data = '{"frames":{"hero 0.ase":{"frame":{"x":0,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":100}},"meta":{"app":"http://www.aseprite.org/","version":"1.3","image":"hero.png","format":"RGBA8888","size":{"w":16,"h":16},"scale":"1","frameTags":[{"name":"idle","from":0,"to":0,"direction":"forward"}]}}'
  local atlas = lurek.sprite.parseAsepriteAtlas(json_data)
  for _, name in ipairs(atlas:entryNames()) do
    lurek.log.info("aseprite tag: " .. name, "sprite")
  end
end

--@api-stub: LSpriteAtlas:entryCount
-- Returns the total number of entries (named sprite regions) in the atlas
do
  -- Use entryCount to validate that the atlas loaded correctly or to iterate
  -- by numeric index when you don't know the names ahead of time.
  local json_data = '{"frames":{"icon_health":{"frame":{"x":0,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16}},"icon_mana":{"frame":{"x":16,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16}},"icon_stamina":{"frame":{"x":32,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16}}},"meta":{"app":"TexturePacker","version":"1.0","image":"icons.png","format":"RGBA8888","size":{"w":48,"h":16},"scale":"1"}}'
  local atlas = lurek.sprite.parseAtlas(json_data)
  local n = atlas:entryCount()
  if n == 0 then
    lurek.log.warn("atlas is empty - check exporter settings", "sprite")
  else
    lurek.log.info("atlas has " .. n .. " sprite regions", "sprite")
  end
end

--@api-stub: LSpriteAtlas:entryNames
-- Returns an array of all entry name strings in the atlas
do
  -- Useful for building UI inventories or filtering entries by naming convention.
  -- For example, find all icons prefixed with "icon_" in a packed UI atlas.
  local json_data = '{"frames":{"icon_sword":{"frame":{"x":0,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16}},"icon_shield":{"frame":{"x":16,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16}},"bg_panel":{"frame":{"x":32,"y":0,"w":64,"h":64},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":64,"h":64},"sourceSize":{"w":64,"h":64}}},"meta":{"app":"TexturePacker","version":"1.0","image":"ui.png","format":"RGBA8888","size":{"w":96,"h":64},"scale":"1"}}'
  local atlas = lurek.sprite.parseAtlas(json_data)
  local icons = {}
  for _, name in ipairs(atlas:entryNames()) do
    if name:sub(1, 5) == "icon_" then
      table.insert(icons, name)
    end
  end
  lurek.log.info("found " .. #icons .. " icon regions out of " .. atlas:entryCount() .. " total", "sprite")
end

--@api-stub: LSpriteAtlas:getByIndex
-- Returns a sprite region by its 1-based index in the atlas
do
  -- Iterate entries by numeric index when building a preview grid or debug overlay.
  -- Each entry is a table: {name, x, y, w, h, rotated}.
  local json_data = '{"frames":{"tile_grass":{"frame":{"x":0,"y":0,"w":32,"h":32},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":32,"h":32},"sourceSize":{"w":32,"h":32}},"tile_stone":{"frame":{"x":32,"y":0,"w":32,"h":32},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":32,"h":32},"sourceSize":{"w":32,"h":32}}},"meta":{"app":"TexturePacker","version":"1.0","image":"tiles.png","format":"RGBA8888","size":{"w":64,"h":32},"scale":"1"}}'
  local atlas = lurek.sprite.parseAtlas(json_data)
  for i = 1, atlas:entryCount() do
    local entry = atlas:getByIndex(i)
    lurek.log.info("tile #" .. i .. " = " .. entry.name .. " at " .. entry.x .. "," .. entry.y, "sprite")
  end
end

--@api-stub: LSpriteAtlas:getEntry
-- Looks up a named sprite region in the atlas by filename or tag
do
  -- Direct name lookup is the fastest way to draw a specific UI element or item icon.
  -- Returns {name, x, y, w, h, rotated} or nil if the name is not found.
  local json_data = '{"frames":{"btn_play":{"frame":{"x":0,"y":0,"w":120,"h":40},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":120,"h":40},"sourceSize":{"w":120,"h":40}},"btn_settings":{"frame":{"x":120,"y":0,"w":120,"h":40},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":120,"h":40},"sourceSize":{"w":120,"h":40}}},"meta":{"app":"TexturePacker","version":"1.0","image":"buttons.png","format":"RGBA8888","size":{"w":240,"h":40},"scale":"1"}}'
  local atlas = lurek.sprite.parseAtlas(json_data)
  local btn = atlas:getEntry("btn_play")
  if btn then
    lurek.log.info("btn_play: " .. btn.w .. "x" .. btn.h .. " at " .. btn.x .. "," .. btn.y, "sprite")
  else
    lurek.log.warn("btn_play not found in atlas", "sprite")
  end
end

--@api-stub: LSpriteAtlas:getFlipped
-- Returns a copy of a named atlas entry with flip flags applied for mirrored drawing
do
  -- Flipping avoids duplicating art: store only the right-facing sprite, then flip for left.
  -- The returned entry adds flip_x and flip_y boolean fields to guide the renderer.
  local json_data = '{"frames":{"enemy_run":{"frame":{"x":0,"y":0,"w":48,"h":48},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":48,"h":48},"sourceSize":{"w":48,"h":48}}},"meta":{"app":"TexturePacker","version":"1.0","image":"enemies.png","format":"RGBA8888","size":{"w":48,"h":48},"scale":"1"}}'
  local atlas = lurek.sprite.parseAtlas(json_data)
  local facing_left = atlas:getFlipped("enemy_run", true, false)
  if facing_left then
    lurek.log.info("flipped entry: flip_x=" .. tostring(facing_left.flip_x) .. " flip_y=" .. tostring(facing_left.flip_y), "sprite")
  end
end

--@api-stub: LSpriteAtlas:type
-- Returns the type name string for this atlas object (always "LSpriteAtlas")
do
  -- Useful for runtime type checks in systems that handle multiple object types.
  local json_data = '{"frames":{},"meta":{"app":"TexturePacker","version":"1.0","image":"empty.png","format":"RGBA8888","size":{"w":1,"h":1},"scale":"1"}}'
  local atlas = lurek.sprite.parseAtlas(json_data)
  lurek.log.info("atlas type: " .. atlas:type(), "sprite")
end

--@api-stub: LSpriteAtlas:typeOf
-- Checks whether this atlas object matches the given type name
do
  -- typeOf supports both the concrete type and parent types like "Object".
  local json_data = '{"frames":{},"meta":{"app":"TexturePacker","version":"1.0","image":"empty.png","format":"RGBA8888","size":{"w":1,"h":1},"scale":"1"}}'
  local atlas = lurek.sprite.parseAtlas(json_data)
  local is_atlas = atlas:typeOf("LSpriteAtlas")
  local is_wrong = atlas:typeOf("LSpriteSheet")
  lurek.log.info("typeOf LSpriteAtlas: " .. tostring(is_atlas) .. ", typeOf LSpriteSheet: " .. tostring(is_wrong), "sprite")
end

--@api-stub: LSpriteSheet:getFrame
-- Returns the UV quad for a single frame by its 1-based index
do
  -- Each frame is a quad table {x, y, w, h} with normalized UV coordinates.
  -- Use this to draw one specific frame from the sheet.
  local sheet = lurek.sprite.newSheet(128, 64, 32, 32) -- 4 cols x 2 rows = 8 frames
  local quad = sheet:getFrame(1)
  if quad then
    lurek.log.info("frame 1 UV: " .. quad.x .. "," .. quad.y .. " size " .. quad.w .. "x" .. quad.h, "sprite")
  end
end

--@api-stub: LSpriteSheet:getFrameCount
-- Returns the total number of frames in this sprite sheet (columns x rows)
do
  -- Knowing the frame count lets you loop animations and clamp indices safely.
  local sheet = lurek.sprite.newSheet(192, 64, 32, 32) -- 6 cols x 2 rows
  local count = sheet:getFrameCount()
  -- Simulate picking a frame at 8 fps after 1.5 seconds
  local fps = 8
  local time = 1.5
  local frame_idx = (math.floor(time * fps) % count) + 1
  lurek.log.info("animating " .. count .. " frames, at t=1.5s showing frame " .. frame_idx, "sprite")
end

--@api-stub: LSpriteSheet:getFrameSize
-- Returns the pixel width and height of a single frame cell
do
  -- Use frame size to derive hitboxes, collision rects, or scale factors.
  local sheet = lurek.sprite.newSheet(256, 256, 64, 64)
  local fw, fh = sheet:getFrameSize()
  -- Shrink the hitbox by a few pixels on each side for fairer gameplay
  local hitbox_w = fw - 8
  local hitbox_h = fh - 4
  lurek.log.info("frame " .. fw .. "x" .. fh .. " -> hitbox " .. hitbox_w .. "x" .. hitbox_h, "sprite")
end

--@api-stub: LSpriteSheet:getGridSize
-- Returns the number of columns and rows in the sprite sheet grid
do
  -- Grid size tells you how your texture is divided without needing to recompute.
  local sheet = lurek.sprite.newSheet(96, 128, 32, 32)
  local cols, rows = sheet:getGridSize()
  lurek.log.info("grid: " .. cols .. " cols x " .. rows .. " rows", "sprite")
end

--@api-stub: LSpriteSheet:getRow
-- Returns all frame quads in the given row (0-based) of the sprite sheet
do
  -- In many sheets, each row represents a different animation direction.
  -- Row 0 = walk down, row 1 = walk left, row 2 = walk right, row 3 = walk up.
  local sheet = lurek.sprite.newSheet(96, 128, 32, 32) -- 3 cols x 4 rows
  local walk_down = sheet:getRow(0)
  lurek.log.info("walk_down row has " .. #walk_down .. " frames", "sprite")
  for i, q in ipairs(walk_down) do
    lurek.log.debug("  frame " .. i .. ": x=" .. q.x .. " y=" .. q.y, "sprite")
  end
end

--@api-stub: LSpriteSheet:getColumn
-- Returns all frame quads in the given column (0-based) of the sprite sheet
do
  -- Columns are useful when animations are stacked vertically (e.g., tile variations).
  local sheet = lurek.sprite.newSheet(96, 128, 32, 32)
  local first_col = sheet:getColumn(0)
  lurek.log.info("column 0 holds " .. #first_col .. " stacked poses", "sprite")
end

--@api-stub: LSpriteSheet:getGroupFrames
-- Returns the frame quads for a named animation group
do
  -- Named groups let you access animation sequences by name instead of raw indices.
  -- RPG Maker sheets define groups automatically; custom sheets need nameGroup() first.
  local sheet = lurek.sprite.newRPGMakerSheet(96, 128)
  local frames = sheet:getGroupFrames("up")
  if frames then
    -- Cycle through the frames based on the current time
    local idx = 1 + (os.time() % #frames)
    local current = frames[idx]
    lurek.log.info("hero facing up, frame UV x=" .. current.x .. " y=" .. current.y, "sprite")
  end
end

--@api-stub: LSpriteSheet:getGroupNames
-- Returns an array of all named animation group names defined on this sheet
do
  -- List available groups to verify your sheet setup or build animation menus.
  local sheet = lurek.sprite.newRPGMakerSheet(96, 128)
  local names = sheet:getGroupNames()
  table.sort(names)
  lurek.log.info("animation groups: " .. table.concat(names, ", "), "sprite")
end

--@api-stub: LSpriteSheet:nameGroup
-- Defines a named animation group as a contiguous range of frames
do
  -- Call nameGroup after creating a generic sheet to label frame ranges.
  -- Start is 1-based, count is how many consecutive frames belong to the group.
  local sheet = lurek.sprite.newSheet(256, 64, 32, 32) -- 8 cols x 2 rows = 16 frames
  sheet:nameGroup("idle", 1, 4)    -- frames 1-4
  sheet:nameGroup("run", 5, 4)     -- frames 5-8
  sheet:nameGroup("attack", 9, 4)  -- frames 9-12
  sheet:nameGroup("die", 13, 4)    -- frames 13-16
  local run_frames = sheet:getGroupFrames("run")
  lurek.log.info("run group has " .. #run_frames .. " frames", "sprite")
end

--@api-stub: LSpriteSheet:drawToImage
-- Renders the sprite sheet grid into an LImage for debugging or previews
do
  -- Generates a debug overlay image showing all frames laid out. Useful for
  -- checking that your sheet parsed correctly during development.
  local sheet = lurek.sprite.newRPGMakerSheet(96, 128)
  local preview = sheet:drawToImage(192, 256) -- 2x upscale for clarity
  lurek.log.info("debug preview generated: " .. tostring(preview), "sprite")
end

--@api-stub: LSpriteAtlas:type
-- Returns the type name string for this sheet object (always "LSpriteSheet")
do
  local sheet = lurek.sprite.newSheet(64, 64, 32, 32)
  lurek.log.info("sheet type: " .. sheet:type(), "sprite")
end

--@api-stub: LSpriteAtlas:typeOf
-- Checks whether this sheet object matches the given type name
do
  -- typeOf is useful in generic systems that process multiple object types.
  local sheet = lurek.sprite.newSheet(64, 64, 32, 32)
  local is_sheet = sheet:typeOf("LSpriteSheet")
  local is_atlas = sheet:typeOf("LSpriteAtlas")
  lurek.log.info("typeOf LSpriteSheet: " .. tostring(is_sheet) .. ", typeOf LSpriteAtlas: " .. tostring(is_atlas), "sprite")
end

print("content/examples/sprite.lua")
