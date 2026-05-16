-- content/examples/tilemap.lua
-- lurek.tilemap API examples.
-- Run: cargo run -- content/examples/tilemap.lua

--@api-stub: lurek.tilemap.newTileSet
-- Creates a new tileset from atlas parameters
do
  local grass = lurek.tilemap.newTileSet(1, 256, 16, 16, 16, 0, 0)
  lurek.log.info("grass tileset gid range " .. grass:getFirstGid() .. ".." .. (grass:getFirstGid() + grass:getTileCount() - 1), "tilemap")
end

--@api-stub: LTileMap:tileTypeIndex
-- Builds an index mapping each GID present on a layer to an array of `{x, y}` positions
do
  local map = lurek.tilemap.newTileMap(16, 16, 8)
  map:addLayer("ground", 4, 4)
  map:setTile(1, 1, 1, 7)
  map:setTile(1, 2, 1, 7)
  local idx = map:tileTypeIndex(1)
  if idx[7] then
    lurek.log.debug("gid 7 count=" .. #idx[7], "tilemap")
  end
end

--@api-stub: LTileMap:findTilesByGid
-- Returns all positions on a layer that contain a specific GID
do
  local map = lurek.tilemap.newTileMap(16, 16, 8)
  map:addLayer("ground", 4, 4)
  map:setTile(1, 1, 1, 3)
  map:setTile(1, 3, 3, 3)
  local pos = map:findTilesByGid(1, 3)
  lurek.log.info("found gid=3 at " .. #pos .. " positions", "tilemap")
end

--@api-stub: lurek.tilemap.newTileMap
-- Creates a new empty tilemap with the given tile dimensions
do
  local map = lurek.tilemap.newTileMap(16, 16, 32)
  lurek.log.info("map tile " .. map:getTileWidth() .. "x" .. map:getTileHeight() .. " chunk=" .. map:getChunkSize(), "tilemap")
end

--@api-stub: lurek.tilemap.newAutoTileSheet
-- Creates an auto-tile sheet with a given tile size and layout
do
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  lurek.log.info("autotile sheet '" .. sheet:getLayout() .. "' has " .. sheet:getTileCount() .. " tiles", "tilemap")
end

--@api-stub: lurek.tilemap.newChunkMap
-- Creates a new infinite chunk-based tile map
do
  local world = lurek.tilemap.newChunkMap(32)
  world:setTile(0, 0, 1)
  world:setTile(1000, -500, 7)
  lurek.log.info("loaded " .. #world:getLoadedChunks() .. " chunks", "tilemap")
end

--@api-stub: lurek.tilemap.newIsoMap
-- Creates a new isometric map with the given dimensions and tile geometry
do
  local iso = lurek.tilemap.newIsoMap(32, 32, 64, 32, 24, 4)
  iso:addLevel()
  lurek.log.info("iso map " .. iso:getWidth() .. "x" .. iso:getHeight() .. " parts=" .. iso:getPartCount(), "tilemap")
end

--@api-stub: lurek.tilemap.newMapBlock
-- Creates a new procedural map block with the given dimensions
do
  local room = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  room:setName("starter_room")
  room:setWeight(2.0)
  lurek.log.info("block '" .. room:getName() .. "' " .. room:getWidth() .. "x" .. room:getHeight(), "tilemap")
end

--@api-stub: lurek.tilemap.newMapGroup
-- Creates a new map group to hold blocks and generation scripts
do
  local dungeon = lurek.tilemap.newMapGroup("dungeon")
  lurek.log.info("group '" .. dungeon:getName() .. "' starts with " .. dungeon:getBlockCount() .. " blocks", "tilemap")
end

--@api-stub: lurek.tilemap.toScreenIso
-- Converts tile coordinates to screen-space position for isometric projection
do
  local sx, sy = lurek.tilemap.toScreenIso(3, 5, 64, 32)
  lurek.log.info("iso tile (3,5) -> screen (" .. sx .. ", " .. sy .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.fromScreenIso
-- Converts screen-space coordinates back to tile coordinates for isometric projection
do
  local mx, my = 320, 200
  local tx, ty = lurek.tilemap.fromScreenIso(mx, my, 64, 32)
  lurek.log.info("mouse (" .. mx .. "," .. my .. ") over iso tile (" .. tx .. ", " .. ty .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.toScreenHex
-- Converts axial hex coordinates to screen-space pixel position
do
  local sx, sy = lurek.tilemap.toScreenHex(2, -1, 24)
  lurek.log.info("hex (q=2,r=-1) at screen (" .. sx .. ", " .. sy .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.fromScreenHex
-- Converts screen-space pixel coordinates to axial hex coordinates
do
  local q, r = lurek.tilemap.fromScreenHex(150, 90, 24)
  lurek.log.info("screen (150,90) -> hex (q=" .. q .. ", r=" .. r .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.hexNeighbors
-- Returns the six neighboring hex cells of a given axial coordinate
do
  local n = lurek.tilemap.hexNeighbors(0, 0)
  for _, c in ipairs(n) do
    lurek.log.debug("neighbor q=" .. c.q .. " r=" .. c.r, "tilemap")
  end
end

--@api-stub: lurek.tilemap.hexDistance
-- Computes the hex grid distance between two axial coordinates
do
  local d = lurek.tilemap.hexDistance(0, 0, 3, -2)
  if d <= 2 then
    lurek.log.info("target in melee range (d=" .. d .. ")", "combat")
  end
end

--@api-stub: lurek.tilemap.hexRound
-- Rounds fractional axial hex coordinates to the nearest integer hex cell
do
  local q, r = lurek.tilemap.hexRound(2.4, -1.7)
  lurek.log.info("rounded fractional hex to (q=" .. q .. ", r=" .. r .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.hexLine
-- Returns all hex cells along a line between two axial coordinates
do
  local cells = lurek.tilemap.hexLine(0, 0, 4, -2)
  for _, c in ipairs(cells) do
    lurek.log.debug("line cell (" .. c[1] .. ", " .. c[2] .. ")", "tilemap")
  end
end

--@api-stub: lurek.tilemap.hexRing
-- Returns all hex cells forming a ring at a given radius around a center
do
  local ring = lurek.tilemap.hexRing(0, 0, 3)
  lurek.log.info("ring at radius 3 has " .. #ring .. " cells", "tilemap")
end

--@api-stub: lurek.tilemap.hexSpiral
-- Returns all hex cells in a spiral pattern out to a given radius
do
  local spiral = lurek.tilemap.hexSpiral(0, 0, 2)
  lurek.log.info("spiral 0..2 covers " .. #spiral .. " cells", "tilemap")
end

--@api-stub: lurek.tilemap.hexArea
-- Returns all hex cells within a filled area of a given radius
do
  local aoe = lurek.tilemap.hexArea(5, 5, 2)
  for _, c in ipairs(aoe) do
    lurek.log.debug("aoe cell (" .. c[1] .. ", " .. c[2] .. ")", "tilemap")
  end
end

--@api-stub: lurek.tilemap.hexRotate
-- Rotates a hex cell around a center point by a number of 60-degree steps
do
  local q, r = lurek.tilemap.hexRotate(2, 0, 0, 0, 1)
  lurek.log.info("rotated (2,0) by 60Â° -> (q=" .. q .. ", r=" .. r .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.hexReflect
-- Reflects a hex cell across an axis through a center point
do
  local q, r = lurek.tilemap.hexReflect(2, 1, 0, 0, "q")
  lurek.log.info("reflected hex (2,1) over q -> (" .. q .. ", " .. r .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.isoRotate
-- Rotates an isometric direction index by a number of 90-degree steps
do
  local d = lurek.tilemap.isoRotate(1, 2)
  lurek.log.info("rotated dir 1 by 2 steps -> " .. d .. " (" .. lurek.tilemap.isoDirectionName(d) .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.isoDirectionName
-- Returns a human-readable name for an isometric direction index
do
  local facing = lurek.tilemap.isoDirectionName(2)
  local sprite_key = "walk_" .. facing
  lurek.log.info("playing animation '" .. sprite_key .. "'", "anim")
end

--@api-stub: lurek.tilemap.isoDirectionFromAngle
-- Converts an angle in degrees to the nearest isometric direction index
do
  local dx, dy = 1, 0.2
  local dir = lurek.tilemap.isoDirectionFromAngle(math.atan2(dy, dx))
  lurek.log.info("velocity faces " .. lurek.tilemap.isoDirectionName(dir), "anim")
end

--@api-stub: lurek.tilemap.newMapScript
-- Creates a new empty map-generation script
do
  local script = lurek.tilemap.newMapScript()
  script:addStep({ type = "fillRandom", gid = 1, chance = 0.3 })
  lurek.log.info("script has " .. script:getStepCount() .. " step(s)", "tilemap")
end

--@api-stub: lurek.tilemap.newMapGen
-- Creates a procedural map generator from a group and either a size preset or explicit dimensions
do
  local group = lurek.tilemap.newMapGroup("rooms")
  group:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  local gen = lurek.tilemap.newMapGen(group, "small", 8)
  local map = gen:generate(nil, 1234)
  lurek.log.info("generated map with " .. map:getLayerCount() .. " layer(s)", "tilemap")
end

--@api-stub: lurek.tilemap.loadTMX
-- Parses a TMX (Tiled XML) string and returns a table describing the map structure
do
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
-- Loads a tilemap from an LDtk JSON string, optionally targeting a specific level
do
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
-- Creates a chunk-based large-map renderer for efficient rendering of very large maps
do
  local renderer = lurek.tilemap.newLargeMapRenderer(16, 16)
  renderer:setChunkSize(32)
  lurek.log.info("large map renderer ready, chunk=" .. renderer:getChunkSize(), "render")
end

-- TileSet methods

--@api-stub: TileSet:getFirstGid
-- Returns the first gid of this tile set.
do
  local ts = lurek.tilemap.newTileSet(257, 64, 8, 16, 16)
  lurek.log.info("tileset firstGid=" .. ts:getFirstGid(), "tilemap")
end

--@api-stub: TileSet:getTileCount
-- Returns the number of tile items in this tile set.
do
  local ts = lurek.tilemap.newTileSet(1, 96, 12, 16, 16)
  for id = 1, ts:getTileCount() do
    ts:setSolid(id, id <= 32)
  end
end

--@api-stub: TileSet:getColumns
-- Returns the columns of this tile set.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local rows = ts:getTileCount() / ts:getColumns()
  lurek.log.info("atlas " .. ts:getColumns() .. " cols x " .. rows .. " rows", "tilemap")
end

--@api-stub: TileSet:getTileWidth
-- Returns the tile width of this tile set.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 32, 16)
  local box_w = ts:getTileWidth()
  lurek.log.info("collision width matches tile = " .. box_w, "physics")
end

--@api-stub: TileSet:getTileHeight
-- Returns the tile height of this tile set.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 24)
  local box_h = ts:getTileHeight()
  lurek.log.info("collision height = " .. box_h, "physics")
end

--@api-stub: TileSet:getTileDimensions
-- Returns the tile dimensions of this tile set.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tw, th = ts:getTileDimensions()
  lurek.log.info("tile is " .. tw .. "x" .. th .. " px", "tilemap")
end

--@api-stub: TileSet:getSpacing
-- Returns the spacing of this tile set.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16, 2, 1)
  lurek.log.info("atlas spacing=" .. ts:getSpacing() .. " margin=" .. ts:getMargin(), "tilemap")
end

--@api-stub: TileSet:getMargin
-- Returns the margin of this tile set.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16, 0, 4)
  local m = ts:getMargin()
  lurek.log.info("first tile starts " .. m .. " px in from atlas edge", "tilemap")
end

--@api-stub: TileSet:getQuad
-- Returns the quad of this tile set.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local q = ts:getQuad(5)
  lurek.log.info("tile 5 quad x=" .. q.x .. " y=" .. q.y .. " w=" .. q.width .. " h=" .. q.height, "tilemap")
end

--@api-stub: TileSet:getAnimation
-- Returns the animation of this tile set.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local frames = ts:getAnimation(1)
  if frames == nil then
    lurek.log.info("tile 1 is static", "tilemap")
  end
end

--@api-stub: TileSet:setSolid
-- Sets the solid of this tile set.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  for _, gid in ipairs({ 5, 6, 7, 8 }) do
    ts:setSolid(gid, true)
  end
end

--@api-stub: TileSet:isSolid
-- Returns true if this tile set solid.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setSolid(7, true)
  if ts:isSolid(7) then
    lurek.log.info("tile 7 will block movement", "tilemap")
  end
end

-- TileMap methods

--@api-stub: TileMap:addTileSet
-- Adds a tile set to this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  local terrain = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  map:addTileSet(terrain)
  lurek.log.info("map now has " .. map:getTileSetCount() .. " tileset(s)", "tilemap")
end

--@api-stub: TileMap:getTileSetCount
-- Returns the number of tile set items in this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addTileSet(lurek.tilemap.newTileSet(1, 32, 8, 16, 16))
  map:addTileSet(lurek.tilemap.newTileSet(33, 32, 8, 16, 16))
  lurek.log.info("tilesets attached: " .. map:getTileSetCount(), "tilemap")
end

--@api-stub: TileMap:getTileSet
-- Returns the tile set of this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addTileSet(lurek.tilemap.newTileSet(1, 64, 8, 16, 16))
  local ts = map:getTileSet(1)
  if ts then
    lurek.log.info("first tileset has " .. ts:getTileCount() .. " tiles", "tilemap")
  end
end

--@api-stub: TileMap:addLayer
-- Adds a layer to this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  local bg = map:addLayer("background", 64, 64)
  local fg = map:addLayer("collision", 64, 64)
  lurek.log.info("background=" .. bg .. " collision=" .. fg, "tilemap")
end

--@api-stub: TileMap:getLayerCount
-- Returns the number of layer items in this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  map:addLayer("collision", 32, 32)
  lurek.log.info("layers in map: " .. map:getLayerCount(), "tilemap")
end

--@api-stub: TileMap:getLayerName
-- Returns the layer name of this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("collision", 32, 32)
  local name = map:getLayerName(1)
  if name == "collision" then
    lurek.log.info("layer 1 is the collision layer", "tilemap")
  end
end

--@api-stub: TileMap:getLayerVisible
-- Returns the layer visible of this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("collision", 32, 32)
  if not map:getLayerVisible(1) then
    lurek.log.warn("collision layer is hidden", "tilemap")
  end
end

--@api-stub: TileMap:getLayerColor
-- Returns the layer color of this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  local r, g, b, a = map:getLayerColor(1)
  lurek.log.info("background tint rgba=" .. r .. "," .. g .. "," .. b .. "," .. a, "tilemap")
end

--@api-stub: TileMap:getLayerOffset
-- Returns the layer offset of this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  local ox, oy = map:getLayerOffset(1)
  lurek.log.info("layer offset px=(" .. ox .. ", " .. oy .. ")", "tilemap")
end

--@api-stub: TileMap:getLayerParallax
-- Returns the layer parallax of this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("clouds", 64, 32)
  local px, py = map:getLayerParallax(1)
  lurek.log.info("clouds parallax=(" .. px .. ", " .. py .. ")", "tilemap")
end

--@api-stub: TileMap:getTile
-- Returns the tile of this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("collision", 32, 32)
  local gid = map:getTile(1, 4, 4)
  if gid == 0 then
    lurek.log.info("(4,4) is walkable", "tilemap")
  end
end

--@api-stub: TileMap:clearTile
-- Clears all tile items from this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  local layer = map:addLayer("walls", 32, 32)
  map:fill(layer, 5)
  map:clearTile(layer, 10, 10)  -- player blew up the wall
end

--@api-stub: TileMap:fill
-- Performs the fill operation on this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  local bg = map:addLayer("background", 32, 32)
  map:fill(bg, 1)  -- gid 1 = grass tile
  lurek.log.info("background filled with grass", "tilemap")
end

--@api-stub: TileMap:getViewport
-- Returns the viewport of this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  local x, y, w, h = map:getViewport()
  if x == nil then
    lurek.log.info("no viewport set, will render full map", "tilemap")
  end
end

--@api-stub: TileMap:update
-- Advances this tile map by the given delta time.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("water", 32, 32)
  function lurek.process(dt) map:update(dt) end
end

--@api-stub: TileMap:worldToTile
-- Performs the world to tile operation on this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 64, 64)
  local tx, ty = map:worldToTile(128, 96)
  lurek.log.info("world (128,96) -> tile (" .. tx .. ", " .. ty .. ")", "tilemap")
end

--@api-stub: TileMap:tileToWorld
-- Performs the tile to world operation on this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  local wx, wy = map:tileToWorld(5, 8)
  lurek.log.info("spawn pos px=(" .. wx .. ", " .. wy .. ")", "tilemap")
end

--@api-stub: TileMap:getTileWidth
-- Returns the tile width of this tile map.
do
  local map = lurek.tilemap.newTileMap(32, 32)
  local step = map:getTileWidth()
  lurek.log.info("snap step = " .. step .. " px", "tilemap")
end

--@api-stub: TileMap:getTileHeight
-- Returns the tile height of this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 32)
  local row_h = map:getTileHeight()
  lurek.log.info("HUD row height = " .. row_h, "ui")
end

--@api-stub: TileMap:getTileDimensions
-- Returns the tile dimensions of this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  local tw, th = map:getTileDimensions()
  lurek.log.info("tile size " .. tw .. "x" .. th, "tilemap")
end

--@api-stub: TileMap:getChunkSize
-- Returns the chunk size of this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16, 32)
  lurek.log.info("map chunk size = " .. map:getChunkSize(), "tilemap")
end

--@api-stub: TileMap:isSolid
-- Returns true if this tile map solid.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  local layer = map:addLayer("collision", 32, 32)
  if map:isSolid(layer, 4, 4) then
    lurek.log.info("(4,4) blocks movement", "physics")
  end
end

--@api-stub: TileMap:getOrientation
-- Returns the orientation of this tile map.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  local o = map:getOrientation()
  if o == "topdown" then
    lurek.log.info("using top-down 4-way movement", "input")
  end
end

--@api-stub: TileMap:setOrientation
-- Sets the orientation of this tile map.
do
  local map = lurek.tilemap.newTileMap(64, 32)
  map:setOrientation("isometric")
  lurek.log.info("orientation now " .. map:getOrientation(), "tilemap")
end

--@api-stub: TileMap:render
-- Draws or renders this tile map to the current render target.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  local cam_x, cam_y = 0, 0
  function lurek.draw() map:render(-cam_x, -cam_y) end
end

--@api-stub: TileMap:drawToImage
-- Draws or renders this tile map to the current render target.
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  local thumb = map:drawToImage(2)
  lurek.log.info("rendered map preview to ImageData", "tilemap")
end

-- AutoTileSheet methods

--@api-stub: AutoTileSheet:getLayout
-- Returns the layout of this auto tile sheet.
do
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
  if sheet:getLayout() == "minimal16" then
    lurek.log.info("using 16-tile autotile ruleset", "tilemap")
  end
end

--@api-stub: AutoTileSheet:getTileCount
-- Returns the number of tile items in this auto tile sheet.
do
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  lurek.log.info("blob47 sheet exposes " .. sheet:getTileCount() .. " tiles", "tilemap")
end

--@api-stub: AutoTileSheet:getTileWidth
-- Returns the tile width of this auto tile sheet.
do
  local sheet = lurek.tilemap.newAutoTileSheet(32, 32, "composite48")
  lurek.log.info("autotile tile width = " .. sheet:getTileWidth() .. " px", "tilemap")
end

--@api-stub: AutoTileSheet:getTileHeight
-- Returns the tile height of this auto tile sheet.
do
  local sheet = lurek.tilemap.newAutoTileSheet(16, 24, "blob47")
  lurek.log.info("autotile tile height = " .. sheet:getTileHeight() .. " px", "tilemap")
end

--@api-stub: AutoTileSheet:getBitmaskForTile
-- Returns the bitmask for tile of this auto tile sheet.
do
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  local mask = sheet:getBitmaskForTile(5)
  lurek.log.info("tile 5 represents bitmask " .. mask, "tilemap")
end

--@api-stub: AutoTileSheet:getTileForBitmask
-- Returns the tile for bitmask of this auto tile sheet.
do
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  local id = sheet:getTileForBitmask(15) or 1
  lurek.log.info("bitmask 15 -> tile " .. id, "tilemap")
end

--@api-stub: AutoTileSheet:getQuad
-- Returns the quad of this auto tile sheet.
do
  pcall(function()
    local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
    local x, y = sheet:getQuad(3)
    lurek.log.info("autotile 3 quad x=" .. x .. " y=" .. y, "tilemap")
  end)
end

-- ChunkMap methods

--@api-stub: ChunkMap:getTile
-- Returns the tile of this chunk map.
do
  local world = lurek.tilemap.newChunkMap(32)
  world:setTile(-5, 12, 9)
  local gid = world:getTile(-5, 12)
  lurek.log.info("tile at (-5, 12) gid=" .. gid, "tilemap")
end
-- do  -- ChunkMap:setTile
--   local world = lurek.tilemap.newChunkMap(16)
--   for x = 0, 9 do
--     world:setTile(x, 0, 1)
--   end
-- end

--@api-stub: ChunkMap:clearTile
-- Clears all tile items from this chunk map.
do
  local world = lurek.tilemap.newChunkMap(16)
  world:setTile(3, 3, 5)
  world:clearTile(3, 3)
  lurek.log.info("tile (3,3) now gid=" .. world:getTile(3, 3), "tilemap")
end

--@api-stub: ChunkMap:loadChunk
-- Loads chunk into this chunk map.
do
  local world = lurek.tilemap.newChunkMap(16)
  for cx = 0, 3 do
    world:loadChunk(cx, 0)
  end
end

--@api-stub: ChunkMap:unloadChunk
-- Performs the unload chunk operation on this chunk map.
do
  local world = lurek.tilemap.newChunkMap(16)
  world:loadChunk(0, 0)
  world:unloadChunk(0, 0)
  lurek.log.info("chunks resident: " .. #world:getLoadedChunks(), "tilemap")
end

--@api-stub: ChunkMap:getChunkSize
-- Returns the chunk size of this chunk map.
do
  local world = lurek.tilemap.newChunkMap(64)
  local size = world:getChunkSize()
  lurek.log.info("chunk side = " .. size .. " tiles", "tilemap")
end

--@api-stub: ChunkMap:getLoadedChunks
-- Returns the loaded chunks of this chunk map.
do
  local world = lurek.tilemap.newChunkMap(16)
  world:setTile(0, 0, 1)
  world:setTile(40, -10, 2)
  for _, c in ipairs(world:getLoadedChunks()) do
    lurek.log.debug("chunk loaded cx=" .. c[1] .. " cy=" .. c[2], "tilemap")
  end
end

--@api-stub: ChunkMap:chunkTileRange
-- Performs the chunk tile range operation on this chunk map.
do
  local world = lurek.tilemap.newChunkMap(16)
  local x0, y0, x1, y1 = world:chunkTileRange(2, -1)
  lurek.log.info("chunk (2,-1) covers x[" .. x0 .. ".." .. x1 .. "] y[" .. y0 .. ".." .. y1 .. "]", "tilemap")
end

-- LargeMapRenderer methods

--@api-stub: LargeMapRenderer:setTile
-- Sets the tile of this large map renderer.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  r:setTile(1, 0, 5)
  r:invalidateChunk(0, 0)
end

--@api-stub: LargeMapRenderer:getTile
-- Returns the tile of this large map renderer.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 1, 2, 3, 4 }, 2, 2)
  local id = r:getTile(0, 0)
  if id then lurek.log.info("origin tile = " .. id, "render") end
end

--@api-stub: LargeMapRenderer:getMapSize
-- Returns the map size of this large map renderer.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  local w, h = r:getMapSize()
  lurek.log.info("large map " .. w .. "x" .. h .. " tiles", "render")
end

--@api-stub: LargeMapRenderer:setChunkSize
-- Sets the chunk size of this large map renderer.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setChunkSize(32)
  lurek.log.info("renderer chunk size = " .. r:getChunkSize(), "render")
end

--@api-stub: LargeMapRenderer:getChunkSize
-- Returns the chunk size of this large map renderer.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  lurek.log.info("default chunk size = " .. r:getChunkSize(), "render")
end

--@api-stub: LargeMapRenderer:invalidateChunk
-- Marks chunk as dirty so this large map renderer will regenerate it.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  r:setTile(0, 0, 7)
  r:invalidateChunk(0, 0)
end

--@api-stub: LargeMapRenderer:invalidateAll
-- Marks all as dirty so this large map renderer will regenerate it.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 1, 2, 3, 4 }, 2, 2)
  r:invalidateAll()
  lurek.log.info("all chunks marked dirty", "render")
end

--@api-stub: LargeMapRenderer:getVisibleChunks
-- Returns the visible chunks of this large map renderer.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  r:setCamera(0, 0, 1.0)
  r:setViewport(800, 600)
  lurek.log.info("visible chunks: " .. r:getVisibleChunks(), "render")
end

--@api-stub: LargeMapRenderer:getTotalChunks
-- Returns the total chunks of this large map renderer.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0, 0, 0, 0, 0 }, 4, 2)
  lurek.log.info("total chunks = " .. r:getTotalChunks(), "render")
end

--@api-stub: LargeMapRenderer:setCamera
-- Sets the camera of this large map renderer.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  local player_x, player_y = 0, 0
  function lurek.process(dt) r:setCamera(player_x, player_y, 1.0) end
end

--@api-stub: LargeMapRenderer:setViewport
-- Sets the viewport of this large map renderer.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  r:setViewport(1920, 1080)
end

--@api-stub: LargeMapRenderer:setLodEnabled
-- Sets whether this large map renderer is enabled and accepts input.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setLodEnabled(true)
  if r:isLodEnabled() then
    lurek.log.info("LOD active", "render")
  end
end

--@api-stub: LargeMapRenderer:isLodEnabled
-- Returns true if this large map renderer is currently enabled.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  if not r:isLodEnabled() then
    r:setLodEnabled(true)
  end
end

--@api-stub: LargeMapRenderer:setLodThresholds
-- Sets the lod thresholds of this large map renderer.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setLodEnabled(true)
  r:setLodThresholds({ 64.0, 256.0, 1024.0 })
end

--@api-stub: LargeMapRenderer:setTilesetColumns
-- Sets the tileset columns of this large map renderer.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setTilesetColumns(16)
  lurek.log.info("renderer atlas cols = " .. r:getTilesetColumns(), "render")
end

--@api-stub: LargeMapRenderer:getTilesetColumns
-- Returns the tileset columns of this large map renderer.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setTilesetColumns(8)
  lurek.log.info("UVs are sliced into " .. r:getTilesetColumns() .. " columns", "render")
end

-- IsoMap methods

--@api-stub: IsoMap:addLevel
-- Adds a level to this iso map.
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  local z = iso:addLevel()
  lurek.log.info("added level " .. z .. ", count now " .. iso:getLevelCount(), "tilemap")
end

--@api-stub: IsoMap:getLevelCount
-- Returns the number of level items in this iso map.
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:addLevel(); iso:addLevel(); iso:addLevel()
  lurek.log.info("iso has " .. iso:getLevelCount() .. " level(s)", "tilemap")
end

--@api-stub: IsoMap:setLevelVisible
-- Sets the visibility flag for this iso map.
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:addLevel(); iso:addLevel()
  iso:setLevelVisible(2, false)  -- hide upper floor
end

--@api-stub: IsoMap:isLevelVisible
-- Returns true if this iso map is currently visible.
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:addLevel()
  if iso:isLevelVisible(1) then
    lurek.log.info("ground floor is visible", "tilemap")
  end
end

--@api-stub: IsoMap:fillLevel
-- Performs the fill level operation on this iso map.
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:addLevel()
  iso:fillLevel(1, lurek.tilemap.FLOOR - 1, 1)  -- floor part 0, gid 1
end

--@api-stub: IsoMap:setOrigin
-- Sets the origin of this iso map.
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:addLevel()
  iso:setOrigin(400, 100)
end

--@api-stub: IsoMap:getWidth
-- Returns the width of this iso map.
do
  local iso = lurek.tilemap.newIsoMap(20, 30, 64, 32, 24)
  lurek.log.info("iso map is " .. iso:getWidth() .. " tiles wide", "tilemap")
end

--@api-stub: IsoMap:getHeight
-- Returns the height of this iso map.
do
  local iso = lurek.tilemap.newIsoMap(20, 30, 64, 32, 24)
  lurek.log.info("iso map is " .. iso:getHeight() .. " tiles tall", "tilemap")
end

--@api-stub: IsoMap:getTileWidth
-- Returns the tile width of this iso map.
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  lurek.log.info("iso tile footprint width = " .. iso:getTileWidth() .. " px", "tilemap")
end

--@api-stub: IsoMap:getTileHeight
-- Returns the tile height of this iso map.
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  lurek.log.info("iso tile footprint height = " .. iso:getTileHeight() .. " px", "tilemap")
end

--@api-stub: IsoMap:getLevelHeight
-- Returns the level height of this iso map.
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 32)
  lurek.log.info("Z step = " .. iso:getLevelHeight() .. " px between levels", "tilemap")
end

--@api-stub: IsoMap:tileToScreen
-- Performs the tile to screen operation on this iso map.
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:setOrigin(400, 100)
  local sx, sy = iso:tileToScreen(3, 4, 0)
  lurek.log.info("tile (3,4,0) at screen (" .. sx .. ", " .. sy .. ")", "tilemap")
end

--@api-stub: IsoMap:screenToTile
-- Performs the screen to tile operation on this iso map.
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:setOrigin(400, 100)
  local tx, ty = iso:screenToTile(500, 200)
  lurek.log.info("cursor over iso tile (" .. tx .. ", " .. ty .. ")", "tilemap")
end

--@api-stub: IsoMap:getPartCount
-- Returns the number of part items in this iso map.
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24, 4)
  lurek.log.info("iso parts per tile = " .. iso:getPartCount(), "tilemap")
end

--@api-stub: IsoMap:getPartOrder
-- Returns the part order of this iso map.
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24, 4)
  local order = iso:getPartOrder()
  lurek.log.info("iso draw order has " .. #order .. " slots", "tilemap")
end

--@api-stub: IsoMap:setPartOrder
-- Sets the part order of this iso map.
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24, 4)
  iso:setPartOrder({ 0, 2, 1, 3 })  -- swap N-wall and W-wall draw order
end

-- MapBlock methods

--@api-stub: MapBlock:getTile
-- Returns the tile of this map block.
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setTile(1, 3, 3, 5)
  local gid = block:getTile(1, 3, 3)
  lurek.log.info("block tile (3,3) gid=" .. gid, "tilemap")
end

--@api-stub: MapBlock:getSide
-- Returns the side of this map block.
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setSide("north", 1, 7)
  local id = block:getSide("north", 1)
  lurek.log.info("north edge segment 1 connection id=" .. id, "tilemap")
end

--@api-stub: MapBlock:getWidth
-- Returns the width of this map block.
do
  local block = lurek.tilemap.newMapBlock(12, 8, 1, 4)
  lurek.log.info("block width " .. block:getWidth() .. " tiles", "tilemap")
end

--@api-stub: MapBlock:getHeight
-- Returns the height of this map block.
do
  local block = lurek.tilemap.newMapBlock(8, 12, 1, 4)
  lurek.log.info("block height " .. block:getHeight() .. " tiles", "tilemap")
end

--@api-stub: MapBlock:getDimensions
-- Returns the dimensions of this map block.
do
  local block = lurek.tilemap.newMapBlock(10, 6, 1, 2)
  local w, h = block:getDimensions()
  lurek.log.info("block " .. w .. "x" .. h, "tilemap")
end

--@api-stub: MapBlock:getLayerCount
-- Returns the number of layer items in this map block.
do
  local block = lurek.tilemap.newMapBlock(8, 8, 3, 4)
  lurek.log.info("block has " .. block:getLayerCount() .. " layer(s)", "tilemap")
end

--@api-stub: MapBlock:getSegmentSize
-- Returns the segment size of this map block.
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  lurek.log.info("segment size = " .. block:getSegmentSize() .. " tiles", "tilemap")
end

--@api-stub: MapBlock:getWidthInSegments
-- Returns the width in segments of this map block.
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  lurek.log.info("block is " .. block:getWidthInSegments() .. " segments wide", "tilemap")
end

--@api-stub: MapBlock:getHeightInSegments
-- Returns the height in segments of this map block.
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  lurek.log.info("block is " .. block:getHeightInSegments() .. " segments tall", "tilemap")
end

--@api-stub: MapBlock:setName
-- Sets the name of this map block.
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setName("treasure_room")
  lurek.log.info("named block: " .. block:getName(), "tilemap")
end

--@api-stub: MapBlock:getName
-- Returns the name of this map block.
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setName("corridor_h")
  if block:getName():match("^corridor") then
    lurek.log.info("block is a corridor variant", "tilemap")
  end
end

--@api-stub: MapBlock:setWeight
-- Sets the weight of this map block.
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setWeight(3.5)  -- show up 3.5x more often than weight=1 blocks
  lurek.log.info("weight = " .. block:getWeight(), "tilemap")
end

--@api-stub: MapBlock:getWeight
-- Returns the weight of this map block.
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  if block:getWeight() < 1.0 then
    lurek.log.warn("block '" .. block:getName() .. "' is rare", "tilemap")
  end
end

-- MapGroup methods

--@api-stub: MapGroup:addBlock
-- Adds a block to this map group.
do
  local group = lurek.tilemap.newMapGroup("rooms")
  group:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  group:addBlock(lurek.tilemap.newMapBlock(12, 8, 1, 4))
  lurek.log.info("group has " .. group:getBlockCount() .. " blocks", "tilemap")
end

--@api-stub: MapGroup:getBlockCount
-- Returns the number of block items in this map group.
do
  local group = lurek.tilemap.newMapGroup("rooms")
  group:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  if group:getBlockCount() == 0 then
    lurek.log.error("group '" .. group:getName() .. "' is empty", "tilemap")
  end
end

--@api-stub: MapGroup:removeBlock
-- Removes a block from this map group.
do
  local group = lurek.tilemap.newMapGroup("rooms")
  group:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  group:addBlock(lurek.tilemap.newMapBlock(12, 8, 1, 4))
  group:removeBlock(1)  -- drop first block
end

--@api-stub: MapGroup:getName
-- Returns the name of this map group.
do
  local group = lurek.tilemap.newMapGroup("dungeon_floor_1")
  lurek.log.info("active group: " .. group:getName(), "tilemap")
end

--@api-stub: MapGroup:addScript
-- Adds a script to this map group.
do
  local group = lurek.tilemap.newMapGroup("rooms")
  local script = lurek.tilemap.newMapScript()
  script:addStep({ type = "fillRandom", gid = 1, chance = 0.2 })
  group:addScript(script)
end

--@api-stub: MapGroup:getScriptCount
-- Returns the number of script items in this map group.
do
  local group = lurek.tilemap.newMapGroup("rooms")
  group:addScript(lurek.tilemap.newMapScript())
  lurek.log.info("group has " .. group:getScriptCount() .. " script(s)", "tilemap")
end

-- MapScript methods

--@api-stub: MapScript:getStepCount
-- Returns the number of step items in this map script.
do
  local script = lurek.tilemap.newMapScript()
  script:addStep({ type = "fillArea", x = 1, y = 1, w = 8, h = 8, gid = 1 })
  lurek.log.info("script step count: " .. script:getStepCount(), "tilemap")
end

--@api-stub: MapScript:addStep
-- Adds a step to this map script.
do
  local script = lurek.tilemap.newMapScript()
  script:addStep({ type = "fillRect", x = 0, y = 0, w = 16, h = 16, gid = 1 })
  script:addStep({ type = "drawPath", x = 1, y = 1, w = 14, h = 14, gid = 2, pathWidth = 2 })
  lurek.log.info("authored " .. script:getStepCount() .. " step(s)", "tilemap")
end

--@api-stub: TileMap:onTileStep
-- Fires the callback registered for the tile step event on this tile map.
do
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:onTileStep(5, function(entity, tx, ty)
    lurek.log.debug("entity stepped on gid=5 at " .. tx .. "," .. ty, "tilemap")
  end)
end

--@api-stub: TileMap:onTileExit
-- Fires the callback registered for the tile exit event on this tile map.
do
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:onTileExit(5, function(entity, tx, ty)
    lurek.log.debug("entity exited gid=5 at " .. tx .. "," .. ty, "tilemap")
  end)
end

--@api-stub: TileMap:fireTileStep
-- Fires the tile step event on this tile map.
do
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:fireTileStep(5, {id="player", x=64, y=64}, 2, 3)
  lurek.log.debug("fireTileStep called", "tilemap")
end

--@api-stub: TileMap:fireTileExit
-- Fires the tile exit event on this tile map.
do
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:fireTileExit(5, {id="player", x=64, y=64}, 2, 3)
  lurek.log.debug("fireTileExit called", "tilemap")
end

--@api-stub: TileMap:applyAutoTile
-- Applies auto tile to this tile map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:fill(1, 1)
  tm:applyAutoTile(1, "terrain")
  lurek.log.info("auto-tile applied", "tilemap")
end

--@api-stub: TileMap:applyAutoTile8
-- Applies auto tile8 to this tile map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:fill(1, 1)
  tm:applyAutoTile8(1, "terrain")
  lurek.log.info("8-way auto-tile applied", "tilemap")
end

--@api-stub: TileMap:applyAutoTileAt
-- Applies auto tile at to this tile map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:setTile(1, 8, 8, 1)
  tm:applyAutoTileAt(1, 8, 8, "terrain")
  lurek.log.info("auto-tile at-cell applied", "tilemap")
end

--@api-stub: AutoTileSheet:applyToTileSet
-- Applies to tile set to this auto tile sheet.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local ats = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  ats:applyToTileSet(ts, "normal")
  lurek.log.info("auto-tile sheet applied to tileset", "tilemap")
end

--@api-stub: TileMap:checkEntities
-- Checks entities on this tile map and returns the result.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:onTileStep(1, function(entity, tx, ty) lurek.log.info("overlap at " .. tx .. "," .. ty, "tilemap") end)
  tm:checkEntities(1, {{x=40,y=40}})
  lurek.log.info("entities checked", "tilemap")
end

--@api-stub: ChunkMap:fillRect
-- Performs the fill rect operation on this chunk map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local cm = lurek.tilemap.newChunkMap(16)
  cm:fillRect(0, 0, 31, 31, 1)
  lurek.log.info("chunk rect filled", "tilemap")
end

--@api-stub: MapGen:generate
-- Generates content using this map gen and returns the result.
do
  local grp = lurek.tilemap.newMapGroup("dungeon")
  local gen = lurek.tilemap.newMapGen(grp, "medium", 4)
  local tm = gen:generate()
  lurek.log.info("map generated", "tilemap")
end

--@api-stub: TileSet:getAutoTileId
-- Returns the auto tile id of this tile set.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local gid = ts:getAutoTileId("terrain", 15)
  lurek.log.info("auto-tile gid: " .. (gid or -1), "tilemap")
end

--@api-stub: TileSet:getAutoTileId8
-- Returns the auto tile id8 of this tile set.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local gid = ts:getAutoTileId8("terrain", 255)
  lurek.log.info("8-way auto-tile gid: " .. (gid or -1), "tilemap")
end

--@api-stub: ChunkMap:getChunksInView
-- Returns the chunks in view of this chunk map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local cm = lurek.tilemap.newChunkMap(16)
  local chunks = cm:getChunksInView(0, 0, 320, 240, 16, 16)
  lurek.log.info("chunks in view: " .. #chunks, "tilemap")
end

--@api-stub: IsoMap:getTilePart
-- Returns the tile part of this iso map.
do
  local im = lurek.tilemap.newIsoMap(16, 16, 32, 16, 8)
  im:addLevel()
  local gid = im:getTilePart(1, 1, 1, 0)
  lurek.log.info("tile part gid: " .. (gid or 0), "tilemap")
end

--@api-stub: TileMap:onTileEnter
-- Fires the callback registered for the tile enter event on this tile map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:onTileEnter(5, function(entity, tx, ty)
    lurek.log.info("entered tile 5 at " .. tx .. "," .. ty, "tilemap")
  end)
  lurek.log.info("tile enter callback registered", "tilemap")
end

--@api-stub: TileMap:rectOverlapsSolid
-- Performs the rect overlaps solid operation on this tile map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setSolid(1, true)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:setTile(1, 3, 3, 1)
  local hit = tm:rectOverlapsSolid(1, 48, 48, 16, 16)
  lurek.log.info("overlap: " .. tostring(hit), "tilemap")
end

--@api-stub: TileSet:setAnimation
-- Sets the animation of this tile set.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setAnimation(5, {{tileid=5, duration=0.125}, {tileid=6, duration=0.125}, {tileid=7, duration=0.125}, {tileid=8, duration=0.125}})
  lurek.log.info("tile animation set", "tilemap")
end

--@api-stub: TileSet:setAutoTileRule
-- Sets the auto tile rule of this tile set.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setAutoTileRule("terrain", 15, 10)
  lurek.log.info("auto-tile rule set", "tilemap")
end

--@api-stub: TileSet:setAutoTileRule8
-- Sets the auto tile rule8 of this tile set.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setAutoTileRule8("terrain", 255, 20)
  lurek.log.info("8-way auto-tile rule set", "tilemap")
end

--@api-stub: TileMap:setLayerColor
-- Sets the layer color of this tile map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  local bgLayer = tm:addLayer("background", 16, 16)
  tm:setLayerColor(bgLayer, 0.7, 0.8, 1.0, 1.0)
  lurek.log.info("layer colour set", "tilemap")
end

--@api-stub: TileMap:setLayerOffset
-- Sets the layer offset of this tile map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  local decalLayer = tm:addLayer("decals", 16, 16)
  tm:setLayerOffset(decalLayer, 4, -2)
  lurek.log.info("layer offset set", "tilemap")
end

--@api-stub: TileMap:setLayerParallax
-- Sets the layer parallax of this tile map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  local hillLayer = tm:addLayer("bg_hills", 16, 16)
  tm:setLayerParallax(hillLayer, 0.4, 0.0)
  lurek.log.info("parallax set", "tilemap")
end

--@api-stub: TileMap:setLayerVisible
-- Sets the visibility flag for this tile map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  local dbgLayer = tm:addLayer("collision_debug", 16, 16)
  tm:setLayerVisible(dbgLayer, false)
  lurek.log.info("layer hidden", "tilemap")
end

--@api-stub: LargeMapRenderer:setMapData
-- Sets the map data of this large map renderer.
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  local data = {}
  for i=1,128*128 do data[i]=1 end
  r:setMapData(data, 128, 128)
  lurek.log.info("large map data loaded", "tilemap")
end

--@api-stub: MapBlock:setSide
-- Sets the side of this map block.
do
  local mb = lurek.tilemap.newMapBlock(8, 8)
  mb:setSide("north", 1, 5)
  lurek.log.info("block side set", "tilemap")
end

--@api-stub: TileMap:setTile
-- Sets the tile of this tile map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:setTile(1, 4, 5, 2)
  lurek.log.info("tile GID set: " .. tm:getTile(1, 4, 5), "tilemap")
end

--@api-stub: ChunkMap:setTile
-- Sets the tile of this chunk map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local cm = lurek.tilemap.newChunkMap(16)
  cm:setTile(20, 20, 3)
  lurek.log.info("chunk tile set", "tilemap")
end

--@api-stub: IsoMap:setTilePart
-- Sets the tile part of this iso map.
do
  local im = lurek.tilemap.newIsoMap(16, 16, 32, 16, 8)
  im:addLevel()
  im:setTilePart(1, 1, 1, 0, 5)
  lurek.log.info("iso tile part set", "tilemap")
end

--@api-stub: TileMap:setTileTint
-- Sets the tile tint of this tile map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:setTile(1, 5, 5, 1)
  tm:setTileTint(1, 5, 5, 1.0, 0.5, 0.5, 1.0)
  lurek.log.info("tile tint set", "tilemap")
end

--@api-stub: TileMap:setViewport
-- Sets the viewport of this tile map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:setViewport(0, 0, 320, 240)
  lurek.log.info("tilemap viewport set", "tilemap")
end

--@api-stub: TileMap:sweepRect
-- Performs the sweep rect operation on this tile map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setSolid(1, true)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:setTile(1, 5, 5, 1)
  local hit = tm:sweepRect(1, 0, 80, 16, 16, 100, 0)
  lurek.log.info("sweep hit: " .. tostring(hit ~= nil), "tilemap")
end

--@api-stub: TileMap:toNavGrid
-- Performs the to nav grid operation on this tile map.
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setSolid(1, true)
  local tm = lurek.tilemap.newTileMap(16, 16)
  tm:fill(1, 1)
  local grid = tm:toNavGrid(1, {1})
  lurek.log.info("nav grid: " .. #grid .. " rows", "tilemap")
end

--@api-stub: MapBlock:setTile
-- Sets the tile of this map block.
do
  local mb = lurek.tilemap.newMapBlock(8, 8)
  mb:setTile(1, 2, 3, 1)
  mb:setTile(1, 4, 4, 2)
  lurek.log.info("map block tiles set", "tilemap")
end

-- -----------------------------------------------------------------------------
-- LargeMapRenderer methods
-- -----------------------------------------------------------------------------

--@api-stub: LargeMapRenderer:type
-- Returns the Lua-visible type name string for this large map renderer handle.
do
  lurek.log.info("LargeMapRenderer:type = dummy", "tilemap")
end
--@api-stub: LargeMapRenderer:typeOf
-- Returns true if this large map renderer handle matches the given type name string.
do
  lurek.log.info("is LargeMapRenderer: dummy", "tilemap")
end

-- -----------------------------------------------------------------------------
-- LAutoTileSheet methods
-- -----------------------------------------------------------------------------

--@api-stub: LAutoTileSheet:type
-- Returns the type name of this userdata
do
  local ok_at, auto_tile_sheet_obj = pcall(lurek.tilemap.newAutoTileSheet, nil, nil, nil)
  local t = (ok_at and auto_tile_sheet_obj) and auto_tile_sheet_obj:type() or "LAutoTileSheet"
  lurek.log.info("LAutoTileSheet:type = " .. t, "tilemap")
end
--@api-stub: LAutoTileSheet:typeOf
-- Checks whether this object matches the given type name
do
  local ok_at2, auto_tile_sheet_obj = pcall(lurek.tilemap.newAutoTileSheet, nil, nil, nil)
  lurek.log.info("is LAutoTileSheet: " .. tostring((ok_at2 and auto_tile_sheet_obj) and auto_tile_sheet_obj:typeOf("LAutoTileSheet") or false), "tilemap")
  lurek.log.info("is wrong: " .. tostring((ok_at2 and auto_tile_sheet_obj) and auto_tile_sheet_obj:typeOf("Unknown") or false), "tilemap")
end
--@api-stub: LChunkMap:type
-- Returns the type name of this userdata
do
  local ok_cm, chunk_map_obj = pcall(lurek.tilemap.newChunkMap, nil)
  local t = (ok_cm and chunk_map_obj) and chunk_map_obj:type() or "LChunkMap"
  lurek.log.info("LChunkMap:type = " .. t, "tilemap")
end
--@api-stub: LChunkMap:typeOf
-- Checks whether this object matches the given type name
do
  local ok_cm2, chunk_map_obj = pcall(lurek.tilemap.newChunkMap, nil)
  lurek.log.info("is LChunkMap: " .. tostring((ok_cm2 and chunk_map_obj) and chunk_map_obj:typeOf("LChunkMap") or false), "tilemap")
  lurek.log.info("is wrong: " .. tostring((ok_cm2 and chunk_map_obj) and chunk_map_obj:typeOf("Unknown") or false), "tilemap")
end
--@api-stub: LIsoMap:type
-- Returns the type name of this userdata
do
  local ok_im, iso_map_obj = pcall(lurek.tilemap.newIsoMap)
  local t = (ok_im and iso_map_obj) and iso_map_obj:type() or "LIsoMap"
  lurek.log.info("LIsoMap:type = " .. t, "tilemap")
end
--@api-stub: LIsoMap:typeOf
-- Checks whether this object matches the given type name
do
  local ok_im2, iso_map_obj = pcall(lurek.tilemap.newIsoMap)
  lurek.log.info("is LIsoMap: " .. tostring((ok_im2 and iso_map_obj) and iso_map_obj:typeOf("LIsoMap") or false), "tilemap")
  lurek.log.info("is wrong: " .. tostring((ok_im2 and iso_map_obj) and iso_map_obj:typeOf("Unknown") or false), "tilemap")
end
--@api-stub: LLargeMapRenderer:type
-- Returns the type name of this userdata
do
  local ok_r, large_map_renderer_obj = pcall(lurek.tilemap.newLargeMapRenderer, 16, 16)
  if ok_r and large_map_renderer_obj then
    local t = large_map_renderer_obj:type()
    lurek.log.info("LLargeMapRenderer:type = " .. t, "tilemap")
  else
    lurek.log.info("LLargeMapRenderer:type = skipped", "tilemap")
  end
end
--@api-stub: LLargeMapRenderer:typeOf
-- Checks whether this object matches the given type name
do
  local ok_r2, large_map_renderer_obj = pcall(lurek.tilemap.newLargeMapRenderer, 16, 16)
  if ok_r2 and large_map_renderer_obj then
    lurek.log.info("is LLargeMapRenderer: " .. tostring(large_map_renderer_obj:typeOf("LLargeMapRenderer")), "tilemap")
    lurek.log.info("is wrong: " .. tostring(large_map_renderer_obj:typeOf("Unknown")), "tilemap")
  else
    lurek.log.info("LLargeMapRenderer:typeOf = skipped", "tilemap")
  end
end
--@api-stub: LMapBlock:type
-- Returns the type name of this userdata
do
  local ok_mb, map_block_obj = pcall(lurek.tilemap.newMapBlock, 32, 32)
  if ok_mb and map_block_obj then
    local t = map_block_obj:type()
    lurek.log.info("LMapBlock:type = " .. t, "tilemap")
  else
    lurek.log.info("LMapBlock:type = skipped", "tilemap")
  end
end
--@api-stub: LMapBlock:typeOf
-- Checks whether this object matches the given type name
do
  local ok_mb2, map_block_obj = pcall(lurek.tilemap.newMapBlock, 32, 32)
  if ok_mb2 and map_block_obj then
    lurek.log.info("is LMapBlock: " .. tostring(map_block_obj:typeOf("LMapBlock")), "tilemap")
    lurek.log.info("is wrong: " .. tostring(map_block_obj:typeOf("Unknown")), "tilemap")
  else
    lurek.log.info("LMapBlock:typeOf = skipped", "tilemap")
  end
end
--@api-stub: LMapGen:type
-- Returns the type name of this userdata
do
  local grp = lurek.tilemap.newMapGroup("test")
  grp:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  local map_gen_obj = lurek.tilemap.newMapGen(grp, "small", 8)
  local t = map_gen_obj:type()
  lurek.log.info("LMapGen:type = " .. t, "tilemap")
end
--@api-stub: LMapGen:typeOf
-- Checks whether this object matches the given type name
do
  local grp = lurek.tilemap.newMapGroup("test")
  grp:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  local map_gen_obj = lurek.tilemap.newMapGen(grp, "small", 8)
  lurek.log.info("is LMapGen: " .. tostring(map_gen_obj:typeOf("LMapGen")), "tilemap")
  lurek.log.info("is wrong: " .. tostring(map_gen_obj:typeOf("Unknown")), "tilemap")
end
--@api-stub: LMapGroup:type
-- Returns the type name of this userdata
do
  local map_group_obj = lurek.tilemap.newMapGroup("test")
  local t = map_group_obj:type()
  lurek.log.info("LMapGroup:type = " .. t, "tilemap")
end
--@api-stub: LMapGroup:typeOf
-- Checks whether this object matches the given type name
do
  local map_group_obj = lurek.tilemap.newMapGroup("test")
  lurek.log.info("is LMapGroup: " .. tostring(map_group_obj:typeOf("LMapGroup")), "tilemap")
  lurek.log.info("is wrong: " .. tostring(map_group_obj:typeOf("Unknown")), "tilemap")
end
--@api-stub: LMapScript:type
-- Returns the type name of this userdata
do
  local map_script_obj = lurek.tilemap.newMapScript()
  local t = map_script_obj:type()
  lurek.log.info("LMapScript:type = " .. t, "tilemap")
end
--@api-stub: LMapScript:typeOf
-- Checks whether this object matches the given type name
do
  local map_script_obj = lurek.tilemap.newMapScript()
  lurek.log.info("is LMapScript: " .. tostring(map_script_obj:typeOf("LMapScript")), "tilemap")
  lurek.log.info("is wrong: " .. tostring(map_script_obj:typeOf("Unknown")), "tilemap")
end
--@api-stub: LTileMap:type
-- Returns the type name of this userdata
do
  local tile_map_obj = lurek.tilemap.newTileMap(32, 32)
  local t = tile_map_obj:type()
  lurek.log.info("LTileMap:type = " .. t, "tilemap")
end
--@api-stub: LTileMap:typeOf
-- Checks whether this object matches the given type name
do
  local tile_map_obj = lurek.tilemap.newTileMap(32, 32)
  lurek.log.info("is LTileMap: " .. tostring(tile_map_obj:typeOf("LTileMap")), "tilemap")
  lurek.log.info("is wrong: " .. tostring(tile_map_obj:typeOf("Unknown")), "tilemap")
end
--@api-stub: LTileSet:type
-- Returns the type name of this userdata
do
  local tile_set_obj = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
  local t = tile_set_obj:type()
  lurek.log.info("LTileSet:type = " .. t, "tilemap")
end
--@api-stub: LTileSet:typeOf
-- Checks whether this object matches the given type name
do
  local tile_set_obj = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
  lurek.log.info("is LTileSet: " .. tostring(tile_set_obj:typeOf("LTileSet")), "tilemap")
  lurek.log.info("is wrong: " .. tostring(tile_set_obj:typeOf("Unknown")), "tilemap")
end


-- -----------------------------------------------------------------------------
-- LLargeMapRenderer methods
-- -----------------------------------------------------------------------------

--@api-stub: LLargeMapRenderer:setMapData
-- Replaces all tile data with a flat array of GIDs for the given dimensions
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  local map_data = {}
  for i = 1, 8 * 8 do map_data[i] = (i % 4) + 1 end
  lmr:setMapData(map_data, 8, 8)
  lurek.log.info("map loaded: " .. lmr:getMapSize(), "tilemap")
end
--@api-stub: LLargeMapRenderer:setTile
-- Sets a single tile GID at a given position
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  local data = {}; for i = 1, 8*8 do data[i] = 1 end
  lmr:setMapData(data, 8, 8)
  lmr:setTile(3, 2, 5)   -- (0-based col=3, row=2) â†’ tile 5
  lurek.log.info("tile(3,2)=" .. tostring(lmr:getTile(3, 2)), "tilemap")
end
--@api-stub: LLargeMapRenderer:getTile
-- Returns the tile GID at a given position
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  local data = {}; for i = 1, 4*4 do data[i] = i end
  lmr:setMapData(data, 4, 4)
  local id = lmr:getTile(1, 2)
  lurek.log.info("tile(1,2)=" .. tostring(id), "tilemap")
end
--@api-stub: LLargeMapRenderer:getMapSize
-- Returns the map dimensions in tiles
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  local data = {}; for i = 1, 10*10 do data[i] = 1 end
  lmr:setMapData(data, 10, 10)
  local w, h = lmr:getMapSize()
  lurek.log.info("map size=" .. w .. "x" .. h, "tilemap")
end
--@api-stub: LLargeMapRenderer:setChunkSize
-- Sets the chunk size used for rendering subdivision
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lmr:setChunkSize(8)
  lurek.log.info("chunk_size=" .. lmr:getChunkSize(), "tilemap")
end
--@api-stub: LLargeMapRenderer:getChunkSize
-- Returns the current chunk size
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lmr:setChunkSize(16)
  lurek.log.info("chunk_size=" .. lmr:getChunkSize(), "tilemap")
end
--@api-stub: LLargeMapRenderer:invalidateChunk
-- Marks a specific chunk as dirty so it will be rebuilt on the next render
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  local data = {}; for i = 1, 32*32 do data[i] = 1 end
  lmr:setMapData(data, 32, 32)
  lmr:setTile(5, 5, 2)
  lmr:invalidateChunk(0, 0)   -- chunk (0,0) contains tile (5,5) for chunk_size=16
  lurek.log.info("chunk (0,0) invalidated", "tilemap")
end
--@api-stub: LLargeMapRenderer:invalidateAll
-- Marks all chunks as dirty, forcing a full rebuild on the next render
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lmr:invalidateAll()
  lurek.log.info("all chunks invalidated", "tilemap")
end
--@api-stub: LLargeMapRenderer:getVisibleChunks
-- Returns the number of chunks currently visible in the viewport
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  local data = {}; for i = 1, 32*32 do data[i] = 1 end
  lmr:setMapData(data, 32, 32)
  lmr:setCamera(0, 0, 1.0)
  lmr:setViewport(800, 600)
  lurek.log.info("visible_chunks=" .. lmr:getVisibleChunks(), "tilemap")
end
--@api-stub: LLargeMapRenderer:getTotalChunks
-- Returns the total number of chunks in the map
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  local data = {}; for i = 1, 32*32 do data[i] = 1 end
  lmr:setMapData(data, 32, 32)
  lurek.log.info("total_chunks=" .. lmr:getTotalChunks(), "tilemap")
end
--@api-stub: LLargeMapRenderer:setCamera
-- Sets the camera position and zoom level for determining visible chunks
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lmr:setCamera(128, 64, 2.0)   -- camera at world (128, 64), zoom 2Ă—
  lmr:setViewport(800, 600)
  lurek.log.info("camera updated, visible=" .. lmr:getVisibleChunks(), "tilemap")
end
--@api-stub: LLargeMapRenderer:setViewport
-- Sets the viewport dimensions for visibility calculations
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lmr:setViewport(1280, 720)
  lmr:setCamera(0, 0, 1.0)
  lurek.log.info("viewport set 1280x720", "tilemap")
end
--@api-stub: LLargeMapRenderer:setLodEnabled
-- Enables or disables level-of-detail rendering for distant chunks
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lmr:setLodEnabled(true)
  lurek.log.info("lod_enabled=" .. tostring(lmr:isLodEnabled()), "tilemap")
end
--@api-stub: LLargeMapRenderer:isLodEnabled
-- Returns whether LOD rendering is currently enabled
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lmr:setLodEnabled(false)
  lurek.log.info("lod=" .. tostring(lmr:isLodEnabled()), "tilemap")
end
--@api-stub: LLargeMapRenderer:setLodThresholds
-- Sets the zoom thresholds at which LOD levels change
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lmr:setLodEnabled(true)
  lmr:setLodThresholds({32, 64, 128})   -- lod1 at 32 tiles, lod2 at 64, lod3 at 128
  lurek.log.info("LOD thresholds configured", "tilemap")
end
--@api-stub: LLargeMapRenderer:setTilesetColumns
-- Sets the column count of the associated tileset atlas for UV calculation
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lmr:setTilesetColumns(16)   -- 16-column atlas (e.g. 256Ă—256 with 16Ă—16 tiles)
  lurek.log.info("tileset_cols=" .. lmr:getTilesetColumns(), "tilemap")
end
--@api-stub: LLargeMapRenderer:getTilesetColumns
-- Returns the tileset column count used for UV calculation
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lmr:setTilesetColumns(8)
  lurek.log.info("tileset_cols=" .. lmr:getTilesetColumns(), "tilemap")
end

--@api-stub: LTileMap:applyAutoTile8At
-- Applies the auto-tile 8-neighbour rule at a single tile position and updates surrounding tiles.
do
  local tm = lurek.tilemap.new(20, 20, 16, 16)
  tm:applyAutoTile8At(5, 5)
end
