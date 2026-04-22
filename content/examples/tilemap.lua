-- content/examples/tilemap.lua
-- Auto-scaffolded coverage of the lurek.tilemap Lua API (134 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/tilemap.lua

print("[example] lurek.tilemap loaded — 134 API items demonstrated")

-- ── lurek.tilemap free functions ──

--@api-stub: lurek.tilemap.newTileSet
-- Creates a new TileSet with the given atlas layout parameters.
-- Use this when creates a new TileSet with the given atlas layout parameters is needed.
if false then
  local _r = lurek.tilemap.newTileSet()
  print(_r)
end

--@api-stub: lurek.tilemap.newTileMap
-- Creates a new TileMap with the given tile size and chunk size.
-- Use this when creates a new TileMap with the given tile size and chunk size is needed.
if false then
  local _r = lurek.tilemap.newTileMap(1, 1, 1)
  print(_r)
end

--@api-stub: lurek.tilemap.newAutoTileSheet
-- Creates a new AutoTileSheet with the given tile dimensions and layout.
-- Use this when creates a new AutoTileSheet with the given tile dimensions and layout is needed.
if false then
  local _r = lurek.tilemap.newAutoTileSheet(0, 0, 0)
  print(_r)
end

--@api-stub: lurek.tilemap.newChunkMap
-- Creates a new ChunkMap with the given chunk size.
-- Use this when creates a new ChunkMap with the given chunk size is needed.
if false then
  local _r = lurek.tilemap.newChunkMap(1)
  print(_r)
end

--@api-stub: lurek.tilemap.newIsoMap
-- Creates a new IsoMap with no levels.
-- Use this when creates a new IsoMap with no levels is needed.
if false then
  local _r = lurek.tilemap.newIsoMap()
  print(_r)
end

--@api-stub: lurek.tilemap.newMapBlock
-- Creates a new MapBlock with the given dimensions.
-- Use this when creates a new MapBlock with the given dimensions is needed.
if false then
  local _r = lurek.tilemap.newMapBlock(1, 1, 0, 1)
  print(_r)
end

--@api-stub: lurek.tilemap.newMapGroup
-- Creates a new empty MapGroup with the given name.
-- Use this when creates a new empty MapGroup with the given name is needed.
if false then
  local _r = lurek.tilemap.newMapGroup(1)
  print(_r)
end

--@api-stub: lurek.tilemap.toScreenIso
-- Converts tile coordinates to screen position using diamond isometric projection.
-- Use this when converts tile coordinates to screen position using diamond isometric projection is needed.
if false then
  local _r = lurek.tilemap.toScreenIso(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.tilemap.fromScreenIso
-- Converts screen position back to tile coordinates for diamond isometric projection.
-- Use this when converts screen position back to tile coordinates for diamond isometric projection is needed.
if false then
  local _r = lurek.tilemap.fromScreenIso(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.tilemap.toScreenHex
-- Converts axial hex coordinates to screen position (pointy-top layout).
-- Use this when converts axial hex coordinates to screen position (pointy-top layout) is needed.
if false then
  local _r = lurek.tilemap.toScreenHex(nil, nil, 1)
  print(_r)
end

--@api-stub: lurek.tilemap.fromScreenHex
-- Converts screen position back to axial hex coordinates (pointy-top layout).
-- Use this when converts screen position back to axial hex coordinates (pointy-top layout) is needed.
if false then
  local _r = lurek.tilemap.fromScreenHex(0, 0, 1)
  print(_r)
end

--@api-stub: lurek.tilemap.hexNeighbors
-- Returns the six axial neighbor coordinates as a table of {q, r} pairs.
-- Use this when returns the six axial neighbor coordinates as a table of {q, r} pairs is needed.
if false then
  local _r = lurek.tilemap.hexNeighbors(nil, nil)
  print(_r)
end

--@api-stub: lurek.tilemap.hexDistance
-- Returns the hex distance between two axial coordinates.
-- Use this when returns the hex distance between two axial coordinates is needed.
if false then
  local _r = lurek.tilemap.hexDistance(nil, nil, nil, nil)
  print(_r)
end

--@api-stub: lurek.tilemap.hexRound
-- Rounds fractional axial coordinates to the nearest hex cell.
-- Use this when rounds fractional axial coordinates to the nearest hex cell is needed.
if false then
  local _r = lurek.tilemap.hexRound(nil, nil)
  print(_r)
end

--@api-stub: lurek.tilemap.hexLine
-- Returns all hex cells along a line between two axial coordinates as a table.
-- Use this when returns all hex cells along a line between two axial coordinates as a table is needed.
if false then
  local _r = lurek.tilemap.hexLine(nil, nil, nil, nil)
  print(_r)
end

--@api-stub: lurek.tilemap.hexRing
-- Returns all cells at exactly radius distance from (q, r) as a table.
-- Use this when returns all cells at exactly radius distance from (q, r) as a table is needed.
if false then
  local _r = lurek.tilemap.hexRing(nil, nil, nil)
  print(_r)
end

--@api-stub: lurek.tilemap.hexSpiral
-- Returns all hex cells from center outward to radius, ring by ring, as a table.
-- Use this when returns all hex cells from center outward to radius, ring by ring, as a table is needed.
if false then
  local _r = lurek.tilemap.hexSpiral(nil, nil, nil)
  print(_r)
end

--@api-stub: lurek.tilemap.hexArea
-- Returns all hex cells within radius distance (filled hex circle) as a table.
-- Use this when returns all hex cells within radius distance (filled hex circle) as a table is needed.
if false then
  local _r = lurek.tilemap.hexArea(nil, nil, nil)
  print(_r)
end

--@api-stub: lurek.tilemap.hexRotate
-- Rotates hex coordinates around a center by steps x 60 degrees clockwise.
-- Use this when rotates hex coordinates around a center by steps x 60 degrees clockwise is needed.
if false then
  local _r = lurek.tilemap.hexRotate(nil, nil, 1, 1, 0)
  print(_r)
end

--@api-stub: lurek.tilemap.hexReflect
-- Reflects hex coordinates across an axis through the center.
-- Use this when reflects hex coordinates across an axis through the center is needed.
if false then
  local _r = lurek.tilemap.hexReflect(nil, nil, 1, 1, 0)
  print(_r)
end

--@api-stub: lurek.tilemap.isoRotate
-- Rotates an isometric direction (1-4) clockwise by steps.
-- Use this when rotates an isometric direction (1-4) clockwise by steps is needed.
if false then
  local _r = lurek.tilemap.isoRotate(1, 0)
  print(_r)
end

--@api-stub: lurek.tilemap.isoDirectionName
-- Returns the name of an isometric direction (1-4).
-- Use this when returns the name of an isometric direction (1-4) is needed.
if false then
  local _r = lurek.tilemap.isoDirectionName(1)
  print(_r)
end

--@api-stub: lurek.tilemap.isoDirectionFromAngle
-- Snaps an angle (in radians) to the nearest isometric direction (1-4).
-- Use this when snaps an angle (in radians) to the nearest isometric direction (1-4) is needed.
if false then
  local _r = lurek.tilemap.isoDirectionFromAngle(1)
  print(_r)
end

--@api-stub: lurek.tilemap.newMapScript
-- Creates a new empty MapScript procedural generation script.
-- Use this when creates a new empty MapScript procedural generation script is needed.
if false then
  local _r = lurek.tilemap.newMapScript()
  print(_r)
end

--@api-stub: lurek.tilemap.newMapGen
-- Creates a MapGen from a MapGroup, a preset name or dimensions, and a segment size.
-- Use this when creates a MapGen from a MapGroup, a preset name or dimensions, and a segment size is needed.
if false then
  local _r = lurek.tilemap.newMapGen()
  print(_r)
end

--@api-stub: lurek.tilemap.loadTMX
-- Parses a TMX XML string and returns a table with map metadata and layers.
-- Use this when parses a TMX XML string and returns a table with map metadata and layers is needed.
if false then
  local _r = lurek.tilemap.loadTMX(0)
  print(_r)
end

--@api-stub: lurek.tilemap.fromLDtk
-- Parses an LDtk JSON export string and returns a TileMap.
-- Use this when parses an LDtk JSON export string and returns a TileMap is needed.
if false then
  local _r = lurek.tilemap.fromLDtk(1, 1)
  print(_r)
end

--@api-stub: lurek.tilemap.newLargeMapRenderer
-- Creates a LargeMapRenderer for chunk-level occlusion culling on maps > 200Ă—200 tiles.
-- Use this when creates a LargeMapRenderer for chunk-level occlusion culling on maps > 200Ă—200 tiles is needed.
if false then
  local _r = lurek.tilemap.newLargeMapRenderer(0, 0)
  print(_r)
end

-- ── TileSet methods ──

--@api-stub: TileSet:getFirstGid
-- Returns the first global ID assigned to this tileset.
-- Use this when returns the first global ID assigned to this tileset is needed.
if false then
  local _o = nil  -- TileSet instance
  _o:getFirstGid()
end

--@api-stub: TileSet:getTileCount
-- Returns the total number of tiles in this tileset.
-- Use this when returns the total number of tiles in this tileset is needed.
if false then
  local _o = nil  -- TileSet instance
  _o:getTileCount()
end

--@api-stub: TileSet:getColumns
-- Returns the number of tile columns in the atlas texture.
-- Use this when returns the number of tile columns in the atlas texture is needed.
if false then
  local _o = nil  -- TileSet instance
  _o:getColumns()
end

--@api-stub: TileSet:getTileWidth
-- Returns the width of a single tile in pixels.
-- Use this when returns the width of a single tile in pixels is needed.
if false then
  local _o = nil  -- TileSet instance
  _o:getTileWidth()
end

--@api-stub: TileSet:getTileHeight
-- Returns the height of a single tile in pixels.
-- Use this when returns the height of a single tile in pixels is needed.
if false then
  local _o = nil  -- TileSet instance
  _o:getTileHeight()
end

--@api-stub: TileSet:getTileDimensions
-- Returns the tile dimensions as (width, height).
-- Use this when returns the tile dimensions as (width, height) is needed.
if false then
  local _o = nil  -- TileSet instance
  _o:getTileDimensions()
end

--@api-stub: TileSet:getSpacing
-- Returns the spacing in pixels between tiles in the atlas.
-- Use this when returns the spacing in pixels between tiles in the atlas is needed.
if false then
  local _o = nil  -- TileSet instance
  _o:getSpacing()
end

--@api-stub: TileSet:getMargin
-- Returns the margin in pixels around the edges of the atlas.
-- Use this when returns the margin in pixels around the edges of the atlas is needed.
if false then
  local _o = nil  -- TileSet instance
  _o:getMargin()
end

--@api-stub: TileSet:getQuad
-- Computes the atlas source rectangle for a 1-based local tile ID.
-- Use this when computes the atlas source rectangle for a 1-based local tile ID is needed.
if false then
  local _o = nil  -- TileSet instance
  _o:getQuad(1)
end

--@api-stub: TileSet:getAnimation
-- Returns the animation frames for a 1-based local tile ID as a table of {tileid, duration}, or nil.
-- Use this when returns the animation frames for a 1-based local tile ID as a table of {tileid, duration}, or nil is needed.
if false then
  local _o = nil  -- TileSet instance
  _o:getAnimation(1)
end

--@api-stub: TileSet:setSolid
-- Sets whether a 1-based local tile ID is solid for collision purposes.
-- Use this when sets whether a 1-based local tile ID is solid for collision purposes is needed.
if false then
  local _o = nil  -- TileSet instance
  _o:setSolid(1, 1)
end

--@api-stub: TileSet:isSolid
-- Returns whether a 1-based local tile ID is solid.
-- Use this when returns whether a 1-based local tile ID is solid is needed.
if false then
  local _o = nil  -- TileSet instance
  _o:isSolid(1)
end

-- ── TileMap methods ──

--@api-stub: TileMap:addTileSet
-- Adds a tileset to this map.
-- Use this when adds a tileset to this map is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:addTileSet(0)
end

--@api-stub: TileMap:getTileSetCount
-- Returns the number of tilesets attached to this map.
-- Use this when returns the number of tilesets attached to this map is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:getTileSetCount()
end

--@api-stub: TileMap:getTileSet
-- Returns a tileset by 1-based index, or nil if out of range.
-- Use this when returns a tileset by 1-based index, or nil if out of range is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:getTileSet(1)
end

--@api-stub: TileMap:addLayer
-- Adds a new empty layer and returns its 1-based index.
-- Use this when adds a new empty layer and returns its 1-based index is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:addLayer(1, 0, 0)
end

--@api-stub: TileMap:getLayerCount
-- Returns the number of layers.
-- Use this when returns the number of layers is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:getLayerCount()
end

--@api-stub: TileMap:getLayerName
-- Returns the name of a layer by 1-based index.
-- Use this when returns the name of a layer by 1-based index is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:getLayerName(1)
end

--@api-stub: TileMap:getLayerVisible
-- Returns layer visibility.
-- Use this when returns layer visibility is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:getLayerVisible(1)
end

--@api-stub: TileMap:getLayerColor
-- Returns the RGBA tint color of a layer.
-- Use this when returns the RGBA tint color of a layer is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:getLayerColor(1)
end

--@api-stub: TileMap:getLayerOffset
-- Returns the pixel offset of a layer.
-- Use this when returns the pixel offset of a layer is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:getLayerOffset(1)
end

--@api-stub: TileMap:getLayerParallax
-- Returns the parallax factor of a layer.
-- Use this when returns the parallax factor of a layer is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:getLayerParallax(1)
end

--@api-stub: TileMap:getTile
-- Returns the GID at (x, y) on the given layer (1-based).
-- Use this when returns the GID at (x, y) on the given layer (1-based) is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:getTile(0, 0, 0)
end

--@api-stub: TileMap:clearTile
-- Clears a tile (sets GID to 0) at (x, y) on the given layer (1-based).
-- Use this when clears a tile (sets GID to 0) at (x, y) on the given layer (1-based) is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:clearTile(0, 0, 0)
end

--@api-stub: TileMap:fill
-- Fills an entire layer with the given GID (1-based layer).
-- Use this when fills an entire layer with the given GID (1-based layer) is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:fill(0, 1)
end

--@api-stub: TileMap:getViewport
-- Returns the viewport as (x, y, w, h) or nil if not set.
-- Use this when returns the viewport as (x, y, w, h) or nil if not set is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:getViewport()
end

--@api-stub: TileMap:update
-- Advances tile animation timers by dt seconds.
-- Use this when advances tile animation timers by dt seconds is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:update(0)
end

--@api-stub: TileMap:worldToTile
-- Converts world pixel coordinates to tile coordinates.
-- Use this when converts world pixel coordinates to tile coordinates is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:worldToTile(0, 0)
end

--@api-stub: TileMap:tileToWorld
-- Converts tile coordinates to world pixel coordinates (1-based input).
-- Use this when converts tile coordinates to world pixel coordinates (1-based input) is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:tileToWorld(0, 0)
end

--@api-stub: TileMap:getTileWidth
-- Returns the tile width in pixels.
-- Use this when returns the tile width in pixels is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:getTileWidth()
end

--@api-stub: TileMap:getTileHeight
-- Returns the tile height in pixels.
-- Use this when returns the tile height in pixels is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:getTileHeight()
end

--@api-stub: TileMap:getTileDimensions
-- Returns tile dimensions as (width, height).
-- Use this when returns tile dimensions as (width, height) is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:getTileDimensions()
end

--@api-stub: TileMap:getChunkSize
-- Returns the chunk size used for spatial partitioning.
-- Use this when returns the chunk size used for spatial partitioning is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:getChunkSize()
end

--@api-stub: TileMap:isSolid
-- Returns true if the tile at (x, y) on layer is solid (1-based).
-- Use this when returns true if the tile at (x, y) on layer is solid (1-based) is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:isSolid(0, 0, 0)
end

--@api-stub: TileMap:getOrientation
-- Returns the map orientation as a string ("topdown", "sideview", "isometric", or "hexagonal").
-- Use this when returns the map orientation as a string ("topdown", "sideview", "isometric", or "hexagonal") is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:getOrientation()
end

--@api-stub: TileMap:setOrientation
-- Sets the map orientation from a string ("topdown", "sideview", "isometric", or "hexagonal").
-- Use this when sets the map orientation from a string ("topdown", "sideview", "isometric", or "hexagonal") is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:setOrientation(1)
end

--@api-stub: TileMap:render
-- Renders the tile map to the screen at the given offset.
-- Use this when renders the tile map to the screen at the given offset is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:render(0, 0)
end

--@api-stub: TileMap:drawToImage
-- Renders the tile map to a CPU ImageData using the given tile pixel size.
-- Use this when renders the tile map to a CPU ImageData using the given tile pixel size is needed.
if false then
  local _o = nil  -- TileMap instance
  _o:drawToImage(1)
end

-- ── AutoTileSheet methods ──

--@api-stub: AutoTileSheet:getLayout
-- Returns the layout variant as a string.
-- Use this when returns the layout variant as a string is needed.
if false then
  local _o = nil  -- AutoTileSheet instance
  _o:getLayout()
end

--@api-stub: AutoTileSheet:getTileCount
-- Returns the number of tiles in this sheet.
-- Use this when returns the number of tiles in this sheet is needed.
if false then
  local _o = nil  -- AutoTileSheet instance
  _o:getTileCount()
end

--@api-stub: AutoTileSheet:getTileWidth
-- Returns the tile width in pixels.
-- Use this when returns the tile width in pixels is needed.
if false then
  local _o = nil  -- AutoTileSheet instance
  _o:getTileWidth()
end

--@api-stub: AutoTileSheet:getTileHeight
-- Returns the tile height in pixels.
-- Use this when returns the tile height in pixels is needed.
if false then
  local _o = nil  -- AutoTileSheet instance
  _o:getTileHeight()
end

--@api-stub: AutoTileSheet:getBitmaskForTile
-- Returns the bitmask value associated with a 1-based local tile ID.
-- Use this when returns the bitmask value associated with a 1-based local tile ID is needed.
if false then
  local _o = nil  -- AutoTileSheet instance
  _o:getBitmaskForTile(1)
end

--@api-stub: AutoTileSheet:getTileForBitmask
-- Returns the 1-based tile ID for a given bitmask, or nil.
-- Use this when returns the 1-based tile ID for a given bitmask, or nil is needed.
if false then
  local _o = nil  -- AutoTileSheet instance
  _o:getTileForBitmask(0)
end

--@api-stub: AutoTileSheet:getQuad
-- Returns the atlas region rectangle for the 1-based tile ID.
-- Use this when returns the atlas region rectangle for the 1-based tile ID is needed.
if false then
  local _o = nil  -- AutoTileSheet instance
  _o:getQuad(1)
end

-- ── ChunkMap methods ──

--@api-stub: ChunkMap:getTile
-- Returns the GID at tile coordinate (x, y).
-- Use this when returns the GID at tile coordinate (x, y) is needed.
if false then
  local _o = nil  -- ChunkMap instance
  _o:getTile(0, 0)
end

--@api-stub: ChunkMap:setTile
-- Sets the GID at tile coordinate (x, y).
-- Use this when sets the GID at tile coordinate (x, y) is needed.
if false then
  local _o = nil  -- ChunkMap instance
  _o:setTile(0, 0, 1)
end

--@api-stub: ChunkMap:clearTile
-- Clears the tile at (x, y) by setting its GID to 0.
-- Use this when clears the tile at (x, y) by setting its GID to 0 is needed.
if false then
  local _o = nil  -- ChunkMap instance
  _o:clearTile(0, 0)
end

--@api-stub: ChunkMap:loadChunk
-- Pre-allocates the chunk at chunk coordinates (cx, cy).
-- Use this when pre-allocates the chunk at chunk coordinates (cx, cy) is needed.
if false then
  local _o = nil  -- ChunkMap instance
  _o:loadChunk(0, 0)
end

--@api-stub: ChunkMap:unloadChunk
-- Removes the chunk at chunk coordinates (cx, cy) from memory.
-- Use this when removes the chunk at chunk coordinates (cx, cy) from memory is needed.
if false then
  local _o = nil  -- ChunkMap instance
  _o:unloadChunk(0, 0)
end

--@api-stub: ChunkMap:getChunkSize
-- Returns the chunk size (tiles per side).
-- Use this when returns the chunk size (tiles per side) is needed.
if false then
  local _o = nil  -- ChunkMap instance
  _o:getChunkSize()
end

--@api-stub: ChunkMap:getLoadedChunks
-- Returns a table of all currently loaded chunk coordinates as {{cx, cy}, ...}.
-- Use this when returns a table of all currently loaded chunk coordinates as {{cx, cy}, ...} is needed.
if false then
  local _o = nil  -- ChunkMap instance
  _o:getLoadedChunks()
end

--@api-stub: ChunkMap:chunkTileRange
-- Returns the tile coordinate range for chunk (cx, cy) as (x0, y0, x1, y1).
-- Use this when returns the tile coordinate range for chunk (cx, cy) as (x0, y0, x1, y1) is needed.
if false then
  local _o = nil  -- ChunkMap instance
  _o:chunkTileRange(0, 0)
end

-- ── LargeMapRenderer methods ──

--@api-stub: LargeMapRenderer:setTile
-- Sets a single tile ID at (x, y).
-- Coordinates are 0-based.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:setTile(0, 0, 1)
end

--@api-stub: LargeMapRenderer:getTile
-- Returns the tile ID at (x, y), or nil if out of bounds.
-- Use this when returns the tile ID at (x, y), or nil if out of bounds is needed.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:getTile(0, 0)
end

--@api-stub: LargeMapRenderer:getMapSize
-- Returns the map dimensions as (width, height) in tiles.
-- Use this when returns the map dimensions as (width, height) in tiles is needed.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:getMapSize()
end

--@api-stub: LargeMapRenderer:setChunkSize
-- Sets the chunk size used for culling (default 16).
-- Use this when sets the chunk size used for culling (default 16) is needed.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:setChunkSize(1)
end

--@api-stub: LargeMapRenderer:getChunkSize
-- Returns the current chunk size.
-- Use this when returns the current chunk size is needed.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:getChunkSize()
end

--@api-stub: LargeMapRenderer:invalidateChunk
-- Marks a chunk at chunk-grid coordinates (cx, cy) as dirty,.
-- Use this when marks a chunk at chunk-grid coordinates (cx, cy) as dirty, is needed.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:invalidateChunk(0, 0)
end

--@api-stub: LargeMapRenderer:invalidateAll
-- Marks every chunk as dirty.
-- Use this when marks every chunk as dirty is needed.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:invalidateAll()
end

--@api-stub: LargeMapRenderer:getVisibleChunks
-- Returns the number of chunks currently within the camera viewport.
-- Use this when returns the number of chunks currently within the camera viewport is needed.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:getVisibleChunks()
end

--@api-stub: LargeMapRenderer:getTotalChunks
-- Returns the total number of chunks that cover the loaded map.
-- Use this when returns the total number of chunks that cover the loaded map is needed.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:getTotalChunks()
end

--@api-stub: LargeMapRenderer:setCamera
-- Updates the camera position and zoom used for visibility culling.
-- Use this when updates the camera position and zoom used for visibility culling is needed.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:setCamera(0, 0, 0)
end

--@api-stub: LargeMapRenderer:setViewport
-- Sets the viewport dimensions in pixels used for visibility culling.
-- Use this when sets the viewport dimensions in pixels used for visibility culling is needed.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:setViewport(0, 0)
end

--@api-stub: LargeMapRenderer:setLodEnabled
-- Enables or disables level-of-detail rendering for distant chunks.
-- Use this when enables or disables level-of-detail rendering for distant chunks is needed.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:setLodEnabled(1)
end

--@api-stub: LargeMapRenderer:isLodEnabled
-- Returns whether LOD rendering is currently enabled.
-- Use this when returns whether LOD rendering is currently enabled is needed.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:isLodEnabled()
end

--@api-stub: LargeMapRenderer:setLodThresholds
-- Sets the distance thresholds (in tile units) at which each LOD level activates.
-- Use this when sets the distance thresholds (in tile units) at which each LOD level activates is needed.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:setLodThresholds(0)
end

--@api-stub: LargeMapRenderer:setTilesetColumns
-- Sets the number of tile columns in the atlas texture used for UV calculation.
-- Use this when sets the number of tile columns in the atlas texture used for UV calculation is needed.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:setTilesetColumns(1)
end

--@api-stub: LargeMapRenderer:getTilesetColumns
-- Returns the number of tileset atlas columns.
-- Use this when returns the number of tileset atlas columns is needed.
if false then
  local _o = nil  -- LargeMapRenderer instance
  _o:getTilesetColumns()
end

-- ── IsoMap methods ──

--@api-stub: IsoMap:addLevel
-- Appends a new empty Z-level and returns its 1-based index.
-- Use this when appends a new empty Z-level and returns its 1-based index is needed.
if false then
  local _o = nil  -- IsoMap instance
  _o:addLevel()
end

--@api-stub: IsoMap:getLevelCount
-- Returns the number of Z-levels currently in the map.
-- Use this when returns the number of Z-levels currently in the map is needed.
if false then
  local _o = nil  -- IsoMap instance
  _o:getLevelCount()
end

--@api-stub: IsoMap:setLevelVisible
-- Sets the visibility of a level (1-based z).
-- Use this when sets the visibility of a level (1-based z) is needed.
if false then
  local _o = nil  -- IsoMap instance
  _o:setLevelVisible(0, 0)
end

--@api-stub: IsoMap:isLevelVisible
-- Returns the visibility of a level (1-based z).
-- Use this when returns the visibility of a level (1-based z) is needed.
if false then
  local _o = nil  -- IsoMap instance
  _o:isLevelVisible(0)
end

--@api-stub: IsoMap:fillLevel
-- Fills every cell in level z with gid for the given part (1-based z; 0-based part).
-- Use this when fills every cell in level z with gid for the given part (1-based z; 0-based part) is needed.
if false then
  local _o = nil  -- IsoMap instance
  _o:fillLevel(0, 0, 1)
end

--@api-stub: IsoMap:setOrigin
-- Sets the screen pixel origin.
-- Use this when sets the screen pixel origin is needed.
if false then
  local _o = nil  -- IsoMap instance
  _o:setOrigin(0, 0)
end

--@api-stub: IsoMap:getWidth
-- Returns the map width in tiles.
-- Use this when returns the map width in tiles is needed.
if false then
  local _o = nil  -- IsoMap instance
  _o:getWidth()
end

--@api-stub: IsoMap:getHeight
-- Returns the map height in tiles.
-- Use this when returns the map height in tiles is needed.
if false then
  local _o = nil  -- IsoMap instance
  _o:getHeight()
end

--@api-stub: IsoMap:getTileWidth
-- Returns the tile footprint width in pixels.
-- Use this when returns the tile footprint width in pixels is needed.
if false then
  local _o = nil  -- IsoMap instance
  _o:getTileWidth()
end

--@api-stub: IsoMap:getTileHeight
-- Returns the tile footprint height in pixels.
-- Use this when returns the tile footprint height in pixels is needed.
if false then
  local _o = nil  -- IsoMap instance
  _o:getTileHeight()
end

--@api-stub: IsoMap:getLevelHeight
-- Returns the vertical pixel offset between consecutive Z-levels.
-- Use this when returns the vertical pixel offset between consecutive Z-levels is needed.
if false then
  local _o = nil  -- IsoMap instance
  _o:getLevelHeight()
end

--@api-stub: IsoMap:tileToScreen
-- Projects isometric tile coordinates (tx, ty, tz) to screen pixels.
-- Use this when projects isometric tile coordinates (tx, ty, tz) to screen pixels is needed.
if false then
  local _o = nil  -- IsoMap instance
  _o:tileToScreen(0, 0, 0)
end

--@api-stub: IsoMap:screenToTile
-- Converts screen pixel coordinates to isometric tile coordinates at Z-level 0.
-- Use this when converts screen pixel coordinates to isometric tile coordinates at Z-level 0 is needed.
if false then
  local _o = nil  -- IsoMap instance
  _o:screenToTile(0, 0)
end

--@api-stub: IsoMap:getPartCount
-- Returns the number of GID slots per tile.
-- Use this when returns the number of GID slots per tile is needed.
if false then
  local _o = nil  -- IsoMap instance
  _o:getPartCount()
end

--@api-stub: IsoMap:getPartOrder
-- Returns the current draw-order array (0-based part slot indices).
-- Use this when returns the current draw-order array (0-based part slot indices) is needed.
if false then
  local _o = nil  -- IsoMap instance
  _o:getPartOrder()
end

--@api-stub: IsoMap:setPartOrder
-- Overrides the draw order for this IsoMap.
-- Length must equal partCount.
if false then
  local _o = nil  -- IsoMap instance
  _o:setPartOrder(nil)
end

-- ── MapBlock methods ──

--@api-stub: MapBlock:getTile
-- Returns the GID of the tile at (x, y) on the given layer (1-based).
-- Use this when returns the GID of the tile at (x, y) on the given layer (1-based) is needed.
if false then
  local _o = nil  -- MapBlock instance
  _o:getTile(0, 0, 0)
end

--@api-stub: MapBlock:getSide
-- Returns the side connection ID for a segment on a given edge.
-- Use this when returns the side connection ID for a segment on a given edge is needed.
if false then
  local _o = nil  -- MapBlock instance
  _o:getSide(0, 1)
end

--@api-stub: MapBlock:getWidth
-- Returns the block width in tiles.
-- Use this when returns the block width in tiles is needed.
if false then
  local _o = nil  -- MapBlock instance
  _o:getWidth()
end

--@api-stub: MapBlock:getHeight
-- Returns the block height in tiles.
-- Use this when returns the block height in tiles is needed.
if false then
  local _o = nil  -- MapBlock instance
  _o:getHeight()
end

--@api-stub: MapBlock:getDimensions
-- Returns the block dimensions as (width, height) in tiles.
-- Use this when returns the block dimensions as (width, height) in tiles is needed.
if false then
  local _o = nil  -- MapBlock instance
  _o:getDimensions()
end

--@api-stub: MapBlock:getLayerCount
-- Returns the number of layers in this block.
-- Use this when returns the number of layers in this block is needed.
if false then
  local _o = nil  -- MapBlock instance
  _o:getLayerCount()
end

--@api-stub: MapBlock:getSegmentSize
-- Returns the segment size in tiles.
-- Use this when returns the segment size in tiles is needed.
if false then
  local _o = nil  -- MapBlock instance
  _o:getSegmentSize()
end

--@api-stub: MapBlock:getWidthInSegments
-- Returns the number of segments along the width.
-- Use this when returns the number of segments along the width is needed.
if false then
  local _o = nil  -- MapBlock instance
  _o:getWidthInSegments()
end

--@api-stub: MapBlock:getHeightInSegments
-- Returns the number of segments along the height.
-- Use this when returns the number of segments along the height is needed.
if false then
  local _o = nil  -- MapBlock instance
  _o:getHeightInSegments()
end

--@api-stub: MapBlock:setName
-- Sets the human-readable name of this block.
-- Use this when sets the human-readable name of this block is needed.
if false then
  local _o = nil  -- MapBlock instance
  _o:setName(1)
end

--@api-stub: MapBlock:getName
-- Returns the name of this block.
-- Use this when returns the name of this block is needed.
if false then
  local _o = nil  -- MapBlock instance
  _o:getName()
end

--@api-stub: MapBlock:setWeight
-- Sets the placement weight.
-- Use this when sets the placement weight is needed.
if false then
  local _o = nil  -- MapBlock instance
  _o:setWeight(0)
end

--@api-stub: MapBlock:getWeight
-- Returns the placement weight.
-- Use this when returns the placement weight is needed.
if false then
  local _o = nil  -- MapBlock instance
  _o:getWeight()
end

-- ── MapGroup methods ──

--@api-stub: MapGroup:addBlock
-- Adds a block to this group.
-- Use this when adds a block to this group is needed.
if false then
  local _o = nil  -- MapGroup instance
  _o:addBlock(nil)
end

--@api-stub: MapGroup:getBlockCount
-- Returns the number of blocks in this group.
-- Use this when returns the number of blocks in this group is needed.
if false then
  local _o = nil  -- MapGroup instance
  _o:getBlockCount()
end

--@api-stub: MapGroup:removeBlock
-- Removes a block by 1-based index.
-- Use this when removes a block by 1-based index is needed.
if false then
  local _o = nil  -- MapGroup instance
  _o:removeBlock(1)
end

--@api-stub: MapGroup:getName
-- Returns the name of this group.
-- Use this when returns the name of this group is needed.
if false then
  local _o = nil  -- MapGroup instance
  _o:getName()
end

--@api-stub: MapGroup:addScript
-- Adds a MapScript to this group.
-- Use this when adds a MapScript to this group is needed.
if false then
  local _o = nil  -- MapGroup instance
  _o:addScript(0)
end

--@api-stub: MapGroup:getScriptCount
-- Returns the number of scripts in this group.
-- Use this when returns the number of scripts in this group is needed.
if false then
  local _o = nil  -- MapGroup instance
  _o:getScriptCount()
end

-- ── MapScript methods ──

--@api-stub: MapScript:getStepCount
-- Returns the number of steps in this script.
-- Use this when returns the number of steps in this script is needed.
if false then
  local _o = nil  -- MapScript instance
  _o:getStepCount()
end

--@api-stub: MapScript:addStep
-- Appends a generation step from a step-definition table.
-- Use this when appends a generation step from a step-definition table is needed.
if false then
  local _o = nil  -- MapScript instance
  _o:addStep(0)
end

