-- content/examples/tilemap.lua
-- Hand-written coverage of the lurek.tilemap API (134 items).
--
-- The lurek.tilemap namespace covers ortho/iso/hex grids, autotiling,
-- chunked sparse maps, large-map culling, TMX/LDtk import, and a
-- block + script driven procedural generator.
--
-- Run: cargo run -- content/examples/tilemap.lua

--@api-stub: lurek.tilemap.newTileSet
-- Creates a new TileSet with the given atlas layout parameters.
-- Pass the firstGid you want this set to occupy in the global ID space; spacing/margin default to 0.
do  -- lurek.tilemap.newTileSet
  local grass = lurek.tilemap.newTileSet(1, 256, 16, 16, 16, 0, 0)
  lurek.log.info("grass tileset gid range " .. grass:getFirstGid() .. ".." .. (grass:getFirstGid() + grass:getTileCount() - 1), "tilemap")
end

--@api-stub: lurek.tilemap.newTileMap
-- Creates a new TileMap with the given tile size and chunk size.
-- Tile size is in pixels; chunk size groups tiles for spatial culling and defaults to 16 if omitted.
do  -- lurek.tilemap.newTileMap
  local map = lurek.tilemap.newTileMap(16, 16, 32)
  lurek.log.info("map tile " .. map:getTileWidth() .. "x" .. map:getTileHeight() .. " chunk=" .. map:getChunkSize(), "tilemap")
end

--@api-stub: lurek.tilemap.newAutoTileSheet
-- Creates a new AutoTileSheet with the given tile dimensions and layout.
-- Layout must be 'blob47', 'composite48', or 'minimal16' — pick to match how your atlas was authored.
do  -- lurek.tilemap.newAutoTileSheet
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  lurek.log.info("autotile sheet '" .. sheet:getLayout() .. "' has " .. sheet:getTileCount() .. " tiles", "tilemap")
end

--@api-stub: lurek.tilemap.newChunkMap
-- Creates a new ChunkMap with the given chunk size.
-- Use ChunkMap for sparse infinite worlds where most coordinates are empty; chunkSize defaults to 16.
do  -- lurek.tilemap.newChunkMap
  local world = lurek.tilemap.newChunkMap(32)
  world:setTile(0, 0, 1)
  world:setTile(1000, -500, 7)
  lurek.log.info("loaded " .. #world:getLoadedChunks() .. " chunks", "tilemap")
end

--@api-stub: lurek.tilemap.newIsoMap
-- Creates a new IsoMap with no levels.
-- levelHeight is the vertical pixel offset between Z-levels; partCount defaults to 4 (floor/N-wall/W-wall/object).
do  -- lurek.tilemap.newIsoMap
  local iso = lurek.tilemap.newIsoMap(32, 32, 64, 32, 24, 4)
  iso:addLevel()
  lurek.log.info("iso map " .. iso:getWidth() .. "x" .. iso:getHeight() .. " parts=" .. iso:getPartCount(), "tilemap")
end

--@api-stub: lurek.tilemap.newMapBlock
-- Creates a new MapBlock with the given dimensions.
-- MapBlocks are reusable map fragments stitched together by MapGen; layers/segmentSize default to 1.
do  -- lurek.tilemap.newMapBlock
  local room = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  room:setName("starter_room")
  room:setWeight(2.0)
  lurek.log.info("block '" .. room:getName() .. "' " .. room:getWidth() .. "x" .. room:getHeight(), "tilemap")
end

--@api-stub: lurek.tilemap.newMapGroup
-- Creates a new empty MapGroup with the given name.
-- A MapGroup is a named bag of MapBlocks and MapScripts that MapGen samples from.
do  -- lurek.tilemap.newMapGroup
  local dungeon = lurek.tilemap.newMapGroup("dungeon")
  lurek.log.info("group '" .. dungeon:getName() .. "' starts with " .. dungeon:getBlockCount() .. " blocks", "tilemap")
end

--@api-stub: lurek.tilemap.toScreenIso
-- Converts tile coordinates to screen position using diamond isometric projection.
-- Use this to position sprites on a diamond-isometric grid; tileW/tileH are the tile footprint in pixels.
do  -- lurek.tilemap.toScreenIso
  local sx, sy = lurek.tilemap.toScreenIso(3, 5, 64, 32)
  lurek.log.info("iso tile (3,5) -> screen (" .. sx .. ", " .. sy .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.fromScreenIso
-- Converts screen position back to tile coordinates for diamond isometric projection.
-- Inverse of toScreenIso; useful for hit-testing the mouse against an isometric grid.
do  -- lurek.tilemap.fromScreenIso
  local mx, my = 320, 200
  local tx, ty = lurek.tilemap.fromScreenIso(mx, my, 64, 32)
  lurek.log.info("mouse (" .. mx .. "," .. my .. ") over iso tile (" .. tx .. ", " .. ty .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.toScreenHex
-- Converts axial hex coordinates to screen position (pointy-top layout).
-- Pointy-top axial layout; size is the hex radius in pixels (corner-to-centre distance).
do  -- lurek.tilemap.toScreenHex
  local sx, sy = lurek.tilemap.toScreenHex(2, -1, 24)
  lurek.log.info("hex (q=2,r=-1) at screen (" .. sx .. ", " .. sy .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.fromScreenHex
-- Converts screen position back to axial hex coordinates (pointy-top layout).
-- Returns the integer axial (q, r) under the cursor; pair with hexRound for fractional sources.
do  -- lurek.tilemap.fromScreenHex
  local q, r = lurek.tilemap.fromScreenHex(150, 90, 24)
  lurek.log.info("screen (150,90) -> hex (q=" .. q .. ", r=" .. r .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.hexNeighbors
-- Returns the six axial neighbor coordinates as a table of {q, r} pairs.
-- Each entry is a {q, r} table; iterate with ipairs to walk all six adjacent cells.
do  -- lurek.tilemap.hexNeighbors
  local n = lurek.tilemap.hexNeighbors(0, 0)
  for _, c in ipairs(n) do
    lurek.log.debug("neighbor q=" .. c.q .. " r=" .. c.r, "tilemap")
  end
end

--@api-stub: lurek.tilemap.hexDistance
-- Returns the hex distance between two axial coordinates.
-- Use to gate abilities by hex range or to sort enemies by proximity in a strategy game.
do  -- lurek.tilemap.hexDistance
  local d = lurek.tilemap.hexDistance(0, 0, 3, -2)
  if d <= 2 then
    lurek.log.info("target in melee range (d=" .. d .. ")", "combat")
  end
end

--@api-stub: lurek.tilemap.hexRound
-- Rounds fractional axial coordinates to the nearest hex cell.
-- Snap a fractional hex (e.g. from fromScreenHex with floats) back to the nearest integer cell.
do  -- lurek.tilemap.hexRound
  local q, r = lurek.tilemap.hexRound(2.4, -1.7)
  lurek.log.info("rounded fractional hex to (q=" .. q .. ", r=" .. r .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.hexLine
-- Returns all hex cells along a line between two axial coordinates as a table.
-- Walk every cell along a straight hex line — useful for line-of-sight and ranged-attack paths.
do  -- lurek.tilemap.hexLine
  local cells = lurek.tilemap.hexLine(0, 0, 4, -2)
  for _, c in ipairs(cells) do
    lurek.log.debug("line cell (" .. c[1] .. ", " .. c[2] .. ")", "tilemap")
  end
end

--@api-stub: lurek.tilemap.hexRing
-- Returns all cells at exactly radius distance from (q, r) as a table.
-- All cells exactly `radius` away — perfect for ring-shaped explosion or aura visuals.
do  -- lurek.tilemap.hexRing
  local ring = lurek.tilemap.hexRing(0, 0, 3)
  lurek.log.info("ring at radius 3 has " .. #ring .. " cells", "tilemap")
end

--@api-stub: lurek.tilemap.hexSpiral
-- Returns all hex cells from center outward to radius, ring by ring, as a table.
-- Returns center then each ring outward — handy for ordered placement or expanding-search BFS.
do  -- lurek.tilemap.hexSpiral
  local spiral = lurek.tilemap.hexSpiral(0, 0, 2)
  lurek.log.info("spiral 0..2 covers " .. #spiral .. " cells", "tilemap")
end

--@api-stub: lurek.tilemap.hexArea
-- Returns all hex cells within radius distance (filled hex circle) as a table.
-- Filled hex disc — use for area-of-effect spells, fog-of-war reveal, or city-radius queries.
do  -- lurek.tilemap.hexArea
  local aoe = lurek.tilemap.hexArea(5, 5, 2)
  for _, c in ipairs(aoe) do
    lurek.log.debug("aoe cell (" .. c[1] .. ", " .. c[2] .. ")", "tilemap")
  end
end

--@api-stub: lurek.tilemap.hexRotate
-- Rotates hex coordinates around a center by steps x 60 degrees clockwise.
-- Each step is 60° clockwise; use a negative `steps` value to rotate counter-clockwise.
do  -- lurek.tilemap.hexRotate
  local q, r = lurek.tilemap.hexRotate(2, 0, 0, 0, 1)
  lurek.log.info("rotated (2,0) by 60° -> (q=" .. q .. ", r=" .. r .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.hexReflect
-- Reflects hex coordinates across an axis through the center.
-- Axis is one of '"q"', '"r"', or '"s"' — the three hex symmetry axes.
do  -- lurek.tilemap.hexReflect
  local q, r = lurek.tilemap.hexReflect(2, 1, 0, 0, "q")
  lurek.log.info("reflected hex (2,1) over q -> (" .. q .. ", " .. r .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.isoRotate
-- Rotates an isometric direction (1-4) clockwise by steps.
-- Direction is 1=N, 2=E, 3=S, 4=W; steps wraps around modulo 4.
do  -- lurek.tilemap.isoRotate
  local d = lurek.tilemap.isoRotate(1, 2)
  lurek.log.info("rotated dir 1 by 2 steps -> " .. d .. " (" .. lurek.tilemap.isoDirectionName(d) .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.isoDirectionName
-- Returns the name of an isometric direction (1-4).
-- Returns 'north'/'east'/'south'/'west'; useful for animation lookup keys.
do  -- lurek.tilemap.isoDirectionName
  local facing = lurek.tilemap.isoDirectionName(2)
  local sprite_key = "walk_" .. facing
  lurek.log.info("playing animation '" .. sprite_key .. "'", "anim")
end

--@api-stub: lurek.tilemap.isoDirectionFromAngle
-- Snaps an angle (in radians) to the nearest isometric direction (1-4).
-- Maps a movement vector angle (math.atan2(dy, dx)) to the nearest cardinal iso direction.
do  -- lurek.tilemap.isoDirectionFromAngle
  local dx, dy = 1, 0.2
  local dir = lurek.tilemap.isoDirectionFromAngle(math.atan2(dy, dx))
  lurek.log.info("velocity faces " .. lurek.tilemap.isoDirectionName(dir), "anim")
end

--@api-stub: lurek.tilemap.newMapScript
-- Creates a new empty MapScript procedural generation script.
-- A MapScript is a sequence of generation steps replayed by MapGen; build it once at load time.
do  -- lurek.tilemap.newMapScript
  local script = lurek.tilemap.newMapScript()
  script:addStep({ type = "fillRandom", gid = 1, chance = 0.3 })
  lurek.log.info("script has " .. script:getStepCount() .. " step(s)", "tilemap")
end

--@api-stub: lurek.tilemap.newMapGen
-- Creates a MapGen from a MapGroup, a preset name or dimensions, and a segment size.
-- Pass either a preset string ('small'/'medium'/'large') or explicit width/height; segmentSize controls block grid.
do  -- lurek.tilemap.newMapGen
  local group = lurek.tilemap.newMapGroup("rooms")
  group:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  local gen = lurek.tilemap.newMapGen(group, "small", 8)
  local map = gen:generate(nil, 1234)
  lurek.log.info("generated map with " .. map:getLayerCount() .. " layer(s)", "tilemap")
end

--@api-stub: lurek.tilemap.loadTMX
-- Parses a TMX XML string and returns a table with map metadata and layers.
-- Returns a metadata table — width/height/tileWidth/tileHeight/orientation/layers — not a TileMap.
do  -- lurek.tilemap.loadTMX
  pcall(function()
    local xml = lurek.fs.read("levels/forest.tmx")
    local meta = lurek.tilemap.loadTMX(xml)
    lurek.log.info("TMX " .. meta.width .. "x" .. meta.height .. " orient=" .. meta.orientation .. " layers=" .. #meta.layers, "tilemap")
  end)
end

--@api-stub: lurek.tilemap.fromLDtk
-- Parses an LDtk JSON export string and returns a TileMap.
-- Pass an optional level name to pick from a multi-level project; defaults to the first level.
do  -- lurek.tilemap.fromLDtk
  pcall(function()
    local json = lurek.fs.read("levels/world.ldtk")
    local map = lurek.tilemap.fromLDtk(json, "Level_0")
    lurek.log.info("LDtk level loaded with " .. map:getLayerCount() .. " layer(s)", "tilemap")
  end)
end

--@api-stub: lurek.tilemap.newLargeMapRenderer
-- Creates a LargeMapRenderer for chunk-level occlusion culling on maps > 200Ă—200 tiles.
-- Use for maps over 200×200 tiles; the renderer culls invisible chunks before issuing draw calls.
do  -- lurek.tilemap.newLargeMapRenderer
  local renderer = lurek.tilemap.newLargeMapRenderer(16, 16)
  renderer:setChunkSize(32)
  lurek.log.info("large map renderer ready, chunk=" .. renderer:getChunkSize(), "render")
end

-- ── TileSet methods ──

--@api-stub: TileSet:getFirstGid
-- Returns the first global ID assigned to this tileset.
-- Use the first GID to translate between local tile IDs and the map-wide global ID space.
do  -- TileSet:getFirstGid
  local ts = lurek.tilemap.newTileSet(257, 64, 8, 16, 16)
  lurek.log.info("tileset firstGid=" .. ts:getFirstGid(), "tilemap")
end

--@api-stub: TileSet:getTileCount
-- Returns the total number of tiles in this tileset.
-- Iterate 1..getTileCount() to enumerate every local tile ID in the set.
do  -- TileSet:getTileCount
  local ts = lurek.tilemap.newTileSet(1, 96, 12, 16, 16)
  for id = 1, ts:getTileCount() do
    ts:setSolid(id, id <= 32)
  end
end

--@api-stub: TileSet:getColumns
-- Returns the number of tile columns in the atlas texture.
-- Columns × rows = tileCount; use this to compute atlas row index for a given tile ID.
do  -- TileSet:getColumns
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local rows = ts:getTileCount() / ts:getColumns()
  lurek.log.info("atlas " .. ts:getColumns() .. " cols x " .. rows .. " rows", "tilemap")
end

--@api-stub: TileSet:getTileWidth
-- Returns the width of a single tile in pixels.
-- Use when configuring matching collision shapes or placing markers in tile units.
do  -- TileSet:getTileWidth
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 32, 16)
  local box_w = ts:getTileWidth()
  lurek.log.info("collision width matches tile = " .. box_w, "physics")
end

--@api-stub: TileSet:getTileHeight
-- Returns the height of a single tile in pixels.
-- Pair with getTileWidth when building axis-aligned colliders that match a tile sprite.
do  -- TileSet:getTileHeight
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 24)
  local box_h = ts:getTileHeight()
  lurek.log.info("collision height = " .. box_h, "physics")
end

--@api-stub: TileSet:getTileDimensions
-- Returns the tile dimensions as (width, height).
-- Returns (width, height) — handy for one-line capture without two getter calls.
do  -- TileSet:getTileDimensions
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tw, th = ts:getTileDimensions()
  lurek.log.info("tile is " .. tw .. "x" .. th .. " px", "tilemap")
end

--@api-stub: TileSet:getSpacing
-- Returns the spacing in pixels between tiles in the atlas.
-- Spacing is the gap in pixels between adjacent tiles in the atlas; 0 means tiles touch.
do  -- TileSet:getSpacing
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16, 2, 1)
  lurek.log.info("atlas spacing=" .. ts:getSpacing() .. " margin=" .. ts:getMargin(), "tilemap")
end

--@api-stub: TileSet:getMargin
-- Returns the margin in pixels around the edges of the atlas.
-- Margin is the border in pixels around the entire atlas; account for it when slicing source rects.
do  -- TileSet:getMargin
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16, 0, 4)
  local m = ts:getMargin()
  lurek.log.info("first tile starts " .. m .. " px in from atlas edge", "tilemap")
end

--@api-stub: TileSet:getQuad
-- Computes the atlas source rectangle for a 1-based local tile ID.
-- Returns a {x, y, width, height} table of the source rectangle in atlas pixels.
do  -- TileSet:getQuad
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local q = ts:getQuad(5)
  lurek.log.info("tile 5 quad x=" .. q.x .. " y=" .. q.y .. " w=" .. q.width .. " h=" .. q.height, "tilemap")
end

--@api-stub: TileSet:getAnimation
-- Returns the animation frames for a 1-based local tile ID as a table of {tileid, duration}, or nil.
-- Returns nil when a tile has no animation; otherwise an array of {tileid, duration} frames.
do  -- TileSet:getAnimation
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local frames = ts:getAnimation(1)
  if frames == nil then
    lurek.log.info("tile 1 is static", "tilemap")
  end
end

--@api-stub: TileSet:setSolid
-- Sets whether a 1-based local tile ID is solid for collision purposes.
-- Mark walls, water, or pit tiles solid up-front so isSolid/sweepRect later use it for collision.
do  -- TileSet:setSolid
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  for _, gid in ipairs({ 5, 6, 7, 8 }) do
    ts:setSolid(gid, true)
  end
end

--@api-stub: TileSet:isSolid
-- Returns whether a 1-based local tile ID is solid.
-- Defaults to false; query at startup to validate tilesets imported from external editors.
do  -- TileSet:isSolid
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setSolid(7, true)
  if ts:isSolid(7) then
    lurek.log.info("tile 7 will block movement", "tilemap")
  end
end

-- ── TileMap methods ──

--@api-stub: TileMap:addTileSet
-- Adds a tileset to this map.
-- Add tilesets in firstGid order so global IDs resolve correctly when you set or query tiles.
do  -- TileMap:addTileSet
  local map = lurek.tilemap.newTileMap(16, 16)
  local terrain = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  map:addTileSet(terrain)
  lurek.log.info("map now has " .. map:getTileSetCount() .. " tileset(s)", "tilemap")
end

--@api-stub: TileMap:getTileSetCount
-- Returns the number of tilesets attached to this map.
-- Loop 1..getTileSetCount() to walk every tileset attached to the map.
do  -- TileMap:getTileSetCount
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addTileSet(lurek.tilemap.newTileSet(1, 32, 8, 16, 16))
  map:addTileSet(lurek.tilemap.newTileSet(33, 32, 8, 16, 16))
  lurek.log.info("tilesets attached: " .. map:getTileSetCount(), "tilemap")
end

--@api-stub: TileMap:getTileSet
-- Returns a tileset by 1-based index, or nil if out of range.
-- Returns nil for out-of-range indices, so always nil-check before calling tileset methods.
do  -- TileMap:getTileSet
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addTileSet(lurek.tilemap.newTileSet(1, 64, 8, 16, 16))
  local ts = map:getTileSet(1)
  if ts then
    lurek.log.info("first tileset has " .. ts:getTileCount() .. " tiles", "tilemap")
  end
end

--@api-stub: TileMap:addLayer
-- Adds a new empty layer and returns its 1-based index.
-- Pass the desired layer name plus width/height in tiles; returns the 1-based layer index.
do  -- TileMap:addLayer
  local map = lurek.tilemap.newTileMap(16, 16)
  local bg = map:addLayer("background", 64, 64)
  local fg = map:addLayer("collision", 64, 64)
  lurek.log.info("background=" .. bg .. " collision=" .. fg, "tilemap")
end

--@api-stub: TileMap:getLayerCount
-- Returns the number of layers.
-- Use to drive a render loop that walks every layer in declaration order.
do  -- TileMap:getLayerCount
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  map:addLayer("collision", 32, 32)
  lurek.log.info("layers in map: " .. map:getLayerCount(), "tilemap")
end

--@api-stub: TileMap:getLayerName
-- Returns the name of a layer by 1-based index.
-- Names are the contract between scripts and level data — branch on them to drive collision rules.
do  -- TileMap:getLayerName
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("collision", 32, 32)
  local name = map:getLayerName(1)
  if name == "collision" then
    lurek.log.info("layer 1 is the collision layer", "tilemap")
  end
end

--@api-stub: TileMap:getLayerVisible
-- Returns layer visibility.
-- Use in a debug-overlay toggle that hides layers without modifying their tile data.
do  -- TileMap:getLayerVisible
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("collision", 32, 32)
  if not map:getLayerVisible(1) then
    lurek.log.warn("collision layer is hidden", "tilemap")
  end
end

--@api-stub: TileMap:getLayerColor
-- Returns the RGBA tint color of a layer.
-- Returns r, g, b, a in 0..1 range; use to fade layers in/out for transitions.
do  -- TileMap:getLayerColor
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  local r, g, b, a = map:getLayerColor(1)
  lurek.log.info("background tint rgba=" .. r .. "," .. g .. "," .. b .. "," .. a, "tilemap")
end

--@api-stub: TileMap:getLayerOffset
-- Returns the pixel offset of a layer.
-- Returns (ox, oy) in pixels — useful when implementing camera-relative parallax UI.
do  -- TileMap:getLayerOffset
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  local ox, oy = map:getLayerOffset(1)
  lurek.log.info("layer offset px=(" .. ox .. ", " .. oy .. ")", "tilemap")
end

--@api-stub: TileMap:getLayerParallax
-- Returns the parallax factor of a layer.
-- Parallax of 1.0 scrolls 1:1 with the camera; 0.5 means half-speed (distant background).
do  -- TileMap:getLayerParallax
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("clouds", 64, 32)
  local px, py = map:getLayerParallax(1)
  lurek.log.info("clouds parallax=(" .. px .. ", " .. py .. ")", "tilemap")
end

--@api-stub: TileMap:getTile
-- Returns the GID at (x, y) on the given layer (1-based).
-- Returns the GID at (x, y) on the layer; 0 means empty. Use for interaction probes.
do  -- TileMap:getTile
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("collision", 32, 32)
  local gid = map:getTile(1, 4, 4)
  if gid == 0 then
    lurek.log.info("(4,4) is walkable", "tilemap")
  end
end

--@api-stub: TileMap:clearTile
-- Clears a tile (sets GID to 0) at (x, y) on the given layer (1-based).
-- Equivalent to setTile(layer, x, y, 0); use when destroying a destructible block.
do  -- TileMap:clearTile
  local map = lurek.tilemap.newTileMap(16, 16)
  local layer = map:addLayer("walls", 32, 32)
  map:fill(layer, 5)
  map:clearTile(layer, 10, 10)  -- player blew up the wall
end

--@api-stub: TileMap:fill
-- Fills an entire layer with the given GID (1-based layer).
-- Floods every cell of a layer with a single GID — handy for paint-by-number background fills.
do  -- TileMap:fill
  local map = lurek.tilemap.newTileMap(16, 16)
  local bg = map:addLayer("background", 32, 32)
  map:fill(bg, 1)  -- gid 1 = grass tile
  lurek.log.info("background filled with grass", "tilemap")
end

--@api-stub: TileMap:getViewport
-- Returns the viewport as (x, y, w, h) or nil if not set.
-- Returns nil values when no viewport is set; check before reading the rectangle.
do  -- TileMap:getViewport
  local map = lurek.tilemap.newTileMap(16, 16)
  local x, y, w, h = map:getViewport()
  if x == nil then
    lurek.log.info("no viewport set, will render full map", "tilemap")
  end
end

--@api-stub: TileMap:update
-- Advances tile animation timers by dt seconds.
-- Call once per frame from lurek.process(dt) to advance any animated tile timers.
do  -- TileMap:update
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("water", 32, 32)
  function lurek.process(dt) map:update(dt) end
end

--@api-stub: TileMap:worldToTile
-- Converts world pixel coordinates to tile coordinates.
-- Returns 1-based tile coordinates; use for mouse-over highlighting or click placement.
do  -- TileMap:worldToTile
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 64, 64)
  local tx, ty = map:worldToTile(128, 96)
  lurek.log.info("world (128,96) -> tile (" .. tx .. ", " .. ty .. ")", "tilemap")
end

--@api-stub: TileMap:tileToWorld
-- Converts tile coordinates to world pixel coordinates (1-based input).
-- Inverse of worldToTile (1-based input); use to anchor sprites to tile centres or corners.
do  -- TileMap:tileToWorld
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  local wx, wy = map:tileToWorld(5, 8)
  lurek.log.info("spawn pos px=(" .. wx .. ", " .. wy .. ")", "tilemap")
end

--@api-stub: TileMap:getTileWidth
-- Returns the tile width in pixels.
-- Use when computing camera bounds or snapping movement to multiples of one tile.
do  -- TileMap:getTileWidth
  local map = lurek.tilemap.newTileMap(32, 32)
  local step = map:getTileWidth()
  lurek.log.info("snap step = " .. step .. " px", "tilemap")
end

--@api-stub: TileMap:getTileHeight
-- Returns the tile height in pixels.
-- Pair with getTileWidth when scaling UI overlays to a tile grid.
do  -- TileMap:getTileHeight
  local map = lurek.tilemap.newTileMap(16, 32)
  local row_h = map:getTileHeight()
  lurek.log.info("HUD row height = " .. row_h, "ui")
end

--@api-stub: TileMap:getTileDimensions
-- Returns tile dimensions as (width, height).
-- Single-call alternative to getTileWidth / getTileHeight; returns (w, h).
do  -- TileMap:getTileDimensions
  local map = lurek.tilemap.newTileMap(16, 16)
  local tw, th = map:getTileDimensions()
  lurek.log.info("tile size " .. tw .. "x" .. th, "tilemap")
end

--@api-stub: TileMap:getChunkSize
-- Returns the chunk size used for spatial partitioning.
-- Chunk size determines spatial-query granularity for culling; 16 is a good default.
do  -- TileMap:getChunkSize
  local map = lurek.tilemap.newTileMap(16, 16, 32)
  lurek.log.info("map chunk size = " .. map:getChunkSize(), "tilemap")
end

--@api-stub: TileMap:isSolid
-- Returns true if the tile at (x, y) on layer is solid (1-based).
-- Reads the solidity from the tileset for the GID at (layer, x, y); use as a cheap blocker check.
do  -- TileMap:isSolid
  local map = lurek.tilemap.newTileMap(16, 16)
  local layer = map:addLayer("collision", 32, 32)
  if map:isSolid(layer, 4, 4) then
    lurek.log.info("(4,4) blocks movement", "physics")
  end
end

--@api-stub: TileMap:getOrientation
-- Returns the map orientation as a string ("topdown", "sideview", "isometric", or "hexagonal").
-- One of 'topdown', 'sideview', 'isometric', or 'hexagonal' — branch on it to pick movement code.
do  -- TileMap:getOrientation
  local map = lurek.tilemap.newTileMap(16, 16)
  local o = map:getOrientation()
  if o == "topdown" then
    lurek.log.info("using top-down 4-way movement", "input")
  end
end

--@api-stub: TileMap:setOrientation
-- Sets the map orientation from a string ("topdown", "sideview", "isometric", or "hexagonal").
-- Set once at level load; passing an unknown string raises an error so validate first.
do  -- TileMap:setOrientation
  local map = lurek.tilemap.newTileMap(64, 32)
  map:setOrientation("isometric")
  lurek.log.info("orientation now " .. map:getOrientation(), "tilemap")
end

--@api-stub: TileMap:render
-- Renders the tile map to the screen at the given offset.
-- Call from lurek.render with the camera offset to draw the map at the correct screen position.
do  -- TileMap:render
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  local cam_x, cam_y = 0, 0
  function lurek.render() map:render(-cam_x, -cam_y) end
end

--@api-stub: TileMap:drawToImage
-- Renders the tile map to a CPU ImageData using the given tile pixel size.
-- Returns an ImageData you can save for a minimap thumbnail or in-engine debug snapshot.
do  -- TileMap:drawToImage
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  local thumb = map:drawToImage(2)
  lurek.log.info("rendered map preview to ImageData", "tilemap")
end

-- ── AutoTileSheet methods ──

--@api-stub: AutoTileSheet:getLayout
-- Returns the layout variant as a string.
-- Returns 'blob47'/'composite48'/'minimal16' — branch on it when emitting tiles per ruleset.
do  -- AutoTileSheet:getLayout
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
  if sheet:getLayout() == "minimal16" then
    lurek.log.info("using 16-tile autotile ruleset", "tilemap")
  end
end

--@api-stub: AutoTileSheet:getTileCount
-- Returns the number of tiles in this sheet.
-- Total tiles in the sheet; matches the layout (16, 47, or 48).
do  -- AutoTileSheet:getTileCount
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  lurek.log.info("blob47 sheet exposes " .. sheet:getTileCount() .. " tiles", "tilemap")
end

--@api-stub: AutoTileSheet:getTileWidth
-- Returns the tile width in pixels.
-- Use when sizing a debug overlay or palette preview for the autotile set.
do  -- AutoTileSheet:getTileWidth
  local sheet = lurek.tilemap.newAutoTileSheet(32, 32, "composite48")
  lurek.log.info("autotile tile width = " .. sheet:getTileWidth() .. " px", "tilemap")
end

--@api-stub: AutoTileSheet:getTileHeight
-- Returns the tile height in pixels.
-- Pair with getTileWidth when laying out a palette for tile selection in a level editor.
do  -- AutoTileSheet:getTileHeight
  local sheet = lurek.tilemap.newAutoTileSheet(16, 24, "blob47")
  lurek.log.info("autotile tile height = " .. sheet:getTileHeight() .. " px", "tilemap")
end

--@api-stub: AutoTileSheet:getBitmaskForTile
-- Returns the bitmask value associated with a 1-based local tile ID.
-- Returns the connectivity bitmask the given tile ID was authored to represent.
do  -- AutoTileSheet:getBitmaskForTile
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  local mask = sheet:getBitmaskForTile(5)
  lurek.log.info("tile 5 represents bitmask " .. mask, "tilemap")
end

--@api-stub: AutoTileSheet:getTileForBitmask
-- Returns the 1-based tile ID for a given bitmask, or nil.
-- Returns nil when no tile is assigned to that bitmask; fall back to a default in that case.
do  -- AutoTileSheet:getTileForBitmask
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  local id = sheet:getTileForBitmask(15) or 1
  lurek.log.info("bitmask 15 -> tile " .. id, "tilemap")
end

--@api-stub: AutoTileSheet:getQuad
-- Returns the atlas region rectangle for the 1-based tile ID.
-- Source rectangle for the given tile ID; returned as {x, y, width, height} in atlas pixels.
do  -- AutoTileSheet:getQuad
  pcall(function()
    local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
    local q = sheet:getQuad(3)
    lurek.log.info("autotile 3 quad x=" .. q.x .. " y=" .. q.y, "tilemap")
  end)
end

-- ── ChunkMap methods ──

--@api-stub: ChunkMap:getTile
-- Returns the GID at tile coordinate (x, y).
-- Coordinates can be any integer (positive or negative); returns 0 for never-touched cells.
do  -- ChunkMap:getTile
  local world = lurek.tilemap.newChunkMap(32)
  world:setTile(-5, 12, 9)
  local gid = world:getTile(-5, 12)
  lurek.log.info("tile at (-5, 12) gid=" .. gid, "tilemap")
end

--@api-stub: ChunkMap:setTile
-- Sets the GID at tile coordinate (x, y).
-- Allocates the underlying chunk lazily; safe to call on any (x, y) including negatives.
do  -- ChunkMap:setTile
  local world = lurek.tilemap.newChunkMap(16)
  for x = 0, 9 do
    world:setTile(x, 0, 1)
  end
end

--@api-stub: ChunkMap:clearTile
-- Clears the tile at (x, y) by setting its GID to 0.
-- Sets the GID back to 0 but does NOT free the chunk — use unloadChunk for memory.
do  -- ChunkMap:clearTile
  local world = lurek.tilemap.newChunkMap(16)
  world:setTile(3, 3, 5)
  world:clearTile(3, 3)
  lurek.log.info("tile (3,3) now gid=" .. world:getTile(3, 3), "tilemap")
end

--@api-stub: ChunkMap:loadChunk
-- Pre-allocates the chunk at chunk coordinates (cx, cy).
-- Pre-warm chunks ahead of the camera to avoid first-touch allocation hitches at the edge.
do  -- ChunkMap:loadChunk
  local world = lurek.tilemap.newChunkMap(16)
  for cx = 0, 3 do
    world:loadChunk(cx, 0)
  end
end

--@api-stub: ChunkMap:unloadChunk
-- Removes the chunk at chunk coordinates (cx, cy) from memory.
-- Drop chunks the camera has left behind to keep memory bounded for infinite worlds.
do  -- ChunkMap:unloadChunk
  local world = lurek.tilemap.newChunkMap(16)
  world:loadChunk(0, 0)
  world:unloadChunk(0, 0)
  lurek.log.info("chunks resident: " .. #world:getLoadedChunks(), "tilemap")
end

--@api-stub: ChunkMap:getChunkSize
-- Returns the chunk size (tiles per side).
-- Use when converting world tile coords to chunk coords: cx = floor(x / chunkSize).
do  -- ChunkMap:getChunkSize
  local world = lurek.tilemap.newChunkMap(64)
  local size = world:getChunkSize()
  lurek.log.info("chunk side = " .. size .. " tiles", "tilemap")
end

--@api-stub: ChunkMap:getLoadedChunks
-- Returns a table of all currently loaded chunk coordinates as {{cx, cy}, ...}.
-- Each entry is {cx, cy}; iterate to draw a debug overlay of resident chunks.
do  -- ChunkMap:getLoadedChunks
  local world = lurek.tilemap.newChunkMap(16)
  world:setTile(0, 0, 1)
  world:setTile(40, -10, 2)
  for _, c in ipairs(world:getLoadedChunks()) do
    lurek.log.debug("chunk loaded cx=" .. c[1] .. " cy=" .. c[2], "tilemap")
  end
end

--@api-stub: ChunkMap:chunkTileRange
-- Returns the tile coordinate range for chunk (cx, cy) as (x0, y0, x1, y1).
-- Returns inclusive (x0, y0, x1, y1) tile bounds — use to iterate every cell of a chunk.
do  -- ChunkMap:chunkTileRange
  local world = lurek.tilemap.newChunkMap(16)
  local x0, y0, x1, y1 = world:chunkTileRange(2, -1)
  lurek.log.info("chunk (2,-1) covers x[" .. x0 .. ".." .. x1 .. "] y[" .. y0 .. ".." .. y1 .. "]", "tilemap")
end

-- ── LargeMapRenderer methods ──

--@api-stub: LargeMapRenderer:setTile
-- Sets a single tile ID at (x, y).
-- Coordinates are 0-based and must be within the map size set via setMapData.
do  -- LargeMapRenderer:setTile
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  r:setTile(1, 0, 5)
  r:invalidateChunk(0, 0)
end

--@api-stub: LargeMapRenderer:getTile
-- Returns the tile ID at (x, y), or nil if out of bounds.
-- Returns nil when (x, y) is outside the map; pair with getMapSize for bounds.
do  -- LargeMapRenderer:getTile
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 1, 2, 3, 4 }, 2, 2)
  local id = r:getTile(0, 0)
  if id then lurek.log.info("origin tile = " .. id, "render") end
end

--@api-stub: LargeMapRenderer:getMapSize
-- Returns the map dimensions as (width, height) in tiles.
-- Use to drive iteration loops or to size a minimap proportional to the world.
do  -- LargeMapRenderer:getMapSize
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  local w, h = r:getMapSize()
  lurek.log.info("large map " .. w .. "x" .. h .. " tiles", "render")
end

--@api-stub: LargeMapRenderer:setChunkSize
-- Sets the chunk size used for culling (default 16).
-- Larger chunks reduce overhead but coarsen culling; 16-32 is typical for HD tilesets.
do  -- LargeMapRenderer:setChunkSize
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setChunkSize(32)
  lurek.log.info("renderer chunk size = " .. r:getChunkSize(), "render")
end

--@api-stub: LargeMapRenderer:getChunkSize
-- Returns the current chunk size.
-- Read after setChunkSize to confirm the value the renderer is actually using.
do  -- LargeMapRenderer:getChunkSize
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  lurek.log.info("default chunk size = " .. r:getChunkSize(), "render")
end

--@api-stub: LargeMapRenderer:invalidateChunk
-- Marks a chunk at chunk-grid coordinates (cx, cy) as dirty,.
-- Call after editing tiles in a chunk so the renderer rebuilds its cached geometry.
do  -- LargeMapRenderer:invalidateChunk
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  r:setTile(0, 0, 7)
  r:invalidateChunk(0, 0)
end

--@api-stub: LargeMapRenderer:invalidateAll
-- Marks every chunk as dirty.
-- Use after a global change like swapping tilesets or applying a colour grading tint.
do  -- LargeMapRenderer:invalidateAll
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 1, 2, 3, 4 }, 2, 2)
  r:invalidateAll()
  lurek.log.info("all chunks marked dirty", "render")
end

--@api-stub: LargeMapRenderer:getVisibleChunks
-- Returns the number of chunks currently within the camera viewport.
-- Use as a debug HUD value to confirm culling is actually trimming work.
do  -- LargeMapRenderer:getVisibleChunks
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  r:setCamera(0, 0, 1.0)
  r:setViewport(800, 600)
  lurek.log.info("visible chunks: " .. r:getVisibleChunks(), "render")
end

--@api-stub: LargeMapRenderer:getTotalChunks
-- Returns the total number of chunks that cover the loaded map.
-- Compare against getVisibleChunks to compute culling efficiency in a perf overlay.
do  -- LargeMapRenderer:getTotalChunks
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0, 0, 0, 0, 0 }, 4, 2)
  lurek.log.info("total chunks = " .. r:getTotalChunks(), "render")
end

--@api-stub: LargeMapRenderer:setCamera
-- Updates the camera position and zoom used for visibility culling.
-- Update from your main loop with the camera position and current zoom each frame.
do  -- LargeMapRenderer:setCamera
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  function lurek.process(dt) r:setCamera(player_x or 0, player_y or 0, 1.0) end
end

--@api-stub: LargeMapRenderer:setViewport
-- Sets the viewport dimensions in pixels used for visibility culling.
-- Pass your render target size in pixels so the renderer can compute culling bounds.
do  -- LargeMapRenderer:setViewport
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  r:setViewport(1920, 1080)
end

--@api-stub: LargeMapRenderer:setLodEnabled
-- Enables or disables level-of-detail rendering for distant chunks.
-- Enable LOD when the camera can zoom out far enough to make per-tile rendering wasteful.
do  -- LargeMapRenderer:setLodEnabled
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setLodEnabled(true)
  if r:isLodEnabled() then
    lurek.log.info("LOD active", "render")
  end
end

--@api-stub: LargeMapRenderer:isLodEnabled
-- Returns whether LOD rendering is currently enabled.
-- Read in a debug HUD to confirm the LOD toggle is matching the menu setting.
do  -- LargeMapRenderer:isLodEnabled
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  if not r:isLodEnabled() then
    r:setLodEnabled(true)
  end
end

--@api-stub: LargeMapRenderer:setLodThresholds
-- Sets the distance thresholds (in tile units) at which each LOD level activates.
-- Each entry is the camera-distance in tile units at which the next LOD tier kicks in.
do  -- LargeMapRenderer:setLodThresholds
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setLodEnabled(true)
  r:setLodThresholds({ 64.0, 256.0, 1024.0 })
end

--@api-stub: LargeMapRenderer:setTilesetColumns
-- Sets the number of tile columns in the atlas texture used for UV calculation.
-- Set this to match your atlas column count so UV mapping is correct.
do  -- LargeMapRenderer:setTilesetColumns
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setTilesetColumns(16)
  lurek.log.info("renderer atlas cols = " .. r:getTilesetColumns(), "render")
end

--@api-stub: LargeMapRenderer:getTilesetColumns
-- Returns the number of tileset atlas columns.
-- Read after setTilesetColumns to confirm the value used in the next render pass.
do  -- LargeMapRenderer:getTilesetColumns
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setTilesetColumns(8)
  lurek.log.info("UVs are sliced into " .. r:getTilesetColumns() .. " columns", "render")
end

-- ── IsoMap methods ──

--@api-stub: IsoMap:addLevel
-- Appends a new empty Z-level and returns its 1-based index.
-- Adds an empty Z-level on top of the stack and returns its 1-based index.
do  -- IsoMap:addLevel
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  local z = iso:addLevel()
  lurek.log.info("added level " .. z .. ", count now " .. iso:getLevelCount(), "tilemap")
end

--@api-stub: IsoMap:getLevelCount
-- Returns the number of Z-levels currently in the map.
-- Drive a render loop from 1..getLevelCount() to draw every Z-level back to front.
do  -- IsoMap:getLevelCount
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:addLevel(); iso:addLevel(); iso:addLevel()
  lurek.log.info("iso has " .. iso:getLevelCount() .. " level(s)", "tilemap")
end

--@api-stub: IsoMap:setLevelVisible
-- Sets the visibility of a level (1-based z).
-- Toggle to implement a 'cutaway' view that hides upper floors above the camera target.
do  -- IsoMap:setLevelVisible
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:addLevel(); iso:addLevel()
  iso:setLevelVisible(2, false)  -- hide upper floor
end

--@api-stub: IsoMap:isLevelVisible
-- Returns the visibility of a level (1-based z).
-- Combine with a UI toggle so the player can opt in to seeing higher Z-levels.
do  -- IsoMap:isLevelVisible
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:addLevel()
  if iso:isLevelVisible(1) then
    lurek.log.info("ground floor is visible", "tilemap")
  end
end

--@api-stub: IsoMap:fillLevel
-- Fills every cell in level z with gid for the given part (1-based z; 0-based part).
-- Floods every cell of (z, part) with the same GID — handy for laying solid floors fast.
do  -- IsoMap:fillLevel
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:addLevel()
  iso:fillLevel(1, lurek.tilemap.FLOOR - 1, 1)  -- floor part 0, gid 1
end

--@api-stub: IsoMap:setOrigin
-- Sets the screen pixel origin.
-- Set the screen-space pixel origin (top-left of the diamond grid) when scrolling the iso world.
do  -- IsoMap:setOrigin
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:addLevel()
  iso:setOrigin(400, 100)
end

--@api-stub: IsoMap:getWidth
-- Returns the map width in tiles.
-- Use when sizing a minimap proportional to the iso footprint.
do  -- IsoMap:getWidth
  local iso = lurek.tilemap.newIsoMap(20, 30, 64, 32, 24)
  lurek.log.info("iso map is " .. iso:getWidth() .. " tiles wide", "tilemap")
end

--@api-stub: IsoMap:getHeight
-- Returns the map height in tiles.
-- Pair with getWidth when iterating over every (x, y) on a level.
do  -- IsoMap:getHeight
  local iso = lurek.tilemap.newIsoMap(20, 30, 64, 32, 24)
  lurek.log.info("iso map is " .. iso:getHeight() .. " tiles tall", "tilemap")
end

--@api-stub: IsoMap:getTileWidth
-- Returns the tile footprint width in pixels.
-- Tile footprint width in pixels — typical iso ratio is 2:1 width:height.
do  -- IsoMap:getTileWidth
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  lurek.log.info("iso tile footprint width = " .. iso:getTileWidth() .. " px", "tilemap")
end

--@api-stub: IsoMap:getTileHeight
-- Returns the tile footprint height in pixels.
-- Tile footprint height in pixels — half the width gives the classic 2:1 isometric look.
do  -- IsoMap:getTileHeight
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  lurek.log.info("iso tile footprint height = " .. iso:getTileHeight() .. " px", "tilemap")
end

--@api-stub: IsoMap:getLevelHeight
-- Returns the vertical pixel offset between consecutive Z-levels.
-- Vertical pixel offset between Z-levels; tune to match the height of your wall sprites.
do  -- IsoMap:getLevelHeight
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 32)
  lurek.log.info("Z step = " .. iso:getLevelHeight() .. " px between levels", "tilemap")
end

--@api-stub: IsoMap:tileToScreen
-- Projects isometric tile coordinates (tx, ty, tz) to screen pixels.
-- Use to position sprite overlays (HP bars, names) above a particular iso tile.
do  -- IsoMap:tileToScreen
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:setOrigin(400, 100)
  local sx, sy = iso:tileToScreen(3, 4, 0)
  lurek.log.info("tile (3,4,0) at screen (" .. sx .. ", " .. sy .. ")", "tilemap")
end

--@api-stub: IsoMap:screenToTile
-- Converts screen pixel coordinates to isometric tile coordinates at Z-level 0.
-- Use for mouse picking; result is at Z=0 — apply your own offset for higher levels.
do  -- IsoMap:screenToTile
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:setOrigin(400, 100)
  local tx, ty = iso:screenToTile(500, 200)
  lurek.log.info("cursor over iso tile (" .. tx .. ", " .. ty .. ")", "tilemap")
end

--@api-stub: IsoMap:getPartCount
-- Returns the number of GID slots per tile.
-- Default 4 (floor/N-wall/W-wall/object); use the lurek.tilemap constants to index parts symbolically.
do  -- IsoMap:getPartCount
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24, 4)
  lurek.log.info("iso parts per tile = " .. iso:getPartCount(), "tilemap")
end

--@api-stub: IsoMap:getPartOrder
-- Returns the current draw-order array (0-based part slot indices).
-- Returns 0-based slot indices in draw order; useful for debugging Z-fighting on stacked parts.
do  -- IsoMap:getPartOrder
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24, 4)
  local order = iso:getPartOrder()
  lurek.log.info("iso draw order has " .. #order .. " slots", "tilemap")
end

--@api-stub: IsoMap:setPartOrder
-- Overrides the draw order for this IsoMap.
-- Pass a permutation of 0..partCount-1; raises an error if the length or values are wrong.
do  -- IsoMap:setPartOrder
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24, 4)
  iso:setPartOrder({ 0, 2, 1, 3 })  -- swap N-wall and W-wall draw order
end

-- ── MapBlock methods ──

--@api-stub: MapBlock:getTile
-- Returns the GID of the tile at (x, y) on the given layer (1-based).
-- Layer/x/y are 1-based; returns 0 for empty cells.
do  -- MapBlock:getTile
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setTile(1, 3, 3, 5)
  local gid = block:getTile(1, 3, 3)
  lurek.log.info("block tile (3,3) gid=" .. gid, "tilemap")
end

--@api-stub: MapBlock:getSide
-- Returns the side connection ID for a segment on a given edge.
-- Edge is 'north', 'east', 'south', or 'west'; segments are 1-based along each edge.
do  -- MapBlock:getSide
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setSide("north", 1, 7)
  local id = block:getSide("north", 1)
  lurek.log.info("north edge segment 1 connection id=" .. id, "tilemap")
end

--@api-stub: MapBlock:getWidth
-- Returns the block width in tiles.
-- Read the authored block width to validate against an expected room size.
do  -- MapBlock:getWidth
  local block = lurek.tilemap.newMapBlock(12, 8, 1, 4)
  lurek.log.info("block width " .. block:getWidth() .. " tiles", "tilemap")
end

--@api-stub: MapBlock:getHeight
-- Returns the block height in tiles.
-- Pair with getWidth to compute the block bounding box for placement queries.
do  -- MapBlock:getHeight
  local block = lurek.tilemap.newMapBlock(8, 12, 1, 4)
  lurek.log.info("block height " .. block:getHeight() .. " tiles", "tilemap")
end

--@api-stub: MapBlock:getDimensions
-- Returns the block dimensions as (width, height) in tiles.
-- Single-call alternative to getWidth/getHeight; returns (w, h).
do  -- MapBlock:getDimensions
  local block = lurek.tilemap.newMapBlock(10, 6, 1, 2)
  local w, h = block:getDimensions()
  lurek.log.info("block " .. w .. "x" .. h, "tilemap")
end

--@api-stub: MapBlock:getLayerCount
-- Returns the number of layers in this block.
-- Use to drive a per-layer iteration when copying a block into a TileMap.
do  -- MapBlock:getLayerCount
  local block = lurek.tilemap.newMapBlock(8, 8, 3, 4)
  lurek.log.info("block has " .. block:getLayerCount() .. " layer(s)", "tilemap")
end

--@api-stub: MapBlock:getSegmentSize
-- Returns the segment size in tiles.
-- Edges are split into segments of this many tiles; segment-level matching drives MapGen connections.
do  -- MapBlock:getSegmentSize
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  lurek.log.info("segment size = " .. block:getSegmentSize() .. " tiles", "tilemap")
end

--@api-stub: MapBlock:getWidthInSegments
-- Returns the number of segments along the width.
-- Equals getWidth() / getSegmentSize(); use when laying out edge-connection rules.
do  -- MapBlock:getWidthInSegments
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  lurek.log.info("block is " .. block:getWidthInSegments() .. " segments wide", "tilemap")
end

--@api-stub: MapBlock:getHeightInSegments
-- Returns the number of segments along the height.
-- Pair with getWidthInSegments when iterating over every edge segment of the block.
do  -- MapBlock:getHeightInSegments
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  lurek.log.info("block is " .. block:getHeightInSegments() .. " segments tall", "tilemap")
end

--@api-stub: MapBlock:setName
-- Sets the human-readable name of this block.
-- Names appear in MapGen logging and tooling; pick something searchable like '"start_room"'.
do  -- MapBlock:setName
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setName("treasure_room")
  lurek.log.info("named block: " .. block:getName(), "tilemap")
end

--@api-stub: MapBlock:getName
-- Returns the name of this block.
-- Read the authored name to filter blocks before adding them to a MapGroup.
do  -- MapBlock:getName
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setName("corridor_h")
  if block:getName():match("^corridor") then
    lurek.log.info("block is a corridor variant", "tilemap")
  end
end

--@api-stub: MapBlock:setWeight
-- Sets the placement weight.
-- Higher weights make MapGen pick this block more often; default is 1.0.
do  -- MapBlock:setWeight
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setWeight(3.5)  -- show up 3.5x more often than weight=1 blocks
  lurek.log.info("weight = " .. block:getWeight(), "tilemap")
end

--@api-stub: MapBlock:getWeight
-- Returns the placement weight.
-- Read after setWeight to confirm the value MapGen will sample with.
do  -- MapBlock:getWeight
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  if block:getWeight() < 1.0 then
    lurek.log.warn("block '" .. block:getName() .. "' is rare", "tilemap")
  end
end

-- ── MapGroup methods ──

--@api-stub: MapGroup:addBlock
-- Adds a block to this group.
-- Add every block variant once; MapGen will sample using each block's weight.
do  -- MapGroup:addBlock
  local group = lurek.tilemap.newMapGroup("rooms")
  group:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  group:addBlock(lurek.tilemap.newMapBlock(12, 8, 1, 4))
  lurek.log.info("group has " .. group:getBlockCount() .. " blocks", "tilemap")
end

--@api-stub: MapGroup:getBlockCount
-- Returns the number of blocks in this group.
-- Use to validate level data loaded from disk before passing the group to MapGen.
do  -- MapGroup:getBlockCount
  local group = lurek.tilemap.newMapGroup("rooms")
  group:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  if group:getBlockCount() == 0 then
    lurek.log.error("group '" .. group:getName() .. "' is empty", "tilemap")
  end
end

--@api-stub: MapGroup:removeBlock
-- Removes a block by 1-based index.
-- 1-based index; remove a misauthored block before generation without rebuilding the group.
do  -- MapGroup:removeBlock
  local group = lurek.tilemap.newMapGroup("rooms")
  group:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  group:addBlock(lurek.tilemap.newMapBlock(12, 8, 1, 4))
  group:removeBlock(1)  -- drop first block
end

--@api-stub: MapGroup:getName
-- Returns the name of this group.
-- Use when logging or when a generator picks a group from a registry by name.
do  -- MapGroup:getName
  local group = lurek.tilemap.newMapGroup("dungeon_floor_1")
  lurek.log.info("active group: " .. group:getName(), "tilemap")
end

--@api-stub: MapGroup:addScript
-- Adds a MapScript to this group.
-- Attach generation scripts (random fill, place, flood) that MapGen runs in order.
do  -- MapGroup:addScript
  local group = lurek.tilemap.newMapGroup("rooms")
  local script = lurek.tilemap.newMapScript()
  script:addStep({ type = "fillRandom", gid = 1, chance = 0.2 })
  group:addScript(script)
end

--@api-stub: MapGroup:getScriptCount
-- Returns the number of scripts in this group.
-- Use to validate that all expected scripts loaded before generation begins.
do  -- MapGroup:getScriptCount
  local group = lurek.tilemap.newMapGroup("rooms")
  group:addScript(lurek.tilemap.newMapScript())
  lurek.log.info("group has " .. group:getScriptCount() .. " script(s)", "tilemap")
end

-- ── MapScript methods ──

--@api-stub: MapScript:getStepCount
-- Returns the number of steps in this script.
-- Inspect the step count after addStep calls to confirm a script loaded as expected.
do  -- MapScript:getStepCount
  local script = lurek.tilemap.newMapScript()
  script:addStep({ type = "fillArea", x = 1, y = 1, w = 8, h = 8, gid = 1 })
  lurek.log.info("script step count: " .. script:getStepCount(), "tilemap")
end

--@api-stub: MapScript:addStep
-- Appends a generation step from a step-definition table.
-- Step `type` must be one of fillRandom/placeBlock/placeRandom/placeLine/floodFill/fillArea/drawPath/fillRect.
do  -- MapScript:addStep
  local script = lurek.tilemap.newMapScript()
  script:addStep({ type = "fillRect", x = 0, y = 0, w = 16, h = 16, gid = 1 })
  script:addStep({ type = "drawPath", x = 1, y = 1, w = 14, h = 14, gid = 2, pathWidth = 2 })
  lurek.log.info("authored " .. script:getStepCount() .. " step(s)", "tilemap")
end
