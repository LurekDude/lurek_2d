-- content/examples/tilemap.lua
-- Practical usage examples for the lurek.tilemap API (134 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.tilemap.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/tilemap.lua

print("[example] lurek.tilemap — 134 API entries")

-- ── lurek.tilemap.* free functions ──

--@api-stub: lurek.tilemap.newTileSet
-- Creates a new TileSet with the given atlas layout parameters.
-- Call when you need to create a new tile set.
local ok, obj = pcall(function() return lurek.tilemap.newTileSet() end)
if ok and obj then print("created:", obj) end
print("lurek.tilemap.newTileSet ok=", ok)

--@api-stub: lurek.tilemap.newTileMap
-- Creates a new TileMap with the given tile size and chunk size.
-- Call when you need to create a new tile map.
local ok, obj = pcall(function() return lurek.tilemap.newTileMap(nil, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.tilemap.newTileMap ok=", ok)

--@api-stub: lurek.tilemap.newAutoTileSheet
-- Creates a new AutoTileSheet with the given tile dimensions and layout.
-- Call when you need to create a new auto tile sheet.
local ok, obj = pcall(function() return lurek.tilemap.newAutoTileSheet(nil, nil, "layout_str value") end)
if ok and obj then print("created:", obj) end
print("lurek.tilemap.newAutoTileSheet ok=", ok)

--@api-stub: lurek.tilemap.newChunkMap
-- Creates a new ChunkMap with the given chunk size.
-- Call when you need to create a new chunk map.
local ok, obj = pcall(function() return lurek.tilemap.newChunkMap(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.tilemap.newChunkMap ok=", ok)

--@api-stub: lurek.tilemap.newIsoMap
-- Creates a new IsoMap with no levels.
-- Call when you need to create a new iso map.
local ok, obj = pcall(function() return lurek.tilemap.newIsoMap() end)
if ok and obj then print("created:", obj) end
print("lurek.tilemap.newIsoMap ok=", ok)

--@api-stub: lurek.tilemap.newMapBlock
-- Creates a new MapBlock with the given dimensions.
-- Call when you need to create a new map block.
local ok, obj = pcall(function() return lurek.tilemap.newMapBlock(100, 100, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.tilemap.newMapBlock ok=", ok)

--@api-stub: lurek.tilemap.newMapGroup
-- Creates a new empty MapGroup with the given name.
-- Call when you need to create a new map group.
local ok, obj = pcall(function() return lurek.tilemap.newMapGroup("name") end)
if ok and obj then print("created:", obj) end
print("lurek.tilemap.newMapGroup ok=", ok)

--@api-stub: lurek.tilemap.toScreenIso
-- Converts tile coordinates to screen position using diamond isometric projection.
-- Call when you need to invoke to screen iso.
local ok, result = pcall(function() return lurek.tilemap.toScreenIso(nil, nil, nil, nil) end)
if ok then print("lurek.tilemap.toScreenIso ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tilemap.fromScreenIso
-- Converts screen position back to tile coordinates for diamond isometric projection.
-- Call when you need to invoke from screen iso.
local ok, obj = pcall(function() return lurek.tilemap.fromScreenIso(nil, nil, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.tilemap.fromScreenIso ok=", ok)

--@api-stub: lurek.tilemap.toScreenHex
-- Converts axial hex coordinates to screen position (pointy-top layout).
-- Call when you need to invoke to screen hex.
local ok, result = pcall(function() return lurek.tilemap.toScreenHex(nil, 1, 10) end)
if ok then print("lurek.tilemap.toScreenHex ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tilemap.fromScreenHex
-- Converts screen position back to axial hex coordinates (pointy-top layout).
-- Call when you need to invoke from screen hex.
local ok, obj = pcall(function() return lurek.tilemap.fromScreenHex(nil, nil, 10) end)
if ok and obj then print("created:", obj) end
print("lurek.tilemap.fromScreenHex ok=", ok)

--@api-stub: lurek.tilemap.hexNeighbors
-- Returns the six axial neighbor coordinates as a table of {q, r} pairs.
-- Call when you need to invoke hex neighbors.
local ok, result = pcall(function() return lurek.tilemap.hexNeighbors(nil, 1) end)
if ok then print("lurek.tilemap.hexNeighbors ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tilemap.hexDistance
-- Returns the hex distance between two axial coordinates.
-- Call when you need to invoke hex distance.
local ok, result = pcall(function() return lurek.tilemap.hexDistance(nil, nil, nil, nil) end)
if ok then print("lurek.tilemap.hexDistance ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tilemap.hexRound
-- Rounds fractional axial coordinates to the nearest hex cell.
-- Call when you need to invoke hex round.
local ok, result = pcall(function() return lurek.tilemap.hexRound(nil, 1) end)
if ok then print("lurek.tilemap.hexRound ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tilemap.hexLine
-- Returns all hex cells along a line between two axial coordinates as a table.
-- Call when you need to invoke hex line.
local ok, result = pcall(function() return lurek.tilemap.hexLine(nil, nil, nil, nil) end)
if ok then print("lurek.tilemap.hexLine ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tilemap.hexRing
-- Returns all cells at exactly radius distance from (q, r) as a table.
-- Call when you need to invoke hex ring.
local ok, result = pcall(function() return lurek.tilemap.hexRing(nil, 1, nil) end)
if ok then print("lurek.tilemap.hexRing ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tilemap.hexSpiral
-- Returns all hex cells from center outward to radius, ring by ring, as a table.
-- Call when you need to invoke hex spiral.
local ok, result = pcall(function() return lurek.tilemap.hexSpiral(nil, 1, nil) end)
if ok then print("lurek.tilemap.hexSpiral ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tilemap.hexArea
-- Returns all hex cells within radius distance (filled hex circle) as a table.
-- Call when you need to invoke hex area.
local ok, result = pcall(function() return lurek.tilemap.hexArea(nil, 1, nil) end)
if ok then print("lurek.tilemap.hexArea ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tilemap.hexRotate
-- Rotates hex coordinates around a center by steps x 60 degrees clockwise.
-- Call when you need to invoke hex rotate.
local ok, result = pcall(function() return lurek.tilemap.hexRotate(nil, 1, nil, nil, nil) end)
if ok then print("lurek.tilemap.hexRotate ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tilemap.hexReflect
-- Reflects hex coordinates across an axis through the center.
-- Call when you need to invoke hex reflect.
local ok, result = pcall(function() return lurek.tilemap.hexReflect(nil, 1, nil, nil, nil) end)
if ok then print("lurek.tilemap.hexReflect ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.tilemap.isoRotate
-- Rotates an isometric direction (1-4) clockwise by steps.
-- Call when you need to invoke iso rotate.
local ok, result = pcall(function() return lurek.tilemap.isoRotate("direction", nil) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.tilemap.isoRotate ok=", ok)

--@api-stub: lurek.tilemap.isoDirectionName
-- Returns the name of an isometric direction (1-4).
-- Call when you need to invoke iso direction name.
local ok, result = pcall(function() return lurek.tilemap.isoDirectionName("direction") end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.tilemap.isoDirectionName ok=", ok)

--@api-stub: lurek.tilemap.isoDirectionFromAngle
-- Snaps an angle (in radians) to the nearest isometric direction (1-4).
-- Call when you need to invoke iso direction from angle.
local ok, result = pcall(function() return lurek.tilemap.isoDirectionFromAngle(0) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.tilemap.isoDirectionFromAngle ok=", ok)

--@api-stub: lurek.tilemap.newMapScript
-- Creates a new empty MapScript procedural generation script.
-- Call when you need to create a new map script.
local ok, obj = pcall(function() return lurek.tilemap.newMapScript() end)
if ok and obj then print("created:", obj) end
print("lurek.tilemap.newMapScript ok=", ok)

--@api-stub: lurek.tilemap.newMapGen
-- Creates a MapGen from a MapGroup, a preset name or dimensions, and a segment size.
-- Call when you need to create a new map gen.
local ok, obj = pcall(function() return lurek.tilemap.newMapGen() end)
if ok and obj then print("created:", obj) end
print("lurek.tilemap.newMapGen ok=", ok)

--@api-stub: lurek.tilemap.loadTMX
-- Parses a TMX XML string and returns a table with map metadata and layers.
-- Call when you need to load t m x.
local ok, obj = pcall(function() return lurek.tilemap.loadTMX(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.tilemap.loadTMX ok=", ok)

--@api-stub: lurek.tilemap.fromLDtk
-- Parses an LDtk JSON export string and returns a TileMap.
-- Call when you need to invoke from l dtk.
local ok, obj = pcall(function() return lurek.tilemap.fromLDtk("json_str value", "level_name") end)
if ok and obj then print("created:", obj) end
print("lurek.tilemap.fromLDtk ok=", ok)

--@api-stub: lurek.tilemap.newLargeMapRenderer
-- Creates a LargeMapRenderer for chunk-level occlusion culling on maps > 200Ă—200 tiles.
-- Call when you need to create a new large map renderer.
local ok, obj = pcall(function() return lurek.tilemap.newLargeMapRenderer(nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.tilemap.newLargeMapRenderer ok=", ok)

-- ── TileSet methods ──

--@api-stub: TileSet:getFirstGid
-- Returns the first global ID assigned to this tileset.
-- Call when you need to read first gid.
-- Build a TileSet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileSet(...)
if instance then
  local ok, result = pcall(function() return instance:getFirstGid() end)
  print("TileSet:getFirstGid ->", ok, result)
end

--@api-stub: TileSet:getTileCount
-- Returns the total number of tiles in this tileset.
-- Call when you need to read tile count.
-- Build a TileSet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileSet(...)
if instance then
  local ok, result = pcall(function() return instance:getTileCount() end)
  print("TileSet:getTileCount ->", ok, result)
end

--@api-stub: TileSet:getColumns
-- Returns the number of tile columns in the atlas texture.
-- Call when you need to read columns.
-- Build a TileSet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileSet(...)
if instance then
  local ok, result = pcall(function() return instance:getColumns() end)
  print("TileSet:getColumns ->", ok, result)
end

--@api-stub: TileSet:getTileWidth
-- Returns the width of a single tile in pixels.
-- Call when you need to read tile width.
-- Build a TileSet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileSet(...)
if instance then
  local ok, result = pcall(function() return instance:getTileWidth() end)
  print("TileSet:getTileWidth ->", ok, result)
end

--@api-stub: TileSet:getTileHeight
-- Returns the height of a single tile in pixels.
-- Call when you need to read tile height.
-- Build a TileSet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileSet(...)
if instance then
  local ok, result = pcall(function() return instance:getTileHeight() end)
  print("TileSet:getTileHeight ->", ok, result)
end

--@api-stub: TileSet:getTileDimensions
-- Returns the tile dimensions as (width, height).
-- Call when you need to read tile dimensions.
-- Build a TileSet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileSet(...)
if instance then
  local ok, result = pcall(function() return instance:getTileDimensions() end)
  print("TileSet:getTileDimensions ->", ok, result)
end

--@api-stub: TileSet:getSpacing
-- Returns the spacing in pixels between tiles in the atlas.
-- Call when you need to read spacing.
-- Build a TileSet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileSet(...)
if instance then
  local ok, result = pcall(function() return instance:getSpacing() end)
  print("TileSet:getSpacing ->", ok, result)
end

--@api-stub: TileSet:getMargin
-- Returns the margin in pixels around the edges of the atlas.
-- Call when you need to read margin.
-- Build a TileSet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileSet(...)
if instance then
  local ok, result = pcall(function() return instance:getMargin() end)
  print("TileSet:getMargin ->", ok, result)
end

--@api-stub: TileSet:getQuad
-- Computes the atlas source rectangle for a 1-based local tile ID.
-- Call when you need to read quad.
-- Build a TileSet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileSet(...)
if instance then
  local ok, result = pcall(function() return instance:getQuad(1) end)
  print("TileSet:getQuad ->", ok, result)
end

--@api-stub: TileSet:getAnimation
-- Returns the animation frames for a 1-based local tile ID as a table of {tileid, duration}, or nil.
-- Call when you need to read animation.
-- Build a TileSet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileSet(...)
if instance then
  local ok, result = pcall(function() return instance:getAnimation(1) end)
  print("TileSet:getAnimation ->", ok, result)
end

--@api-stub: TileSet:setSolid
-- Sets whether a 1-based local tile ID is solid for collision purposes.
-- Call when you need to assign solid.
-- Build a TileSet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileSet(...)
if instance then
  local ok, result = pcall(function() return instance:setSolid(1, 1) end)
  print("TileSet:setSolid ->", ok, result)
end

--@api-stub: TileSet:isSolid
-- Returns whether a 1-based local tile ID is solid.
-- Call when you need to check is solid.
-- Build a TileSet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileSet(...)
if instance then
  local ok, result = pcall(function() return instance:isSolid(1) end)
  print("TileSet:isSolid ->", ok, result)
end

-- ── TileMap methods ──

--@api-stub: TileMap:addTileSet
-- Adds a tileset to this map.
-- Call when you need to add tile set.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:addTileSet(nil) end)
  print("TileMap:addTileSet ->", ok, result)
end

--@api-stub: TileMap:getTileSetCount
-- Returns the number of tilesets attached to this map.
-- Call when you need to read tile set count.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:getTileSetCount() end)
  print("TileMap:getTileSetCount ->", ok, result)
end

--@api-stub: TileMap:getTileSet
-- Returns a tileset by 1-based index, or nil if out of range.
-- Call when you need to read tile set.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:getTileSet(1) end)
  print("TileMap:getTileSet ->", ok, result)
end

--@api-stub: TileMap:addLayer
-- Adds a new empty layer and returns its 1-based index.
-- Call when you need to add layer.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:addLayer("name", 100, 100) end)
  print("TileMap:addLayer ->", ok, result)
end

--@api-stub: TileMap:getLayerCount
-- Returns the number of layers.
-- Call when you need to read layer count.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:getLayerCount() end)
  print("TileMap:getLayerCount ->", ok, result)
end

--@api-stub: TileMap:getLayerName
-- Returns the name of a layer by 1-based index.
-- Call when you need to read layer name.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:getLayerName(1) end)
  print("TileMap:getLayerName ->", ok, result)
end

--@api-stub: TileMap:getLayerVisible
-- Returns layer visibility.
-- Call when you need to read layer visible.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:getLayerVisible(1) end)
  print("TileMap:getLayerVisible ->", ok, result)
end

--@api-stub: TileMap:getLayerColor
-- Returns the RGBA tint color of a layer.
-- Call when you need to read layer color.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:getLayerColor(1) end)
  print("TileMap:getLayerColor ->", ok, result)
end

--@api-stub: TileMap:getLayerOffset
-- Returns the pixel offset of a layer.
-- Call when you need to read layer offset.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:getLayerOffset(1) end)
  print("TileMap:getLayerOffset ->", ok, result)
end

--@api-stub: TileMap:getLayerParallax
-- Returns the parallax factor of a layer.
-- Call when you need to read layer parallax.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:getLayerParallax(1) end)
  print("TileMap:getLayerParallax ->", ok, result)
end

--@api-stub: TileMap:getTile
-- Returns the GID at (x, y) on the given layer (1-based).
-- Call when you need to read tile.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:getTile(nil, 0, 0) end)
  print("TileMap:getTile ->", ok, result)
end

--@api-stub: TileMap:clearTile
-- Clears a tile (sets GID to 0) at (x, y) on the given layer (1-based).
-- Call when you need to invoke clear tile.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:clearTile(nil, 0, 0) end)
  print("TileMap:clearTile ->", ok, result)
end

--@api-stub: TileMap:fill
-- Fills an entire layer with the given GID (1-based layer).
-- Call when you need to invoke fill.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:fill(nil, 1) end)
  print("TileMap:fill ->", ok, result)
end

--@api-stub: TileMap:getViewport
-- Returns the viewport as (x, y, w, h) or nil if not set.
-- Call when you need to read viewport.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:getViewport() end)
  print("TileMap:getViewport ->", ok, result)
end

--@api-stub: TileMap:update
-- Advances tile animation timers by dt seconds.
-- Call when you need to invoke update.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("TileMap:update ->", ok, result)
end

--@api-stub: TileMap:worldToTile
-- Converts world pixel coordinates to tile coordinates.
-- Call when you need to invoke world to tile.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:worldToTile(nil, nil) end)
  print("TileMap:worldToTile ->", ok, result)
end

--@api-stub: TileMap:tileToWorld
-- Converts tile coordinates to world pixel coordinates (1-based input).
-- Call when you need to invoke tile to world.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:tileToWorld(nil, nil) end)
  print("TileMap:tileToWorld ->", ok, result)
end

--@api-stub: TileMap:getTileWidth
-- Returns the tile width in pixels.
-- Call when you need to read tile width.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:getTileWidth() end)
  print("TileMap:getTileWidth ->", ok, result)
end

--@api-stub: TileMap:getTileHeight
-- Returns the tile height in pixels.
-- Call when you need to read tile height.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:getTileHeight() end)
  print("TileMap:getTileHeight ->", ok, result)
end

--@api-stub: TileMap:getTileDimensions
-- Returns tile dimensions as (width, height).
-- Call when you need to read tile dimensions.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:getTileDimensions() end)
  print("TileMap:getTileDimensions ->", ok, result)
end

--@api-stub: TileMap:getChunkSize
-- Returns the chunk size used for spatial partitioning.
-- Call when you need to read chunk size.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:getChunkSize() end)
  print("TileMap:getChunkSize ->", ok, result)
end

--@api-stub: TileMap:isSolid
-- Returns true if the tile at (x, y) on layer is solid (1-based).
-- Call when you need to check is solid.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:isSolid(nil, 0, 0) end)
  print("TileMap:isSolid ->", ok, result)
end

--@api-stub: TileMap:getOrientation
-- Returns the map orientation as a string ("topdown", "sideview", "isometric", or "hexagonal").
-- Call when you need to read orientation.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:getOrientation() end)
  print("TileMap:getOrientation ->", ok, result)
end

--@api-stub: TileMap:setOrientation
-- Sets the map orientation from a string ("topdown", "sideview", "isometric", or "hexagonal").
-- Call when you need to assign orientation.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:setOrientation(nil) end)
  print("TileMap:setOrientation ->", ok, result)
end

--@api-stub: TileMap:render
-- Renders the tile map to the screen at the given offset.
-- Call when you need to invoke render.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:render(nil, nil) end)
  print("TileMap:render ->", ok, result)
end

--@api-stub: TileMap:drawToImage
-- Renders the tile map to a CPU ImageData using the given tile pixel size.
-- Call when you need to render to image.
-- Build a TileMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newTileMap(...)
if instance then
  local ok, result = pcall(function() return instance:drawToImage(nil) end)
  print("TileMap:drawToImage ->", ok, result)
end

-- ── AutoTileSheet methods ──

--@api-stub: AutoTileSheet:getLayout
-- Returns the layout variant as a string.
-- Call when you need to read layout.
-- Build a AutoTileSheet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newAutoTileSheet(...)
if instance then
  local ok, result = pcall(function() return instance:getLayout() end)
  print("AutoTileSheet:getLayout ->", ok, result)
end

--@api-stub: AutoTileSheet:getTileCount
-- Returns the number of tiles in this sheet.
-- Call when you need to read tile count.
-- Build a AutoTileSheet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newAutoTileSheet(...)
if instance then
  local ok, result = pcall(function() return instance:getTileCount() end)
  print("AutoTileSheet:getTileCount ->", ok, result)
end

--@api-stub: AutoTileSheet:getTileWidth
-- Returns the tile width in pixels.
-- Call when you need to read tile width.
-- Build a AutoTileSheet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newAutoTileSheet(...)
if instance then
  local ok, result = pcall(function() return instance:getTileWidth() end)
  print("AutoTileSheet:getTileWidth ->", ok, result)
end

--@api-stub: AutoTileSheet:getTileHeight
-- Returns the tile height in pixels.
-- Call when you need to read tile height.
-- Build a AutoTileSheet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newAutoTileSheet(...)
if instance then
  local ok, result = pcall(function() return instance:getTileHeight() end)
  print("AutoTileSheet:getTileHeight ->", ok, result)
end

--@api-stub: AutoTileSheet:getBitmaskForTile
-- Returns the bitmask value associated with a 1-based local tile ID.
-- Call when you need to read bitmask for tile.
-- Build a AutoTileSheet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newAutoTileSheet(...)
if instance then
  local ok, result = pcall(function() return instance:getBitmaskForTile(1) end)
  print("AutoTileSheet:getBitmaskForTile ->", ok, result)
end

--@api-stub: AutoTileSheet:getTileForBitmask
-- Returns the 1-based tile ID for a given bitmask, or nil.
-- Call when you need to read tile for bitmask.
-- Build a AutoTileSheet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newAutoTileSheet(...)
if instance then
  local ok, result = pcall(function() return instance:getTileForBitmask(nil) end)
  print("AutoTileSheet:getTileForBitmask ->", ok, result)
end

--@api-stub: AutoTileSheet:getQuad
-- Returns the atlas region rectangle for the 1-based tile ID.
-- Call when you need to read quad.
-- Build a AutoTileSheet via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newAutoTileSheet(...)
if instance then
  local ok, result = pcall(function() return instance:getQuad(1) end)
  print("AutoTileSheet:getQuad ->", ok, result)
end

-- ── ChunkMap methods ──

--@api-stub: ChunkMap:getTile
-- Returns the GID at tile coordinate (x, y).
-- Call when you need to read tile.
-- Build a ChunkMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newChunkMap(...)
if instance then
  local ok, result = pcall(function() return instance:getTile(0, 0) end)
  print("ChunkMap:getTile ->", ok, result)
end

--@api-stub: ChunkMap:setTile
-- Sets the GID at tile coordinate (x, y).
-- Call when you need to assign tile.
-- Build a ChunkMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newChunkMap(...)
if instance then
  local ok, result = pcall(function() return instance:setTile(0, 0, 1) end)
  print("ChunkMap:setTile ->", ok, result)
end

--@api-stub: ChunkMap:clearTile
-- Clears the tile at (x, y) by setting its GID to 0.
-- Call when you need to invoke clear tile.
-- Build a ChunkMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newChunkMap(...)
if instance then
  local ok, result = pcall(function() return instance:clearTile(0, 0) end)
  print("ChunkMap:clearTile ->", ok, result)
end

--@api-stub: ChunkMap:loadChunk
-- Pre-allocates the chunk at chunk coordinates (cx, cy).
-- Call when you need to load chunk.
-- Build a ChunkMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newChunkMap(...)
if instance then
  local ok, result = pcall(function() return instance:loadChunk(nil, nil) end)
  print("ChunkMap:loadChunk ->", ok, result)
end

--@api-stub: ChunkMap:unloadChunk
-- Removes the chunk at chunk coordinates (cx, cy) from memory.
-- Call when you need to invoke unload chunk.
-- Build a ChunkMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newChunkMap(...)
if instance then
  local ok, result = pcall(function() return instance:unloadChunk(nil, nil) end)
  print("ChunkMap:unloadChunk ->", ok, result)
end

--@api-stub: ChunkMap:getChunkSize
-- Returns the chunk size (tiles per side).
-- Call when you need to read chunk size.
-- Build a ChunkMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newChunkMap(...)
if instance then
  local ok, result = pcall(function() return instance:getChunkSize() end)
  print("ChunkMap:getChunkSize ->", ok, result)
end

--@api-stub: ChunkMap:getLoadedChunks
-- Returns a table of all currently loaded chunk coordinates as {{cx, cy}, ...}.
-- Call when you need to read loaded chunks.
-- Build a ChunkMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newChunkMap(...)
if instance then
  local ok, result = pcall(function() return instance:getLoadedChunks() end)
  print("ChunkMap:getLoadedChunks ->", ok, result)
end

--@api-stub: ChunkMap:chunkTileRange
-- Returns the tile coordinate range for chunk (cx, cy) as (x0, y0, x1, y1).
-- Call when you need to invoke chunk tile range.
-- Build a ChunkMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newChunkMap(...)
if instance then
  local ok, result = pcall(function() return instance:chunkTileRange(nil, nil) end)
  print("ChunkMap:chunkTileRange ->", ok, result)
end

-- ── LargeMapRenderer methods ──

--@api-stub: LargeMapRenderer:setTile
-- Sets a single tile ID at (x, y).
-- Coordinates are 0-based.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:setTile(0, 0, 1) end)
  print("LargeMapRenderer:setTile ->", ok, result)
end

--@api-stub: LargeMapRenderer:getTile
-- Returns the tile ID at (x, y), or nil if out of bounds.
-- Call when you need to read tile.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:getTile(0, 0) end)
  print("LargeMapRenderer:getTile ->", ok, result)
end

--@api-stub: LargeMapRenderer:getMapSize
-- Returns the map dimensions as (width, height) in tiles.
-- Call when you need to read map size.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:getMapSize() end)
  print("LargeMapRenderer:getMapSize ->", ok, result)
end

--@api-stub: LargeMapRenderer:setChunkSize
-- Sets the chunk size used for culling (default 16).
-- Call when you need to assign chunk size.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:setChunkSize(10) end)
  print("LargeMapRenderer:setChunkSize ->", ok, result)
end

--@api-stub: LargeMapRenderer:getChunkSize
-- Returns the current chunk size.
-- Call when you need to read chunk size.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:getChunkSize() end)
  print("LargeMapRenderer:getChunkSize ->", ok, result)
end

--@api-stub: LargeMapRenderer:invalidateChunk
-- Marks a chunk at chunk-grid coordinates (cx, cy) as dirty,.
-- Call when you need to invoke invalidate chunk.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:invalidateChunk(nil, nil) end)
  print("LargeMapRenderer:invalidateChunk ->", ok, result)
end

--@api-stub: LargeMapRenderer:invalidateAll
-- Marks every chunk as dirty.
-- Call when you need to invoke invalidate all.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:invalidateAll() end)
  print("LargeMapRenderer:invalidateAll ->", ok, result)
end

--@api-stub: LargeMapRenderer:getVisibleChunks
-- Returns the number of chunks currently within the camera viewport.
-- Call when you need to read visible chunks.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:getVisibleChunks() end)
  print("LargeMapRenderer:getVisibleChunks ->", ok, result)
end

--@api-stub: LargeMapRenderer:getTotalChunks
-- Returns the total number of chunks that cover the loaded map.
-- Call when you need to read total chunks.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:getTotalChunks() end)
  print("LargeMapRenderer:getTotalChunks ->", ok, result)
end

--@api-stub: LargeMapRenderer:setCamera
-- Updates the camera position and zoom used for visibility culling.
-- Call when you need to assign camera.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:setCamera(0, 0, nil) end)
  print("LargeMapRenderer:setCamera ->", ok, result)
end

--@api-stub: LargeMapRenderer:setViewport
-- Sets the viewport dimensions in pixels used for visibility culling.
-- Call when you need to assign viewport.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:setViewport(100, 100) end)
  print("LargeMapRenderer:setViewport ->", ok, result)
end

--@api-stub: LargeMapRenderer:setLodEnabled
-- Enables or disables level-of-detail rendering for distant chunks.
-- Call when you need to assign lod enabled.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:setLodEnabled(nil) end)
  print("LargeMapRenderer:setLodEnabled ->", ok, result)
end

--@api-stub: LargeMapRenderer:isLodEnabled
-- Returns whether LOD rendering is currently enabled.
-- Call when you need to check is lod enabled.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:isLodEnabled() end)
  print("LargeMapRenderer:isLodEnabled ->", ok, result)
end

--@api-stub: LargeMapRenderer:setLodThresholds
-- Sets the distance thresholds (in tile units) at which each LOD level activates.
-- Call when you need to assign lod thresholds.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:setLodThresholds(nil) end)
  print("LargeMapRenderer:setLodThresholds ->", ok, result)
end

--@api-stub: LargeMapRenderer:setTilesetColumns
-- Sets the number of tile columns in the atlas texture used for UV calculation.
-- Call when you need to assign tileset columns.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:setTilesetColumns(10) end)
  print("LargeMapRenderer:setTilesetColumns ->", ok, result)
end

--@api-stub: LargeMapRenderer:getTilesetColumns
-- Returns the number of tileset atlas columns.
-- Call when you need to read tileset columns.
-- Build a LargeMapRenderer via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newLargeMapRenderer(...)
if instance then
  local ok, result = pcall(function() return instance:getTilesetColumns() end)
  print("LargeMapRenderer:getTilesetColumns ->", ok, result)
end

-- ── IsoMap methods ──

--@api-stub: IsoMap:addLevel
-- Appends a new empty Z-level and returns its 1-based index.
-- Call when you need to add level.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:addLevel() end)
  print("IsoMap:addLevel ->", ok, result)
end

--@api-stub: IsoMap:getLevelCount
-- Returns the number of Z-levels currently in the map.
-- Call when you need to read level count.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:getLevelCount() end)
  print("IsoMap:getLevelCount ->", ok, result)
end

--@api-stub: IsoMap:setLevelVisible
-- Sets the visibility of a level (1-based z).
-- Call when you need to assign level visible.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:setLevelVisible(0, nil) end)
  print("IsoMap:setLevelVisible ->", ok, result)
end

--@api-stub: IsoMap:isLevelVisible
-- Returns the visibility of a level (1-based z).
-- Call when you need to check is level visible.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:isLevelVisible(0) end)
  print("IsoMap:isLevelVisible ->", ok, result)
end

--@api-stub: IsoMap:fillLevel
-- Fills every cell in level z with gid for the given part (1-based z; 0-based part).
-- Call when you need to invoke fill level.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:fillLevel(0, nil, 1) end)
  print("IsoMap:fillLevel ->", ok, result)
end

--@api-stub: IsoMap:setOrigin
-- Sets the screen pixel origin.
-- Call when you need to assign origin.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:setOrigin(0, 0) end)
  print("IsoMap:setOrigin ->", ok, result)
end

--@api-stub: IsoMap:getWidth
-- Returns the map width in tiles.
-- Call when you need to read width.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("IsoMap:getWidth ->", ok, result)
end

--@api-stub: IsoMap:getHeight
-- Returns the map height in tiles.
-- Call when you need to read height.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("IsoMap:getHeight ->", ok, result)
end

--@api-stub: IsoMap:getTileWidth
-- Returns the tile footprint width in pixels.
-- Call when you need to read tile width.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:getTileWidth() end)
  print("IsoMap:getTileWidth ->", ok, result)
end

--@api-stub: IsoMap:getTileHeight
-- Returns the tile footprint height in pixels.
-- Call when you need to read tile height.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:getTileHeight() end)
  print("IsoMap:getTileHeight ->", ok, result)
end

--@api-stub: IsoMap:getLevelHeight
-- Returns the vertical pixel offset between consecutive Z-levels.
-- Call when you need to read level height.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:getLevelHeight() end)
  print("IsoMap:getLevelHeight ->", ok, result)
end

--@api-stub: IsoMap:tileToScreen
-- Projects isometric tile coordinates (tx, ty, tz) to screen pixels.
-- Call when you need to invoke tile to screen.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:tileToScreen(nil, nil, nil) end)
  print("IsoMap:tileToScreen ->", ok, result)
end

--@api-stub: IsoMap:screenToTile
-- Converts screen pixel coordinates to isometric tile coordinates at Z-level 0.
-- Call when you need to invoke screen to tile.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:screenToTile(nil, nil) end)
  print("IsoMap:screenToTile ->", ok, result)
end

--@api-stub: IsoMap:getPartCount
-- Returns the number of GID slots per tile.
-- Call when you need to read part count.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:getPartCount() end)
  print("IsoMap:getPartCount ->", ok, result)
end

--@api-stub: IsoMap:getPartOrder
-- Returns the current draw-order array (0-based part slot indices).
-- Call when you need to read part order.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:getPartOrder() end)
  print("IsoMap:getPartOrder ->", ok, result)
end

--@api-stub: IsoMap:setPartOrder
-- Overrides the draw order for this IsoMap.
-- Length must equal partCount.
-- Build a IsoMap via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newIsoMap(...)
if instance then
  local ok, result = pcall(function() return instance:setPartOrder(nil) end)
  print("IsoMap:setPartOrder ->", ok, result)
end

-- ── MapBlock methods ──

--@api-stub: MapBlock:getTile
-- Returns the GID of the tile at (x, y) on the given layer (1-based).
-- Call when you need to read tile.
-- Build a MapBlock via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapBlock(...)
if instance then
  local ok, result = pcall(function() return instance:getTile(nil, 0, 0) end)
  print("MapBlock:getTile ->", ok, result)
end

--@api-stub: MapBlock:getSide
-- Returns the side connection ID for a segment on a given edge.
-- Call when you need to read side.
-- Build a MapBlock via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapBlock(...)
if instance then
  local ok, result = pcall(function() return instance:getSide("edge_str value", nil) end)
  print("MapBlock:getSide ->", ok, result)
end

--@api-stub: MapBlock:getWidth
-- Returns the block width in tiles.
-- Call when you need to read width.
-- Build a MapBlock via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapBlock(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("MapBlock:getWidth ->", ok, result)
end

--@api-stub: MapBlock:getHeight
-- Returns the block height in tiles.
-- Call when you need to read height.
-- Build a MapBlock via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapBlock(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("MapBlock:getHeight ->", ok, result)
end

--@api-stub: MapBlock:getDimensions
-- Returns the block dimensions as (width, height) in tiles.
-- Call when you need to read dimensions.
-- Build a MapBlock via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapBlock(...)
if instance then
  local ok, result = pcall(function() return instance:getDimensions() end)
  print("MapBlock:getDimensions ->", ok, result)
end

--@api-stub: MapBlock:getLayerCount
-- Returns the number of layers in this block.
-- Call when you need to read layer count.
-- Build a MapBlock via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapBlock(...)
if instance then
  local ok, result = pcall(function() return instance:getLayerCount() end)
  print("MapBlock:getLayerCount ->", ok, result)
end

--@api-stub: MapBlock:getSegmentSize
-- Returns the segment size in tiles.
-- Call when you need to read segment size.
-- Build a MapBlock via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapBlock(...)
if instance then
  local ok, result = pcall(function() return instance:getSegmentSize() end)
  print("MapBlock:getSegmentSize ->", ok, result)
end

--@api-stub: MapBlock:getWidthInSegments
-- Returns the number of segments along the width.
-- Call when you need to read width in segments.
-- Build a MapBlock via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapBlock(...)
if instance then
  local ok, result = pcall(function() return instance:getWidthInSegments() end)
  print("MapBlock:getWidthInSegments ->", ok, result)
end

--@api-stub: MapBlock:getHeightInSegments
-- Returns the number of segments along the height.
-- Call when you need to read height in segments.
-- Build a MapBlock via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapBlock(...)
if instance then
  local ok, result = pcall(function() return instance:getHeightInSegments() end)
  print("MapBlock:getHeightInSegments ->", ok, result)
end

--@api-stub: MapBlock:setName
-- Sets the human-readable name of this block.
-- Call when you need to assign name.
-- Build a MapBlock via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapBlock(...)
if instance then
  local ok, result = pcall(function() return instance:setName("name") end)
  print("MapBlock:setName ->", ok, result)
end

--@api-stub: MapBlock:getName
-- Returns the name of this block.
-- Call when you need to read name.
-- Build a MapBlock via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapBlock(...)
if instance then
  local ok, result = pcall(function() return instance:getName() end)
  print("MapBlock:getName ->", ok, result)
end

--@api-stub: MapBlock:setWeight
-- Sets the placement weight.
-- Call when you need to assign weight.
-- Build a MapBlock via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapBlock(...)
if instance then
  local ok, result = pcall(function() return instance:setWeight(nil) end)
  print("MapBlock:setWeight ->", ok, result)
end

--@api-stub: MapBlock:getWeight
-- Returns the placement weight.
-- Call when you need to read weight.
-- Build a MapBlock via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapBlock(...)
if instance then
  local ok, result = pcall(function() return instance:getWeight() end)
  print("MapBlock:getWeight ->", ok, result)
end

-- ── MapGroup methods ──

--@api-stub: MapGroup:addBlock
-- Adds a block to this group.
-- Call when you need to add block.
-- Build a MapGroup via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapGroup(...)
if instance then
  local ok, result = pcall(function() return instance:addBlock(nil) end)
  print("MapGroup:addBlock ->", ok, result)
end

--@api-stub: MapGroup:getBlockCount
-- Returns the number of blocks in this group.
-- Call when you need to read block count.
-- Build a MapGroup via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapGroup(...)
if instance then
  local ok, result = pcall(function() return instance:getBlockCount() end)
  print("MapGroup:getBlockCount ->", ok, result)
end

--@api-stub: MapGroup:removeBlock
-- Removes a block by 1-based index.
-- Call when you need to remove block.
-- Build a MapGroup via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapGroup(...)
if instance then
  local ok, result = pcall(function() return instance:removeBlock(1) end)
  print("MapGroup:removeBlock ->", ok, result)
end

--@api-stub: MapGroup:getName
-- Returns the name of this group.
-- Call when you need to read name.
-- Build a MapGroup via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapGroup(...)
if instance then
  local ok, result = pcall(function() return instance:getName() end)
  print("MapGroup:getName ->", ok, result)
end

--@api-stub: MapGroup:addScript
-- Adds a MapScript to this group.
-- Call when you need to add script.
-- Build a MapGroup via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapGroup(...)
if instance then
  local ok, result = pcall(function() return instance:addScript(nil) end)
  print("MapGroup:addScript ->", ok, result)
end

--@api-stub: MapGroup:getScriptCount
-- Returns the number of scripts in this group.
-- Call when you need to read script count.
-- Build a MapGroup via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapGroup(...)
if instance then
  local ok, result = pcall(function() return instance:getScriptCount() end)
  print("MapGroup:getScriptCount ->", ok, result)
end

-- ── MapScript methods ──

--@api-stub: MapScript:getStepCount
-- Returns the number of steps in this script.
-- Call when you need to read step count.
-- Build a MapScript via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapScript(...)
if instance then
  local ok, result = pcall(function() return instance:getStepCount() end)
  print("MapScript:getStepCount ->", ok, result)
end

--@api-stub: MapScript:addStep
-- Appends a generation step from a step-definition table.
-- Call when you need to add step.
-- Build a MapScript via the appropriate lurek.tilemap.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.tilemap.newMapScript(...)
if instance then
  local ok, result = pcall(function() return instance:addStep(nil) end)
  print("MapScript:addStep ->", ok, result)
end

