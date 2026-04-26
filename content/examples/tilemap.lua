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
    local xml = [[
<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" tiledversion="1.10.2" orientation="orthogonal" renderorder="right-down" width="2" height="2" tilewidth="16" tileheight="16" infinite="0">
  <layer id="1" name="Ground" width="2" height="2">
    <data encoding="csv">1,0,0,1</data>
  </layer>
</map>
]]
    local meta = lurek.tilemap.loadTMX(xml)
    if meta ~= nil then
      lurek.log.info("TMX " .. meta.width .. "x" .. meta.height .. " orient=" .. meta.orientation .. " layers=" .. #meta.layers, "tilemap")
    end
  end)
end

--@api-stub: lurek.tilemap.fromLDtk
-- Parses an LDtk JSON export string and returns a TileMap.
-- Pass an optional level name to pick from a multi-level project; defaults to the first level.
do  -- lurek.tilemap.fromLDtk
  pcall(function()
    local json = [[
{
  "iid": "example-project",
  "jsonVersion": "1.5.3",
  "defs": {
    "layers": [
      {
        "identifier": "Ground",
        "type": "IntGrid",
        "uid": 1,
        "gridSize": 16
      }
    ],
    "tilesets": []
  },
  "levels": [
    {
      "identifier": "Level_0",
      "uid": 1,
      "pxWid": 32,
      "pxHei": 32,
      "worldX": 0,
      "worldY": 0,
      "layerInstances": [
        {
          "__identifier": "Ground",
          "__type": "IntGrid",
          "__cWid": 2,
          "__cHei": 2,
          "__gridSize": 16,
          "intGridCsv": [1, 0, 0, 1],
          "autoLayerTiles": [],
          "gridTiles": []
        }
      ]
    }
  ]
}
]]
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
  function lurek.draw() map:render(-cam_x, -cam_y) end
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
    local x, y = sheet:getQuad(3)
    lurek.log.info("autotile 3 quad x=" .. x .. " y=" .. y, "tilemap")
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
  local player_x, player_y = 0, 0
  function lurek.process(dt) r:setCamera(player_x, player_y, 1.0) end
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

--@api-stub: TileMap:onTileStep
-- Register a callback fired when an entity steps onto a tile with the given GID.
-- @param gid integer, @param fn function(entity, tx, ty)
do  -- TileMap:onTileStep
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:onTileStep(5, function(entity, tx, ty)
    lurek.log.debug("entity stepped on gid=5 at " .. tx .. "," .. ty, "tilemap")
  end)
end

--@api-stub: TileMap:onTileExit
-- Register a callback fired when an entity exits a tile with the given GID.
-- @param gid integer, @param fn function(entity, tx, ty)
do  -- TileMap:onTileExit
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:onTileExit(5, function(entity, tx, ty)
    lurek.log.debug("entity exited gid=5 at " .. tx .. "," .. ty, "tilemap")
  end)
end

--@api-stub: TileMap:fireTileStep
-- Manually fire the onTileStep callback for a GID, entity, and tile coords.
-- Used by physics integrations or scripted movement systems.
do  -- TileMap:fireTileStep
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:fireTileStep(5, {id="player", x=64, y=64}, 2, 3)
  lurek.log.debug("fireTileStep called", "tilemap")
end

--@api-stub: TileMap:fireTileExit
-- Manually fire the onTileExit callback for a GID, entity, and tile coords.
-- Used by scripted teleport or scene-transition systems that bypass the physics step.
do  -- TileMap:fireTileExit
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:fireTileExit(5, {id="player", x=64, y=64}, 2, 3)
  lurek.log.debug("fireTileExit called", "tilemap")
end

--@api-stub: TileMap:applyAutoTile
-- Applies auto-tiling rules to every cell in all layers using the attached TileSet.
-- Call after bulk map edits to recalculate all tile border variants at once.
do  -- TileMap:applyAutoTile
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:fill(1, 1)
  tm:applyAutoTile(1, "terrain")
  lurek.log.info("auto-tile applied", "tilemap")
end

--@api-stub: TileMap:applyAutoTile8
-- Applies 8-direction auto-tiling to the entire map, considering diagonal neighbours.
-- Produces more natural corners and borders than the 4-direction variant.
do  -- TileMap:applyAutoTile8
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:fill(1, 1)
  tm:applyAutoTile8(1, "terrain")
  lurek.log.info("8-way auto-tile applied", "tilemap")
end

--@api-stub: TileMap:applyAutoTile8At
-- Applies 8-direction auto-tiling rules only at a specific cell and its neighbours.
-- Faster than a full applyAutoTile8 when only a single cell has changed.
do  -- TileMap:applyAutoTile8
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:setTile(1, 5, 5, 1)
  tm:applyAutoTile8At(1, 5, 5, "terrain")
  lurek.log.info("8-way at-cell applied", "tilemap")
end

--@api-stub: TileMap:applyAutoTileAt
-- Applies 4-direction auto-tiling rules at a single cell and its cardinal neighbours.
-- Cheaper than a full map pass when editing tiles interactively.
do  -- TileMap:applyAutoTileAt
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:setTile(1, 8, 8, 1)
  tm:applyAutoTileAt(1, 8, 8, "terrain")
  lurek.log.info("auto-tile at-cell applied", "tilemap")
end

--@api-stub: AutoTileSheet:applyToTileSet
-- Copies the auto-tile quads and rules from this sheet into a TileSet.
-- Call once after loading the sheet; the TileSet then supports applyAutoTile.
do  -- AutoTileSheet:applyToTileSet
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local ats = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  ats:applyToTileSet(ts, "normal")
  lurek.log.info("auto-tile sheet applied to tileset", "tilemap")
end

--@api-stub: TileMap:checkEntities
-- Tests all registered entity rectangles against solid tiles and fires overlap callbacks.
-- Call each frame before physics to handle tile-based collision responses.
do  -- TileMap:checkEntities
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:onTileStep(1, function(entity, tx, ty) lurek.log.info("overlap at " .. tx .. "," .. ty, "tilemap") end)
  tm:checkEntities(1, {{x=40,y=40}})
  lurek.log.info("entities checked", "tilemap")
end

--@api-stub: ChunkMap:fillRect
-- Fills a rectangle of cells in the chunk map with the given tile GID.
-- Works across chunk boundaries; loads chunks if needed.
do  -- ChunkMap:fillRect
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local cm = lurek.tilemap.newChunkMap(16)
  cm:fillRect(0, 0, 31, 31, 1)
  lurek.log.info("chunk rect filled", "tilemap")
end

--@api-stub: MapGen:generate
-- Runs the map generator and returns a 2D table of tile GIDs.
-- Generator parameters are set at construction; call once per new level.
do  -- MapGen:generate
  local grp = lurek.tilemap.newMapGroup("dungeon")
  local gen = lurek.tilemap.newMapGen(grp, "medium", 4)
  local tm = gen:generate()
  lurek.log.info("map generated", "tilemap")
end

--@api-stub: TileSet:getAutoTileId
-- Returns the tile GID for a given 4-bit auto-tile bitmask.
-- Used internally by applyAutoTile; call directly for custom rendering.
do  -- TileSet:getAutoTileId
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local gid = ts:getAutoTileId("terrain", 15)
  lurek.log.info("auto-tile gid: " .. (gid or -1), "tilemap")
end

--@api-stub: TileSet:getAutoTileId8
-- Returns the tile GID for a given 8-bit auto-tile bitmask (8-direction variant).
-- bitmask encodes N/NE/E/SE/S/SW/W/NW neighbours as individual bits.
do  -- TileSet:getAutoTileId8
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local gid = ts:getAutoTileId8("terrain", 255)
  lurek.log.info("8-way auto-tile gid: " .. (gid or -1), "tilemap")
end

--@api-stub: ChunkMap:getChunksInView
-- Returns a list of chunk coordinate pairs currently overlapping the camera viewport.
-- Use to decide which chunks to stream in or render each frame.
do  -- ChunkMap:getChunksInView
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local cm = lurek.tilemap.newChunkMap(16)
  local chunks = cm:getChunksInView(0, 0, 320, 240, 16, 16)
  lurek.log.info("chunks in view: " .. #chunks, "tilemap")
end

--@api-stub: IsoMap:getTilePart
-- Returns the tile GID for a specific named part of an isometric tile at (x, y, level).
-- Parts split a tile into floor, wall, top, and decorations for layered rendering.
do  -- IsoMap:getTilePart
  local im = lurek.tilemap.newIsoMap(16, 16, 32, 16, 8)
  im:addLevel()
  local gid = im:getTilePart(1, 1, 1, 0)
  lurek.log.info("tile part gid: " .. (gid or 0), "tilemap")
end

--@api-stub: TileMap:onTileEnter
-- Registers a callback that fires when an entity moves onto a cell with the given GID.
-- Use for trigger tiles: damage zones, teleporters, chest-open triggers.
do  -- TileMap:onTileEnter
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:onTileEnter(5, function(entity, tx, ty)
    lurek.log.info("entered tile 5 at " .. tx .. "," .. ty, "tilemap")
  end)
  lurek.log.info("tile enter callback registered", "tilemap")
end

--@api-stub: TileMap:rectOverlapsSolid
-- Returns true if a world-space rectangle overlaps any solid tile.
-- Use for AABB-based pre-collision tests before physics resolution.
do  -- TileMap:rectOverlapsSolid
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setSolid(1, true)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:setTile(1, 3, 3, 1)
  local hit = tm:rectOverlapsSolid(1, 48, 48, 16, 16)
  lurek.log.info("overlap: " .. tostring(hit), "tilemap")
end

--@api-stub: TileSet:setAnimation
-- Assigns a looping frame sequence to a tile GID for animated tiles.
-- frames is a table of GIDs; duration is total seconds for one full cycle.
do  -- TileSet:setAnimation
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setAnimation(5, {{tileid=5, duration=0.125}, {tileid=6, duration=0.125}, {tileid=7, duration=0.125}, {tileid=8, duration=0.125}})
  lurek.log.info("tile animation set", "tilemap")
end

--@api-stub: TileSet:setAutoTileRule
-- Defines a 4-direction auto-tile rule: when neighbours match the bitmask, use this GID.
-- Use to register custom terrain transitions beyond the default ruleset.
do  -- TileSet:setAutoTileRule
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setAutoTileRule("terrain", 15, 10)
  lurek.log.info("auto-tile rule set", "tilemap")
end

--@api-stub: TileSet:setAutoTileRule8
-- Defines an 8-direction auto-tile rule for diagonal-neighbour aware tile selection.
-- bitmask encodes all 8 neighbours; pass the desired GID for that configuration.
do  -- TileSet:setAutoTileRule8
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setAutoTileRule8("terrain", 255, 20)
  lurek.log.info("8-way auto-tile rule set", "tilemap")
end

--@api-stub: TileMap:setLayerColor
-- Sets the tint colour for an entire map layer, blending with individual tile tints.
-- Use to apply a day/night atmosphere tint to background layers.
do  -- TileMap:setLayerColor
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  local bgLayer = tm:addLayer("background", 16, 16)
  tm:setLayerColor(bgLayer, 0.7, 0.8, 1.0, 1.0)
  lurek.log.info("layer colour set", "tilemap")
end

--@api-stub: TileMap:setLayerOffset
-- Sets a pixel offset for a named layer, shifting it relative to the base grid.
-- Use for decorative layers that need sub-tile alignment.
do  -- TileMap:setLayerOffset
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  local decalLayer = tm:addLayer("decals", 16, 16)
  tm:setLayerOffset(decalLayer, 4, -2)
  lurek.log.info("layer offset set", "tilemap")
end

--@api-stub: TileMap:setLayerParallax
-- Sets a parallax scroll factor for a named layer.
-- factor < 1 makes the layer scroll slower than the camera (background effect).
do  -- TileMap:setLayerParallax
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  local hillLayer = tm:addLayer("bg_hills", 16, 16)
  tm:setLayerParallax(hillLayer, 0.4, 0.0)
  lurek.log.info("parallax set", "tilemap")
end

--@api-stub: TileMap:setLayerVisible
-- Shows or hides a named map layer without removing it.
-- Toggle for editing workflow or conditional HUD layers.
do  -- TileMap:setLayerVisible
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  local dbgLayer = tm:addLayer("collision_debug", 16, 16)
  tm:setLayerVisible(dbgLayer, false)
  lurek.log.info("layer hidden", "tilemap")
end

--@api-stub: LargeMapRenderer:setMapData
-- Loads tile data into the large-map renderer from a flat GID table.
-- table length must equal width*height; row-major order, starting from top-left.
do  -- LargeMapRenderer:setMapData
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  local data = {}
  for i=1,128*128 do data[i]=1 end
  r:setMapData(data, 128, 128)
  lurek.log.info("large map data loaded", "tilemap")
end

--@api-stub: MapBlock:setSide
-- Sets the tile GID for a specific side face (N/S/E/W) of a 3D map block cell.
-- Side faces are used for isometric and first-person wall rendering.
do  -- MapBlock:setSide
  local mb = lurek.tilemap.newMapBlock(8, 8)
  mb:setSide("north", 1, 5)
  lurek.log.info("block side set", "tilemap")
end

--@api-stub: TileMap:setTile
-- Sets the tile GID at (x, y) in the specified layer.
-- GID=0 clears the cell; non-zero GIDs reference tiles in the attached TileSet.
do  -- TileMap:setTile
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:setTile(1, 4, 5, 2)
  lurek.log.info("tile GID set: " .. tm:getTile(1, 4, 5), "tilemap")
end

--@api-stub: ChunkMap:setTile
-- Sets the tile GID at a world-space cell in the chunk map, loading the chunk if needed.
-- Chunks are loaded/created on demand; the cell persists until explicitly cleared.
do  -- ChunkMap:setTile
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local cm = lurek.tilemap.newChunkMap(16)
  cm:setTile(20, 20, 3)
  lurek.log.info("chunk tile set", "tilemap")
end

--@api-stub: IsoMap:setTilePart
-- Sets the tile GID for a specific named part of an isometric cell at (x, y, level).
-- Parts allow multi-layer isometric tiles: floor, walls, top decoration.
do  -- IsoMap:setTilePart
  local im = lurek.tilemap.newIsoMap(16, 16, 32, 16, 8)
  im:addLevel()
  im:setTilePart(1, 1, 1, 0, 5)
  lurek.log.info("iso tile part set", "tilemap")
end

--@api-stub: TileMap:setTileTint
-- Sets the RGBA tint for a specific tile cell in a layer.
-- Tint multiplies the tile's texture colour; (1,1,1,1) means no tint change.
do  -- TileMap:setTileTint
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:setTile(1, 5, 5, 1)
  tm:setTileTint(1, 5, 5, 1.0, 0.5, 0.5, 1.0)
  lurek.log.info("tile tint set", "tilemap")
end

--@api-stub: TileMap:setViewport
-- Restricts rendering to the given world-space rectangle.
-- Tiles outside the viewport are skipped; update each frame with the camera region.
do  -- TileMap:setViewport
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:setViewport(0, 0, 320, 240)
  lurek.log.info("tilemap viewport set", "tilemap")
end

--@api-stub: TileMap:sweepRect
-- Sweeps a moving rectangle through the map and returns the first solid-tile hit.
-- Returns the resolved position and hit normal; returns nil if no collision.
do  -- TileMap:sweepRect
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setSolid(1, true)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:setTile(1, 5, 5, 1)
  local hit = tm:sweepRect(1, 0, 80, 16, 16, 100, 0)
  lurek.log.info("sweep hit: " .. tostring(hit ~= nil), "tilemap")
end

--@api-stub: TileMap:toNavGrid
-- Converts the tile map's solid-tile pattern into a NavGrid for pathfinding.
-- Solid tiles become blocked cells; returns a lurek.pathfind NavGrid.
do  -- TileMap:toNavGrid
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setSolid(1, true)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:fill(1, 1)
  local grid = tm:toNavGrid(1, {1})
  lurek.log.info("nav grid: " .. #grid .. " rows", "tilemap")
end

--@api-stub: MapBlock:setTile
-- Sets the floor tile GID at a specific (x, y) cell in a MapBlock grid.
-- Used to configure the base terrain for isometric block rendering.
do  -- MapBlock:setTile
  local mb = lurek.tilemap.newMapBlock(8, 8)
  mb:setTile(1, 2, 3, 1)
  mb:setTile(1, 4, 4, 2)
  lurek.log.info("map block tiles set", "tilemap")
end

-- =============================================================================
-- STUBS: 20 uncovered lurek.tilemap API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- AutoTileSheet methods
-- -----------------------------------------------------------------------------

-- ---- Stub: AutoTileSheet:type --------------------------------------------
--@api-stub: AutoTileSheet:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- autoTileSheet_stub:type()  -- -> string
-- (replace autoTileSheet_stub with your real AutoTileSheet instance above)

-- ---- Stub: AutoTileSheet:typeOf ------------------------------------------
--@api-stub: AutoTileSheet:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- autoTileSheet_stub:typeOf("hero")  -- -> boolean
-- (replace autoTileSheet_stub with your real AutoTileSheet instance above)

-- -----------------------------------------------------------------------------
-- ChunkMap methods
-- -----------------------------------------------------------------------------

-- ---- Stub: ChunkMap:type -------------------------------------------------
--@api-stub: ChunkMap:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- chunkMap_stub:type()  -- -> string
-- (replace chunkMap_stub with your real ChunkMap instance above)

-- ---- Stub: ChunkMap:typeOf -----------------------------------------------
--@api-stub: ChunkMap:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- chunkMap_stub:typeOf("hero")  -- -> boolean
-- (replace chunkMap_stub with your real ChunkMap instance above)

-- -----------------------------------------------------------------------------
-- IsoMap methods
-- -----------------------------------------------------------------------------

-- ---- Stub: IsoMap:type ---------------------------------------------------
--@api-stub: IsoMap:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- isoMap_stub:type()  -- -> string
-- (replace isoMap_stub with your real IsoMap instance above)

-- ---- Stub: IsoMap:typeOf -------------------------------------------------
--@api-stub: IsoMap:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- isoMap_stub:typeOf("hero")  -- -> boolean
-- (replace isoMap_stub with your real IsoMap instance above)

-- -----------------------------------------------------------------------------
-- LargeMapRenderer methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LargeMapRenderer:type -----------------------------------------
--@api-stub: LargeMapRenderer:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- largeMapRenderer_stub:type()  -- -> string
-- (replace largeMapRenderer_stub with your real LargeMapRenderer instance above)

-- ---- Stub: LargeMapRenderer:typeOf ---------------------------------------
--@api-stub: LargeMapRenderer:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- largeMapRenderer_stub:typeOf("hero")  -- -> boolean
-- (replace largeMapRenderer_stub with your real LargeMapRenderer instance above)

-- -----------------------------------------------------------------------------
-- MapBlock methods
-- -----------------------------------------------------------------------------

-- ---- Stub: MapBlock:type -------------------------------------------------
--@api-stub: MapBlock:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- mapBlock_stub:type()  -- -> string
-- (replace mapBlock_stub with your real MapBlock instance above)

-- ---- Stub: MapBlock:typeOf -----------------------------------------------
--@api-stub: MapBlock:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- mapBlock_stub:typeOf("hero")  -- -> boolean
-- (replace mapBlock_stub with your real MapBlock instance above)

-- -----------------------------------------------------------------------------
-- MapGen methods
-- -----------------------------------------------------------------------------

-- ---- Stub: MapGen:type ---------------------------------------------------
--@api-stub: MapGen:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- mapGen_stub:type()  -- -> string
-- (replace mapGen_stub with your real MapGen instance above)

-- ---- Stub: MapGen:typeOf -------------------------------------------------
--@api-stub: MapGen:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- mapGen_stub:typeOf("hero")  -- -> boolean
-- (replace mapGen_stub with your real MapGen instance above)

-- -----------------------------------------------------------------------------
-- MapGroup methods
-- -----------------------------------------------------------------------------

-- ---- Stub: MapGroup:type -------------------------------------------------
--@api-stub: MapGroup:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- mapGroup_stub:type()  -- -> string
-- (replace mapGroup_stub with your real MapGroup instance above)

-- ---- Stub: MapGroup:typeOf -----------------------------------------------
--@api-stub: MapGroup:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- mapGroup_stub:typeOf("hero")  -- -> boolean
-- (replace mapGroup_stub with your real MapGroup instance above)

-- -----------------------------------------------------------------------------
-- MapScript methods
-- -----------------------------------------------------------------------------

-- ---- Stub: MapScript:type ------------------------------------------------
--@api-stub: MapScript:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- mapScript_stub:type()  -- -> string
-- (replace mapScript_stub with your real MapScript instance above)

-- ---- Stub: MapScript:typeOf ----------------------------------------------
--@api-stub: MapScript:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- mapScript_stub:typeOf("hero")  -- -> boolean
-- (replace mapScript_stub with your real MapScript instance above)

-- -----------------------------------------------------------------------------
-- TileMap methods
-- -----------------------------------------------------------------------------

-- ---- Stub: TileMap:type --------------------------------------------------
--@api-stub: TileMap:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- tileMap_stub:type()  -- -> string
-- (replace tileMap_stub with your real TileMap instance above)

-- ---- Stub: TileMap:typeOf ------------------------------------------------
--@api-stub: TileMap:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- tileMap_stub:typeOf("hero")  -- -> boolean
-- (replace tileMap_stub with your real TileMap instance above)

-- -----------------------------------------------------------------------------
-- TileSet methods
-- -----------------------------------------------------------------------------

-- ---- Stub: TileSet:type --------------------------------------------------
--@api-stub: TileSet:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- tileSet_stub:type()  -- -> string
-- (replace tileSet_stub with your real TileSet instance above)

-- ---- Stub: TileSet:typeOf ------------------------------------------------
--@api-stub: TileSet:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- tileSet_stub:typeOf("hero")  -- -> boolean
-- (replace tileSet_stub with your real TileSet instance above)

-- =============================================================================
-- STUBS: 20 uncovered lurek.tilemap API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LAutoTileSheet methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAutoTileSheet:type -------------------------------------------
--@api-stub: LAutoTileSheet:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAutoTileSheet_stub:type()  -- -> string
-- (replace lAutoTileSheet_stub with your real LAutoTileSheet instance above)

-- ---- Stub: LAutoTileSheet:typeOf -----------------------------------------
--@api-stub: LAutoTileSheet:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAutoTileSheet_stub:typeOf("hero")  -- -> boolean
-- (replace lAutoTileSheet_stub with your real LAutoTileSheet instance above)

-- -----------------------------------------------------------------------------
-- LChunkMap methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LChunkMap:type ------------------------------------------------
--@api-stub: LChunkMap:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lChunkMap_stub:type()  -- -> string
-- (replace lChunkMap_stub with your real LChunkMap instance above)

-- ---- Stub: LChunkMap:typeOf ----------------------------------------------
--@api-stub: LChunkMap:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lChunkMap_stub:typeOf("hero")  -- -> boolean
-- (replace lChunkMap_stub with your real LChunkMap instance above)

-- -----------------------------------------------------------------------------
-- LIsoMap methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LIsoMap:type --------------------------------------------------
--@api-stub: LIsoMap:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:type()  -- -> string
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:typeOf ------------------------------------------------
--@api-stub: LIsoMap:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:typeOf("hero")  -- -> boolean
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- -----------------------------------------------------------------------------
-- LLargeMapRenderer methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LLargeMapRenderer:type ----------------------------------------
--@api-stub: LLargeMapRenderer:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:type()  -- -> string
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:typeOf --------------------------------------
--@api-stub: LLargeMapRenderer:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:typeOf("hero")  -- -> boolean
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- -----------------------------------------------------------------------------
-- LMapBlock methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMapBlock:type ------------------------------------------------
--@api-stub: LMapBlock:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:type()  -- -> string
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- ---- Stub: LMapBlock:typeOf ----------------------------------------------
--@api-stub: LMapBlock:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:typeOf("hero")  -- -> boolean
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- -----------------------------------------------------------------------------
-- LMapGen methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMapGen:type --------------------------------------------------
--@api-stub: LMapGen:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapGen_stub:type()  -- -> string
-- (replace lMapGen_stub with your real LMapGen instance above)

-- ---- Stub: LMapGen:typeOf ------------------------------------------------
--@api-stub: LMapGen:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapGen_stub:typeOf("hero")  -- -> boolean
-- (replace lMapGen_stub with your real LMapGen instance above)

-- -----------------------------------------------------------------------------
-- LMapGroup methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMapGroup:type ------------------------------------------------
--@api-stub: LMapGroup:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapGroup_stub:type()  -- -> string
-- (replace lMapGroup_stub with your real LMapGroup instance above)

-- ---- Stub: LMapGroup:typeOf ----------------------------------------------
--@api-stub: LMapGroup:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapGroup_stub:typeOf("hero")  -- -> boolean
-- (replace lMapGroup_stub with your real LMapGroup instance above)

-- -----------------------------------------------------------------------------
-- LMapScript methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMapScript:type -----------------------------------------------
--@api-stub: LMapScript:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapScript_stub:type()  -- -> string
-- (replace lMapScript_stub with your real LMapScript instance above)

-- ---- Stub: LMapScript:typeOf ---------------------------------------------
--@api-stub: LMapScript:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapScript_stub:typeOf("hero")  -- -> boolean
-- (replace lMapScript_stub with your real LMapScript instance above)

-- -----------------------------------------------------------------------------
-- LTileMap methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTileMap:type -------------------------------------------------
--@api-stub: LTileMap:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:type()  -- -> string
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:typeOf -----------------------------------------------
--@api-stub: LTileMap:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:typeOf("hero")  -- -> boolean
-- (replace lTileMap_stub with your real LTileMap instance above)

-- -----------------------------------------------------------------------------
-- LTileSet methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTileSet:type -------------------------------------------------
--@api-stub: LTileSet:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:type()  -- -> string
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:typeOf -----------------------------------------------
--@api-stub: LTileSet:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:typeOf("hero")  -- -> boolean
-- (replace lTileSet_stub with your real LTileSet instance above)

-- =============================================================================
-- STUBS: 140 uncovered lurek.tilemap API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LAutoTileSheet methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAutoTileSheet:getLayout --------------------------------------
--@api-stub: LAutoTileSheet:getLayout
-- Returns the layout variant as a string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAutoTileSheet_stub:getLayout()  -- -> string
-- (replace lAutoTileSheet_stub with your real LAutoTileSheet instance above)

-- ---- Stub: LAutoTileSheet:getTileCount -----------------------------------
--@api-stub: LAutoTileSheet:getTileCount
-- Returns the number of tiles in this sheet.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAutoTileSheet_stub:getTileCount()  -- -> integer
-- (replace lAutoTileSheet_stub with your real LAutoTileSheet instance above)

-- ---- Stub: LAutoTileSheet:getTileWidth -----------------------------------
--@api-stub: LAutoTileSheet:getTileWidth
-- Returns the tile width in pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAutoTileSheet_stub:getTileWidth()  -- -> integer
-- (replace lAutoTileSheet_stub with your real LAutoTileSheet instance above)

-- ---- Stub: LAutoTileSheet:getTileHeight ----------------------------------
--@api-stub: LAutoTileSheet:getTileHeight
-- Returns the tile height in pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAutoTileSheet_stub:getTileHeight()  -- -> integer
-- (replace lAutoTileSheet_stub with your real LAutoTileSheet instance above)

-- ---- Stub: LAutoTileSheet:applyToTileSet ---------------------------------
--@api-stub: LAutoTileSheet:applyToTileSet
-- Applies autotile rules from this sheet to a TileSet.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAutoTileSheet_stub:applyToTileSet(ts_ud, type_name, [start_gid])
-- (replace lAutoTileSheet_stub with your real LAutoTileSheet instance above)

-- ---- Stub: LAutoTileSheet:getBitmaskForTile ------------------------------
--@api-stub: LAutoTileSheet:getBitmaskForTile
-- Returns the bitmask value associated with a 1-based local tile ID.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAutoTileSheet_stub:getBitmaskForTile(tile_id)  -- -> integer
-- (replace lAutoTileSheet_stub with your real LAutoTileSheet instance above)

-- ---- Stub: LAutoTileSheet:getTileForBitmask ------------------------------
--@api-stub: LAutoTileSheet:getTileForBitmask
-- Returns the 1-based tile ID for a given bitmask, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAutoTileSheet_stub:getTileForBitmask(bitmask)  -- -> integer?
-- (replace lAutoTileSheet_stub with your real LAutoTileSheet instance above)

-- ---- Stub: LAutoTileSheet:getQuad ----------------------------------------
--@api-stub: LAutoTileSheet:getQuad
-- Returns the atlas region rectangle for the 1-based tile ID.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAutoTileSheet_stub:getQuad(tile_id)  -- -> number, number, number, number
-- (replace lAutoTileSheet_stub with your real LAutoTileSheet instance above)

-- -----------------------------------------------------------------------------
-- LChunkMap methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LChunkMap:getTile ---------------------------------------------
--@api-stub: LChunkMap:getTile
-- Returns the GID at tile coordinate (x, y).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lChunkMap_stub:getTile(0.0, 0.0)  -- -> integer
-- (replace lChunkMap_stub with your real LChunkMap instance above)

-- ---- Stub: LChunkMap:setTile ---------------------------------------------
--@api-stub: LChunkMap:setTile
-- Sets the GID at tile coordinate (x, y).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lChunkMap_stub:setTile(0.0, 0.0, gid)
-- (replace lChunkMap_stub with your real LChunkMap instance above)

-- ---- Stub: LChunkMap:clearTile -------------------------------------------
--@api-stub: LChunkMap:clearTile
-- Clears the tile at (x, y) by setting its GID to 0.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lChunkMap_stub:clearTile(0.0, 0.0)
-- (replace lChunkMap_stub with your real LChunkMap instance above)

-- ---- Stub: LChunkMap:fillRect --------------------------------------------
--@api-stub: LChunkMap:fillRect
-- Fills the rectangular tile region with a GID.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lChunkMap_stub:fillRect(x0, y0, x1, y1, gid)
-- (replace lChunkMap_stub with your real LChunkMap instance above)

-- ---- Stub: LChunkMap:loadChunk -------------------------------------------
--@api-stub: LChunkMap:loadChunk
-- Pre-allocates the chunk at chunk coordinates (cx, cy).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lChunkMap_stub:loadChunk(cx, cy)
-- (replace lChunkMap_stub with your real LChunkMap instance above)

-- ---- Stub: LChunkMap:unloadChunk -----------------------------------------
--@api-stub: LChunkMap:unloadChunk
-- Removes the chunk at chunk coordinates (cx, cy) from memory.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lChunkMap_stub:unloadChunk(cx, cy)
-- (replace lChunkMap_stub with your real LChunkMap instance above)

-- ---- Stub: LChunkMap:getChunkSize ----------------------------------------
--@api-stub: LChunkMap:getChunkSize
-- Returns the chunk size (tiles per side).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lChunkMap_stub:getChunkSize()  -- -> integer
-- (replace lChunkMap_stub with your real LChunkMap instance above)

-- ---- Stub: LChunkMap:getLoadedChunks -------------------------------------
--@api-stub: LChunkMap:getLoadedChunks
-- Returns a table of all currently loaded chunk coordinates as {{cx, cy}, ...}.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lChunkMap_stub:getLoadedChunks()  -- -> table
-- (replace lChunkMap_stub with your real LChunkMap instance above)

-- ---- Stub: LChunkMap:getChunksInView -------------------------------------
--@api-stub: LChunkMap:getChunksInView
-- Returns chunk coordinates whose world-pixel footprint overlaps the given viewport.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lChunkMap_stub:getChunksInView(vx, vy, vw, vh, tw, th)  -- -> table
-- (replace lChunkMap_stub with your real LChunkMap instance above)

-- ---- Stub: LChunkMap:chunkTileRange --------------------------------------
--@api-stub: LChunkMap:chunkTileRange
-- Returns the tile coordinate range for chunk (cx, cy) as (x0, y0, x1, y1).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lChunkMap_stub:chunkTileRange(cx, cy)  -- -> integer, integer, integer, integer
-- (replace lChunkMap_stub with your real LChunkMap instance above)

-- -----------------------------------------------------------------------------
-- LIsoMap methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LIsoMap:addLevel ----------------------------------------------
--@api-stub: LIsoMap:addLevel
-- Appends a new empty Z-level and returns its 1-based index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:addLevel()  -- -> integer
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:getLevelCount -----------------------------------------
--@api-stub: LIsoMap:getLevelCount
-- Returns the number of Z-levels currently in the map.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:getLevelCount()  -- -> integer
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:setLevelVisible ---------------------------------------
--@api-stub: LIsoMap:setLevelVisible
-- Sets the visibility of a level (1-based z).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:setLevelVisible(0, true)
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:isLevelVisible ----------------------------------------
--@api-stub: LIsoMap:isLevelVisible
-- Returns the visibility of a level (1-based z).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:isLevelVisible(0)  -- -> boolean
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:setTilePart -------------------------------------------
--@api-stub: LIsoMap:setTilePart
-- Writes a GID into the part slot of tile (x, y) on level z (1-based z, x, y; 0-based part).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:setTilePart(0, 0.0, 0.0, part, gid)
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:getTilePart -------------------------------------------
--@api-stub: LIsoMap:getTilePart
-- Reads the GID in the part slot of tile (x, y) on level z (1-based z, x, y; 0-based part).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:getTilePart(0, 0.0, 0.0, part)  -- -> integer
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:fillLevel ---------------------------------------------
--@api-stub: LIsoMap:fillLevel
-- Fills every cell in level z with gid for the given part (1-based z; 0-based part).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:fillLevel(0, part, gid)
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:setOrigin ---------------------------------------------
--@api-stub: LIsoMap:setOrigin
-- Sets the screen pixel origin.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:setOrigin(0.0, 0.0)
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:getWidth ----------------------------------------------
--@api-stub: LIsoMap:getWidth
-- Returns the map width in tiles.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:getWidth()  -- -> integer
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:getHeight ---------------------------------------------
--@api-stub: LIsoMap:getHeight
-- Returns the map height in tiles.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:getHeight()  -- -> integer
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:getTileWidth ------------------------------------------
--@api-stub: LIsoMap:getTileWidth
-- Returns the tile footprint width in pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:getTileWidth()  -- -> integer
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:getTileHeight -----------------------------------------
--@api-stub: LIsoMap:getTileHeight
-- Returns the tile footprint height in pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:getTileHeight()  -- -> integer
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:getLevelHeight ----------------------------------------
--@api-stub: LIsoMap:getLevelHeight
-- Returns the vertical pixel offset between consecutive Z-levels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:getLevelHeight()  -- -> integer
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:tileToScreen ------------------------------------------
--@api-stub: LIsoMap:tileToScreen
-- Projects isometric tile coordinates (tx, ty, tz) to screen pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:tileToScreen(tx, ty, tz)  -- -> number, number
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:screenToTile ------------------------------------------
--@api-stub: LIsoMap:screenToTile
-- Converts screen pixel coordinates to isometric tile coordinates at Z-level 0.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:screenToTile(1.0, 1.0)  -- -> number, number
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:getPartCount ------------------------------------------
--@api-stub: LIsoMap:getPartCount
-- Returns the number of GID slots per tile.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:getPartCount()  -- -> integer
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:getPartOrder ------------------------------------------
--@api-stub: LIsoMap:getPartOrder
-- Returns the current draw-order array (0-based part slot indices).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:getPartOrder()  -- -> table
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- ---- Stub: LIsoMap:setPartOrder ------------------------------------------
--@api-stub: LIsoMap:setPartOrder
-- Overrides the draw order for this IsoMap. Length must equal partCount.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lIsoMap_stub:setPartOrder(order)
-- (replace lIsoMap_stub with your real LIsoMap instance above)

-- -----------------------------------------------------------------------------
-- LLargeMapRenderer methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LLargeMapRenderer:setMapData ----------------------------------
--@api-stub: LLargeMapRenderer:setMapData
-- Loads a flat array of tile IDs (row-major) covering width Ă— height tiles.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:setMapData(data, 256, 256)
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:setTile -------------------------------------
--@api-stub: LLargeMapRenderer:setTile
-- Sets a single tile ID at (x, y).  Coordinates are 0-based.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:setTile(0.0, 0.0, tile_id)
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:getTile -------------------------------------
--@api-stub: LLargeMapRenderer:getTile
-- Returns the tile ID at (x, y), or nil if out of bounds.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:getTile(0.0, 0.0)  -- -> integer?
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:getMapSize ----------------------------------
--@api-stub: LLargeMapRenderer:getMapSize
-- Returns the map dimensions as (width, height) in tiles.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:getMapSize()  -- -> integer, integer
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:setChunkSize --------------------------------
--@api-stub: LLargeMapRenderer:setChunkSize
-- Sets the chunk size used for culling (default 16).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:setChunkSize(size)
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:getChunkSize --------------------------------
--@api-stub: LLargeMapRenderer:getChunkSize
-- Returns the current chunk size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:getChunkSize()  -- -> integer
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:invalidateChunk -----------------------------
--@api-stub: LLargeMapRenderer:invalidateChunk
-- Marks a chunk at chunk-grid coordinates (cx, cy) as dirty,
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:invalidateChunk(cx, cy)
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:invalidateAll -------------------------------
--@api-stub: LLargeMapRenderer:invalidateAll
-- Marks every chunk as dirty.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:invalidateAll()
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:getVisibleChunks ----------------------------
--@api-stub: LLargeMapRenderer:getVisibleChunks
-- Returns the number of chunks currently within the camera viewport.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:getVisibleChunks()  -- -> integer
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:getTotalChunks ------------------------------
--@api-stub: LLargeMapRenderer:getTotalChunks
-- Returns the total number of chunks that cover the loaded map.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:getTotalChunks()  -- -> integer
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:setCamera -----------------------------------
--@api-stub: LLargeMapRenderer:setCamera
-- Updates the camera position and zoom used for visibility culling.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:setCamera(0.0, 0.0, zoom)
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:setViewport ---------------------------------
--@api-stub: LLargeMapRenderer:setViewport
-- Sets the viewport dimensions in pixels used for visibility culling.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:setViewport(64.0, 64.0)
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:setLodEnabled -------------------------------
--@api-stub: LLargeMapRenderer:setLodEnabled
-- Enables or disables level-of-detail rendering for distant chunks.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:setLodEnabled(true)
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:isLodEnabled --------------------------------
--@api-stub: LLargeMapRenderer:isLodEnabled
-- Returns whether LOD rendering is currently enabled.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:isLodEnabled()  -- -> boolean
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:setLodThresholds ----------------------------
--@api-stub: LLargeMapRenderer:setLodThresholds
-- Sets the distance thresholds (in tile units) at which each LOD level activates.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:setLodThresholds(levels)
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:setTilesetColumns ---------------------------
--@api-stub: LLargeMapRenderer:setTilesetColumns
-- Sets the number of tile columns in the atlas texture used for UV calculation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:setTilesetColumns(cols)
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- ---- Stub: LLargeMapRenderer:getTilesetColumns ---------------------------
--@api-stub: LLargeMapRenderer:getTilesetColumns
-- Returns the number of tileset atlas columns.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lLargeMapRenderer_stub:getTilesetColumns()  -- -> integer
-- (replace lLargeMapRenderer_stub with your real LLargeMapRenderer instance above)

-- -----------------------------------------------------------------------------
-- LMapBlock methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMapBlock:setTile ---------------------------------------------
--@api-stub: LMapBlock:setTile
-- Sets the GID of a tile at (x, y) on the given layer (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:setTile(1, 0.0, 0.0, gid)
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- ---- Stub: LMapBlock:getTile ---------------------------------------------
--@api-stub: LMapBlock:getTile
-- Returns the GID of the tile at (x, y) on the given layer (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:getTile(1, 0.0, 0.0)  -- -> integer
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- ---- Stub: LMapBlock:setSide ---------------------------------------------
--@api-stub: LMapBlock:setSide
-- Sets the side connection ID for a segment on a given edge.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:setSide(edge_str, segment, side_id)
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- ---- Stub: LMapBlock:getSide ---------------------------------------------
--@api-stub: LMapBlock:getSide
-- Returns the side connection ID for a segment on a given edge.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:getSide(edge_str, segment)  -- -> integer
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- ---- Stub: LMapBlock:getWidth --------------------------------------------
--@api-stub: LMapBlock:getWidth
-- Returns the block width in tiles.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:getWidth()  -- -> integer
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- ---- Stub: LMapBlock:getHeight -------------------------------------------
--@api-stub: LMapBlock:getHeight
-- Returns the block height in tiles.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:getHeight()  -- -> integer
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- ---- Stub: LMapBlock:getDimensions ---------------------------------------
--@api-stub: LMapBlock:getDimensions
-- Returns the block dimensions as (width, height) in tiles.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:getDimensions()  -- -> integer, integer
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- ---- Stub: LMapBlock:getLayerCount ---------------------------------------
--@api-stub: LMapBlock:getLayerCount
-- Returns the number of layers in this block.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:getLayerCount()  -- -> integer
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- ---- Stub: LMapBlock:getSegmentSize --------------------------------------
--@api-stub: LMapBlock:getSegmentSize
-- Returns the segment size in tiles.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:getSegmentSize()  -- -> integer
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- ---- Stub: LMapBlock:getWidthInSegments ----------------------------------
--@api-stub: LMapBlock:getWidthInSegments
-- Returns the number of segments along the width.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:getWidthInSegments()  -- -> integer
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- ---- Stub: LMapBlock:getHeightInSegments ---------------------------------
--@api-stub: LMapBlock:getHeightInSegments
-- Returns the number of segments along the height.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:getHeightInSegments()  -- -> integer
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- ---- Stub: LMapBlock:setName ---------------------------------------------
--@api-stub: LMapBlock:setName
-- Sets the human-readable name of this block.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:setName("hero")
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- ---- Stub: LMapBlock:getName ---------------------------------------------
--@api-stub: LMapBlock:getName
-- Returns the name of this block.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:getName()  -- -> string
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- ---- Stub: LMapBlock:setWeight -------------------------------------------
--@api-stub: LMapBlock:setWeight
-- Sets the placement weight.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:setWeight(weight)
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- ---- Stub: LMapBlock:getWeight -------------------------------------------
--@api-stub: LMapBlock:getWeight
-- Returns the placement weight.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapBlock_stub:getWeight()  -- -> number
-- (replace lMapBlock_stub with your real LMapBlock instance above)

-- -----------------------------------------------------------------------------
-- LMapGen methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMapGen:generate ----------------------------------------------
--@api-stub: LMapGen:generate
-- Generates a TileMap using the group's blocks and an optional script index, seed, and layer name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapGen_stub:generate([script_idx], [seed], [layer_name])  -- -> TileMap
-- (replace lMapGen_stub with your real LMapGen instance above)

-- -----------------------------------------------------------------------------
-- LMapGroup methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMapGroup:addBlock --------------------------------------------
--@api-stub: LMapGroup:addBlock
-- Adds a block to this group.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapGroup_stub:addBlock(block_ud)
-- (replace lMapGroup_stub with your real LMapGroup instance above)

-- ---- Stub: LMapGroup:getBlockCount ---------------------------------------
--@api-stub: LMapGroup:getBlockCount
-- Returns the number of blocks in this group.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapGroup_stub:getBlockCount()  -- -> integer
-- (replace lMapGroup_stub with your real LMapGroup instance above)

-- ---- Stub: LMapGroup:removeBlock -----------------------------------------
--@api-stub: LMapGroup:removeBlock
-- Removes a block by 1-based index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapGroup_stub:removeBlock(1)
-- (replace lMapGroup_stub with your real LMapGroup instance above)

-- ---- Stub: LMapGroup:getName ---------------------------------------------
--@api-stub: LMapGroup:getName
-- Returns the name of this group.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapGroup_stub:getName()  -- -> string
-- (replace lMapGroup_stub with your real LMapGroup instance above)

-- ---- Stub: LMapGroup:addScript -------------------------------------------
--@api-stub: LMapGroup:addScript
-- Adds a MapScript to this group.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapGroup_stub:addScript(script_ud)
-- (replace lMapGroup_stub with your real LMapGroup instance above)

-- ---- Stub: LMapGroup:getScriptCount --------------------------------------
--@api-stub: LMapGroup:getScriptCount
-- Returns the number of scripts in this group.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapGroup_stub:getScriptCount()  -- -> integer
-- (replace lMapGroup_stub with your real LMapGroup instance above)

-- -----------------------------------------------------------------------------
-- LMapScript methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMapScript:getStepCount ---------------------------------------
--@api-stub: LMapScript:getStepCount
-- Returns the number of steps in this script.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapScript_stub:getStepCount()  -- -> integer
-- (replace lMapScript_stub with your real LMapScript instance above)

-- ---- Stub: LMapScript:addStep --------------------------------------------
--@api-stub: LMapScript:addStep
-- Appends a generation step from a step-definition table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMapScript_stub:addStep(step_def)
-- (replace lMapScript_stub with your real LMapScript instance above)

-- -----------------------------------------------------------------------------
-- LTileMap methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTileMap:addTileSet -------------------------------------------
--@api-stub: LTileMap:addTileSet
-- Adds a tileset to this map.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:addTileSet(ts_ud)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:getTileSetCount --------------------------------------
--@api-stub: LTileMap:getTileSetCount
-- Returns the number of tilesets attached to this map.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:getTileSetCount()  -- -> integer
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:getTileSet -------------------------------------------
--@api-stub: LTileMap:getTileSet
-- Returns a tileset by 1-based index, or nil if out of range.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:getTileSet(1)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:addLayer ---------------------------------------------
--@api-stub: LTileMap:addLayer
-- Adds a new empty layer and returns its 1-based index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:addLayer("hero", 64.0, 64.0)  -- -> integer
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:getLayerCount ----------------------------------------
--@api-stub: LTileMap:getLayerCount
-- Returns the number of layers.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:getLayerCount()  -- -> integer
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:getLayerName -----------------------------------------
--@api-stub: LTileMap:getLayerName
-- Returns the name of a layer by 1-based index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:getLayerName(1)  -- -> string?
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:setLayerVisible --------------------------------------
--@api-stub: LTileMap:setLayerVisible
-- Shows or hides a tile layer by its 1-based index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:setLayerVisible(1, true)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:getLayerVisible --------------------------------------
--@api-stub: LTileMap:getLayerVisible
-- Returns layer visibility.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:getLayerVisible(1)  -- -> boolean
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:setLayerColor ----------------------------------------
--@api-stub: LTileMap:setLayerColor
-- Sets the RGBA tint color for a layer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:setLayerColor(1, 1.0, 0.8, 0.2, 1.0)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:getLayerColor ----------------------------------------
--@api-stub: LTileMap:getLayerColor
-- Returns the RGBA tint color of a layer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:getLayerColor(1)  -- -> number, number, number, number
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:setLayerOffset ---------------------------------------
--@api-stub: LTileMap:setLayerOffset
-- Sets the pixel offset for a layer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:setLayerOffset(1, ox, oy)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:getLayerOffset ---------------------------------------
--@api-stub: LTileMap:getLayerOffset
-- Returns the pixel offset of a layer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:getLayerOffset(1)  -- -> number, number
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:setLayerParallax -------------------------------------
--@api-stub: LTileMap:setLayerParallax
-- Sets the parallax scrolling factor for a layer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:setLayerParallax(1, px, py)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:getLayerParallax -------------------------------------
--@api-stub: LTileMap:getLayerParallax
-- Returns the parallax factor of a layer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:getLayerParallax(1)  -- -> number, number
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:setTile ----------------------------------------------
--@api-stub: LTileMap:setTile
-- Sets the GID of a tile at (x, y) on the given layer (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:setTile(1, 0.0, 0.0, gid)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:getTile ----------------------------------------------
--@api-stub: LTileMap:getTile
-- Returns the GID at (x, y) on the given layer (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:getTile(1, 0.0, 0.0)  -- -> integer
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:clearTile --------------------------------------------
--@api-stub: LTileMap:clearTile
-- Clears a tile (sets GID to 0) at (x, y) on the given layer (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:clearTile(1, 0.0, 0.0)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:fill -------------------------------------------------
--@api-stub: LTileMap:fill
-- Fills an entire layer with the given GID (1-based layer).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:fill(1, gid)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:setViewport ------------------------------------------
--@api-stub: LTileMap:setViewport
-- Sets the viewport rectangle for rendering culling.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:setViewport(0.0, 0.0, 64.0, 64.0)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:getViewport ------------------------------------------
--@api-stub: LTileMap:getViewport
-- Returns the viewport as (x, y, w, h) or nil if not set.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:getViewport()  -- -> number, number, number, number
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:update -----------------------------------------------
--@api-stub: LTileMap:update
-- Advances tile animation timers by dt seconds.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:update(0.016)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:worldToTile ------------------------------------------
--@api-stub: LTileMap:worldToTile
-- Converts world pixel coordinates to tile coordinates.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:worldToTile(wx, wy)  -- -> integer, integer
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:tileToWorld ------------------------------------------
--@api-stub: LTileMap:tileToWorld
-- Converts tile coordinates to world pixel coordinates (1-based input).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:tileToWorld(tx, ty)  -- -> number, number
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:getTileWidth -----------------------------------------
--@api-stub: LTileMap:getTileWidth
-- Returns the tile width in pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:getTileWidth()  -- -> integer
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:getTileHeight ----------------------------------------
--@api-stub: LTileMap:getTileHeight
-- Returns the tile height in pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:getTileHeight()  -- -> integer
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:getTileDimensions ------------------------------------
--@api-stub: LTileMap:getTileDimensions
-- Returns tile dimensions as (width, height).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:getTileDimensions()  -- -> integer, integer
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:getChunkSize -----------------------------------------
--@api-stub: LTileMap:getChunkSize
-- Returns the chunk size used for spatial partitioning.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:getChunkSize()  -- -> integer
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:isSolid ----------------------------------------------
--@api-stub: LTileMap:isSolid
-- Returns true if the tile at (x, y) on layer is solid (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:isSolid(1, 0.0, 0.0)  -- -> boolean
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:applyAutoTile ----------------------------------------
--@api-stub: LTileMap:applyAutoTile
-- Applies 4-bit cardinal autotile rules to every tile on layer (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:applyAutoTile(1, type_name)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:applyAutoTileAt --------------------------------------
--@api-stub: LTileMap:applyAutoTileAt
-- Applies 4-bit cardinal autotile at a single cell and its 3x3 neighborhood (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:applyAutoTileAt(1, 0.0, 0.0, type_name)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:applyAutoTile8 ---------------------------------------
--@api-stub: LTileMap:applyAutoTile8
-- Applies 8-bit directional autotile rules to every tile on layer (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:applyAutoTile8(1, type_name)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:applyAutoTile8At -------------------------------------
--@api-stub: LTileMap:applyAutoTile8At
-- Applies 8-bit directional autotile at a single cell and its 3x3 neighborhood (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:applyAutoTile8At(1, 0.0, 0.0, type_name)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:rectOverlapsSolid ------------------------------------
--@api-stub: LTileMap:rectOverlapsSolid
-- Returns true if any solid tile overlaps the given world-space rectangle on layer (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:rectOverlapsSolid(1, 0.0, 0.0, 64.0, 64.0)  -- -> boolean
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:sweepRect --------------------------------------------
--@api-stub: LTileMap:sweepRect
-- Performs a swept AABB collision test against solid tiles on layer (1-based).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:sweepRect(1, 0.0, 0.0, 64.0, 64.0, dx, dy)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:getOrientation ---------------------------------------
--@api-stub: LTileMap:getOrientation
-- Returns the map orientation as a string ("topdown", "sideview", "isometric", or "hexagonal").
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:getOrientation()  -- -> string
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:setOrientation ---------------------------------------
--@api-stub: LTileMap:setOrientation
-- Sets the map orientation from a string ("topdown", "sideview", "isometric", or "hexagonal").
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:setOrientation(orientation)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:setTileTint ------------------------------------------
--@api-stub: LTileMap:setTileTint
-- Sets a per-tile RGBA tint override (1-based layer, x, y).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:setTileTint(1, 0.0, 0.0, 1.0, 0.8, 0.2, 1.0)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:render -----------------------------------------------
--@api-stub: LTileMap:render
-- Renders the tile map to the screen at the given offset.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:render([ox], [oy])
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:drawToImage ------------------------------------------
--@api-stub: LTileMap:drawToImage
-- Renders the tile map to a CPU ImageData using the given tile pixel size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:drawToImage(tile_size)  -- -> ImageData
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:toNavGrid --------------------------------------------
--@api-stub: LTileMap:toNavGrid
-- Converts the given layer into a 2D navigation grid.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:toNavGrid(1, gids_tbl)  -- -> table
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:onTileEnter ------------------------------------------
--@api-stub: LTileMap:onTileEnter
-- Registers a callback fired when any entity's tile GID matches `gid`.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:onTileEnter(gid, func)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:checkEntities ----------------------------------------
--@api-stub: LTileMap:checkEntities
-- Checks a list of entity positions against registered tile callbacks and fires matches.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:checkEntities(1, entities)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:onTileStep -------------------------------------------
--@api-stub: LTileMap:onTileStep
-- Register a callback for when an entity steps on a tile with the given GID.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:onTileStep(gid, func)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:onTileExit -------------------------------------------
--@api-stub: LTileMap:onTileExit
-- Register a callback for when an entity exits a tile with the given GID.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:onTileExit(gid, func)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:fireTileStep -----------------------------------------
--@api-stub: LTileMap:fireTileStep
-- Fire the tile step callback for the given GID (call each frame while entity is on tile).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:fireTileStep(gid, entity, tx, ty)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- ---- Stub: LTileMap:fireTileExit -----------------------------------------
--@api-stub: LTileMap:fireTileExit
-- Fire the tile exit callback for the given GID (call when entity leaves tile).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileMap_stub:fireTileExit(gid, entity, tx, ty)
-- (replace lTileMap_stub with your real LTileMap instance above)

-- -----------------------------------------------------------------------------
-- LTileSet methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTileSet:getFirstGid ------------------------------------------
--@api-stub: LTileSet:getFirstGid
-- Returns the first global ID assigned to this tileset.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:getFirstGid()  -- -> integer
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:getTileCount -----------------------------------------
--@api-stub: LTileSet:getTileCount
-- Returns the total number of tiles in this tileset.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:getTileCount()  -- -> integer
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:getColumns -------------------------------------------
--@api-stub: LTileSet:getColumns
-- Returns the number of tile columns in the atlas texture.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:getColumns()  -- -> integer
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:getTileWidth -----------------------------------------
--@api-stub: LTileSet:getTileWidth
-- Returns the width of a single tile in pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:getTileWidth()  -- -> integer
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:getTileHeight ----------------------------------------
--@api-stub: LTileSet:getTileHeight
-- Returns the height of a single tile in pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:getTileHeight()  -- -> integer
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:getTileDimensions ------------------------------------
--@api-stub: LTileSet:getTileDimensions
-- Returns the tile dimensions as (width, height).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:getTileDimensions()  -- -> integer, integer
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:getSpacing -------------------------------------------
--@api-stub: LTileSet:getSpacing
-- Returns the spacing in pixels between tiles in the atlas.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:getSpacing()  -- -> integer
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:getMargin --------------------------------------------
--@api-stub: LTileSet:getMargin
-- Returns the margin in pixels around the edges of the atlas.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:getMargin()  -- -> integer
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:getQuad ----------------------------------------------
--@api-stub: LTileSet:getQuad
-- Computes the atlas source rectangle for a 1-based local tile ID.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:getQuad(tile_id)  -- -> table
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:setAnimation -----------------------------------------
--@api-stub: LTileSet:setAnimation
-- Sets the animation frames for a 1-based local tile ID from a table of {tileid, duration}.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:setAnimation(tile_id, frames)
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:getAnimation -----------------------------------------
--@api-stub: LTileSet:getAnimation
-- Returns the animation frames for a 1-based local tile ID as a table of {tileid, duration}, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:getAnimation(tile_id)  -- -> table?
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:setSolid ---------------------------------------------
--@api-stub: LTileSet:setSolid
-- Sets whether a 1-based local tile ID is solid for collision purposes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:setSolid(tile_id, solid)
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:isSolid ----------------------------------------------
--@api-stub: LTileSet:isSolid
-- Returns whether a 1-based local tile ID is solid.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:isSolid(tile_id)  -- -> boolean
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:setAutoTileRule --------------------------------------
--@api-stub: LTileSet:setAutoTileRule
-- Registers a 4-bit cardinal autotile rule. tileId is 1-based.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:setAutoTileRule(type_name, bitmask, tile_id)
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:getAutoTileId ----------------------------------------
--@api-stub: LTileSet:getAutoTileId
-- Looks up the 1-based local tile ID for a 4-bit cardinal autotile bitmask, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:getAutoTileId(type_name, bitmask)  -- -> integer?
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:setAutoTileRule8 -------------------------------------
--@api-stub: LTileSet:setAutoTileRule8
-- Registers an 8-bit directional autotile rule. tileId is 1-based.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:setAutoTileRule8(type_name, bitmask, tile_id)
-- (replace lTileSet_stub with your real LTileSet instance above)

-- ---- Stub: LTileSet:getAutoTileId8 ---------------------------------------
--@api-stub: LTileSet:getAutoTileId8
-- Looks up the 1-based local tile ID for an 8-bit directional autotile bitmask, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTileSet_stub:getAutoTileId8(type_name, bitmask)  -- -> integer?
-- (replace lTileSet_stub with your real LTileSet instance above)
