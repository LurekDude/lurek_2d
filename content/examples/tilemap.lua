-- content/examples/tilemap.lua
-- Scaffolded coverage of the lurek.tilemap API (134 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/tilemap_api.rs   (Lua binding, arg types, return shape)
--   * src/tilemap/                 (semantics, side effects)
--   * docs/specs/tilemap.md        (canonical reference)
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
-- Run: cargo run -- content/examples/tilemap.lua

-- ── lurek.tilemap.* functions ──

--@api-stub: lurek.tilemap.newTileSet
-- Creates a new TileSet with the given atlas layout parameters.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.newTileSet
  local _todo = "TODO: write a real lurek.tilemap.newTileSet usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.newTileMap
-- Creates a new TileMap with the given tile size and chunk size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.newTileMap
  local _todo = "TODO: write a real lurek.tilemap.newTileMap usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.newAutoTileSheet
-- Creates a new AutoTileSheet with the given tile dimensions and layout.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.newAutoTileSheet
  local _todo = "TODO: write a real lurek.tilemap.newAutoTileSheet usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.newChunkMap
-- Creates a new ChunkMap with the given chunk size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.newChunkMap
  local _todo = "TODO: write a real lurek.tilemap.newChunkMap usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.newIsoMap
-- Creates a new IsoMap with no levels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.newIsoMap
  local _todo = "TODO: write a real lurek.tilemap.newIsoMap usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.newMapBlock
-- Creates a new MapBlock with the given dimensions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.newMapBlock
  local _todo = "TODO: write a real lurek.tilemap.newMapBlock usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.newMapGroup
-- Creates a new empty MapGroup with the given name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.newMapGroup
  local _todo = "TODO: write a real lurek.tilemap.newMapGroup usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.toScreenIso
-- Converts tile coordinates to screen position using diamond isometric projection.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.toScreenIso
  local _todo = "TODO: write a real lurek.tilemap.toScreenIso usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.fromScreenIso
-- Converts screen position back to tile coordinates for diamond isometric projection.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.fromScreenIso
  local _todo = "TODO: write a real lurek.tilemap.fromScreenIso usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.toScreenHex
-- Converts axial hex coordinates to screen position (pointy-top layout).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.toScreenHex
  local _todo = "TODO: write a real lurek.tilemap.toScreenHex usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.fromScreenHex
-- Converts screen position back to axial hex coordinates (pointy-top layout).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.fromScreenHex
  local _todo = "TODO: write a real lurek.tilemap.fromScreenHex usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.hexNeighbors
-- Returns the six axial neighbor coordinates as a table of {q, r} pairs.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.hexNeighbors
  local _todo = "TODO: write a real lurek.tilemap.hexNeighbors usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.hexDistance
-- Returns the hex distance between two axial coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.hexDistance
  local _todo = "TODO: write a real lurek.tilemap.hexDistance usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.hexRound
-- Rounds fractional axial coordinates to the nearest hex cell.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.hexRound
  local _todo = "TODO: write a real lurek.tilemap.hexRound usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.hexLine
-- Returns all hex cells along a line between two axial coordinates as a table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.hexLine
  local _todo = "TODO: write a real lurek.tilemap.hexLine usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.hexRing
-- Returns all cells at exactly radius distance from (q, r) as a table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.hexRing
  local _todo = "TODO: write a real lurek.tilemap.hexRing usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.hexSpiral
-- Returns all hex cells from center outward to radius, ring by ring, as a table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.hexSpiral
  local _todo = "TODO: write a real lurek.tilemap.hexSpiral usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.hexArea
-- Returns all hex cells within radius distance (filled hex circle) as a table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.hexArea
  local _todo = "TODO: write a real lurek.tilemap.hexArea usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.hexRotate
-- Rotates hex coordinates around a center by steps x 60 degrees clockwise.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.hexRotate
  local _todo = "TODO: write a real lurek.tilemap.hexRotate usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.hexReflect
-- Reflects hex coordinates across an axis through the center.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.hexReflect
  local _todo = "TODO: write a real lurek.tilemap.hexReflect usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.isoRotate
-- Rotates an isometric direction (1-4) clockwise by steps.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.isoRotate
  local _todo = "TODO: write a real lurek.tilemap.isoRotate usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.isoDirectionName
-- Returns the name of an isometric direction (1-4).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.isoDirectionName
  local _todo = "TODO: write a real lurek.tilemap.isoDirectionName usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.isoDirectionFromAngle
-- Snaps an angle (in radians) to the nearest isometric direction (1-4).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.isoDirectionFromAngle
  local _todo = "TODO: write a real lurek.tilemap.isoDirectionFromAngle usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.newMapScript
-- Creates a new empty MapScript procedural generation script.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.newMapScript
  local _todo = "TODO: write a real lurek.tilemap.newMapScript usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.newMapGen
-- Creates a MapGen from a MapGroup, a preset name or dimensions, and a segment size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.newMapGen
  local _todo = "TODO: write a real lurek.tilemap.newMapGen usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.loadTMX
-- Parses a TMX XML string and returns a table with map metadata and layers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.loadTMX
  local _todo = "TODO: write a real lurek.tilemap.loadTMX usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.fromLDtk
-- Parses an LDtk JSON export string and returns a TileMap.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.fromLDtk
  local _todo = "TODO: write a real lurek.tilemap.fromLDtk usage example"
  print(_todo)
end

--@api-stub: lurek.tilemap.newLargeMapRenderer
-- Creates a LargeMapRenderer for chunk-level occlusion culling on maps > 200Ă—200 tiles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: lurek.tilemap.newLargeMapRenderer
  local _todo = "TODO: write a real lurek.tilemap.newLargeMapRenderer usage example"
  print(_todo)
end

-- ── TileSet methods ──

--@api-stub: TileSet:getFirstGid
-- Returns the first global ID assigned to this tileset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileSet:getFirstGid
  local _todo = "TODO: write a real TileSet:getFirstGid usage example"
  print(_todo)
end

--@api-stub: TileSet:getTileCount
-- Returns the total number of tiles in this tileset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileSet:getTileCount
  local _todo = "TODO: write a real TileSet:getTileCount usage example"
  print(_todo)
end

--@api-stub: TileSet:getColumns
-- Returns the number of tile columns in the atlas texture.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileSet:getColumns
  local _todo = "TODO: write a real TileSet:getColumns usage example"
  print(_todo)
end

--@api-stub: TileSet:getTileWidth
-- Returns the width of a single tile in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileSet:getTileWidth
  local _todo = "TODO: write a real TileSet:getTileWidth usage example"
  print(_todo)
end

--@api-stub: TileSet:getTileHeight
-- Returns the height of a single tile in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileSet:getTileHeight
  local _todo = "TODO: write a real TileSet:getTileHeight usage example"
  print(_todo)
end

--@api-stub: TileSet:getTileDimensions
-- Returns the tile dimensions as (width, height).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileSet:getTileDimensions
  local _todo = "TODO: write a real TileSet:getTileDimensions usage example"
  print(_todo)
end

--@api-stub: TileSet:getSpacing
-- Returns the spacing in pixels between tiles in the atlas.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileSet:getSpacing
  local _todo = "TODO: write a real TileSet:getSpacing usage example"
  print(_todo)
end

--@api-stub: TileSet:getMargin
-- Returns the margin in pixels around the edges of the atlas.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileSet:getMargin
  local _todo = "TODO: write a real TileSet:getMargin usage example"
  print(_todo)
end

--@api-stub: TileSet:getQuad
-- Computes the atlas source rectangle for a 1-based local tile ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileSet:getQuad
  local _todo = "TODO: write a real TileSet:getQuad usage example"
  print(_todo)
end

--@api-stub: TileSet:getAnimation
-- Returns the animation frames for a 1-based local tile ID as a table of {tileid, duration}, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileSet:getAnimation
  local _todo = "TODO: write a real TileSet:getAnimation usage example"
  print(_todo)
end

--@api-stub: TileSet:setSolid
-- Sets whether a 1-based local tile ID is solid for collision purposes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileSet:setSolid
  local _todo = "TODO: write a real TileSet:setSolid usage example"
  print(_todo)
end

--@api-stub: TileSet:isSolid
-- Returns whether a 1-based local tile ID is solid.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileSet:isSolid
  local _todo = "TODO: write a real TileSet:isSolid usage example"
  print(_todo)
end

-- ── TileMap methods ──

--@api-stub: TileMap:addTileSet
-- Adds a tileset to this map.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:addTileSet
  local _todo = "TODO: write a real TileMap:addTileSet usage example"
  print(_todo)
end

--@api-stub: TileMap:getTileSetCount
-- Returns the number of tilesets attached to this map.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:getTileSetCount
  local _todo = "TODO: write a real TileMap:getTileSetCount usage example"
  print(_todo)
end

--@api-stub: TileMap:getTileSet
-- Returns a tileset by 1-based index, or nil if out of range.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:getTileSet
  local _todo = "TODO: write a real TileMap:getTileSet usage example"
  print(_todo)
end

--@api-stub: TileMap:addLayer
-- Adds a new empty layer and returns its 1-based index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:addLayer
  local _todo = "TODO: write a real TileMap:addLayer usage example"
  print(_todo)
end

--@api-stub: TileMap:getLayerCount
-- Returns the number of layers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:getLayerCount
  local _todo = "TODO: write a real TileMap:getLayerCount usage example"
  print(_todo)
end

--@api-stub: TileMap:getLayerName
-- Returns the name of a layer by 1-based index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:getLayerName
  local _todo = "TODO: write a real TileMap:getLayerName usage example"
  print(_todo)
end

--@api-stub: TileMap:getLayerVisible
-- Returns layer visibility.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:getLayerVisible
  local _todo = "TODO: write a real TileMap:getLayerVisible usage example"
  print(_todo)
end

--@api-stub: TileMap:getLayerColor
-- Returns the RGBA tint color of a layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:getLayerColor
  local _todo = "TODO: write a real TileMap:getLayerColor usage example"
  print(_todo)
end

--@api-stub: TileMap:getLayerOffset
-- Returns the pixel offset of a layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:getLayerOffset
  local _todo = "TODO: write a real TileMap:getLayerOffset usage example"
  print(_todo)
end

--@api-stub: TileMap:getLayerParallax
-- Returns the parallax factor of a layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:getLayerParallax
  local _todo = "TODO: write a real TileMap:getLayerParallax usage example"
  print(_todo)
end

--@api-stub: TileMap:getTile
-- Returns the GID at (x, y) on the given layer (1-based).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:getTile
  local _todo = "TODO: write a real TileMap:getTile usage example"
  print(_todo)
end

--@api-stub: TileMap:clearTile
-- Clears a tile (sets GID to 0) at (x, y) on the given layer (1-based).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:clearTile
  local _todo = "TODO: write a real TileMap:clearTile usage example"
  print(_todo)
end

--@api-stub: TileMap:fill
-- Fills an entire layer with the given GID (1-based layer).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:fill
  local _todo = "TODO: write a real TileMap:fill usage example"
  print(_todo)
end

--@api-stub: TileMap:getViewport
-- Returns the viewport as (x, y, w, h) or nil if not set.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:getViewport
  local _todo = "TODO: write a real TileMap:getViewport usage example"
  print(_todo)
end

--@api-stub: TileMap:update
-- Advances tile animation timers by dt seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:update
  local _todo = "TODO: write a real TileMap:update usage example"
  print(_todo)
end

--@api-stub: TileMap:worldToTile
-- Converts world pixel coordinates to tile coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:worldToTile
  local _todo = "TODO: write a real TileMap:worldToTile usage example"
  print(_todo)
end

--@api-stub: TileMap:tileToWorld
-- Converts tile coordinates to world pixel coordinates (1-based input).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:tileToWorld
  local _todo = "TODO: write a real TileMap:tileToWorld usage example"
  print(_todo)
end

--@api-stub: TileMap:getTileWidth
-- Returns the tile width in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:getTileWidth
  local _todo = "TODO: write a real TileMap:getTileWidth usage example"
  print(_todo)
end

--@api-stub: TileMap:getTileHeight
-- Returns the tile height in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:getTileHeight
  local _todo = "TODO: write a real TileMap:getTileHeight usage example"
  print(_todo)
end

--@api-stub: TileMap:getTileDimensions
-- Returns tile dimensions as (width, height).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:getTileDimensions
  local _todo = "TODO: write a real TileMap:getTileDimensions usage example"
  print(_todo)
end

--@api-stub: TileMap:getChunkSize
-- Returns the chunk size used for spatial partitioning.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:getChunkSize
  local _todo = "TODO: write a real TileMap:getChunkSize usage example"
  print(_todo)
end

--@api-stub: TileMap:isSolid
-- Returns true if the tile at (x, y) on layer is solid (1-based).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:isSolid
  local _todo = "TODO: write a real TileMap:isSolid usage example"
  print(_todo)
end

--@api-stub: TileMap:getOrientation
-- Returns the map orientation as a string ("topdown", "sideview", "isometric", or "hexagonal").
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:getOrientation
  local _todo = "TODO: write a real TileMap:getOrientation usage example"
  print(_todo)
end

--@api-stub: TileMap:setOrientation
-- Sets the map orientation from a string ("topdown", "sideview", "isometric", or "hexagonal").
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:setOrientation
  local _todo = "TODO: write a real TileMap:setOrientation usage example"
  print(_todo)
end

--@api-stub: TileMap:render
-- Renders the tile map to the screen at the given offset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:render
  local _todo = "TODO: write a real TileMap:render usage example"
  print(_todo)
end

--@api-stub: TileMap:drawToImage
-- Renders the tile map to a CPU ImageData using the given tile pixel size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: TileMap:drawToImage
  local _todo = "TODO: write a real TileMap:drawToImage usage example"
  print(_todo)
end

-- ── AutoTileSheet methods ──

--@api-stub: AutoTileSheet:getLayout
-- Returns the layout variant as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: AutoTileSheet:getLayout
  local _todo = "TODO: write a real AutoTileSheet:getLayout usage example"
  print(_todo)
end

--@api-stub: AutoTileSheet:getTileCount
-- Returns the number of tiles in this sheet.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: AutoTileSheet:getTileCount
  local _todo = "TODO: write a real AutoTileSheet:getTileCount usage example"
  print(_todo)
end

--@api-stub: AutoTileSheet:getTileWidth
-- Returns the tile width in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: AutoTileSheet:getTileWidth
  local _todo = "TODO: write a real AutoTileSheet:getTileWidth usage example"
  print(_todo)
end

--@api-stub: AutoTileSheet:getTileHeight
-- Returns the tile height in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: AutoTileSheet:getTileHeight
  local _todo = "TODO: write a real AutoTileSheet:getTileHeight usage example"
  print(_todo)
end

--@api-stub: AutoTileSheet:getBitmaskForTile
-- Returns the bitmask value associated with a 1-based local tile ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: AutoTileSheet:getBitmaskForTile
  local _todo = "TODO: write a real AutoTileSheet:getBitmaskForTile usage example"
  print(_todo)
end

--@api-stub: AutoTileSheet:getTileForBitmask
-- Returns the 1-based tile ID for a given bitmask, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: AutoTileSheet:getTileForBitmask
  local _todo = "TODO: write a real AutoTileSheet:getTileForBitmask usage example"
  print(_todo)
end

--@api-stub: AutoTileSheet:getQuad
-- Returns the atlas region rectangle for the 1-based tile ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: AutoTileSheet:getQuad
  local _todo = "TODO: write a real AutoTileSheet:getQuad usage example"
  print(_todo)
end

-- ── ChunkMap methods ──

--@api-stub: ChunkMap:getTile
-- Returns the GID at tile coordinate (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: ChunkMap:getTile
  local _todo = "TODO: write a real ChunkMap:getTile usage example"
  print(_todo)
end

--@api-stub: ChunkMap:setTile
-- Sets the GID at tile coordinate (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: ChunkMap:setTile
  local _todo = "TODO: write a real ChunkMap:setTile usage example"
  print(_todo)
end

--@api-stub: ChunkMap:clearTile
-- Clears the tile at (x, y) by setting its GID to 0.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: ChunkMap:clearTile
  local _todo = "TODO: write a real ChunkMap:clearTile usage example"
  print(_todo)
end

--@api-stub: ChunkMap:loadChunk
-- Pre-allocates the chunk at chunk coordinates (cx, cy).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: ChunkMap:loadChunk
  local _todo = "TODO: write a real ChunkMap:loadChunk usage example"
  print(_todo)
end

--@api-stub: ChunkMap:unloadChunk
-- Removes the chunk at chunk coordinates (cx, cy) from memory.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: ChunkMap:unloadChunk
  local _todo = "TODO: write a real ChunkMap:unloadChunk usage example"
  print(_todo)
end

--@api-stub: ChunkMap:getChunkSize
-- Returns the chunk size (tiles per side).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: ChunkMap:getChunkSize
  local _todo = "TODO: write a real ChunkMap:getChunkSize usage example"
  print(_todo)
end

--@api-stub: ChunkMap:getLoadedChunks
-- Returns a table of all currently loaded chunk coordinates as {{cx, cy}, ...}.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: ChunkMap:getLoadedChunks
  local _todo = "TODO: write a real ChunkMap:getLoadedChunks usage example"
  print(_todo)
end

--@api-stub: ChunkMap:chunkTileRange
-- Returns the tile coordinate range for chunk (cx, cy) as (x0, y0, x1, y1).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: ChunkMap:chunkTileRange
  local _todo = "TODO: write a real ChunkMap:chunkTileRange usage example"
  print(_todo)
end

-- ── LargeMapRenderer methods ──

--@api-stub: LargeMapRenderer:setTile
-- Sets a single tile ID at (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:setTile
  local _todo = "TODO: write a real LargeMapRenderer:setTile usage example"
  print(_todo)
end

--@api-stub: LargeMapRenderer:getTile
-- Returns the tile ID at (x, y), or nil if out of bounds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:getTile
  local _todo = "TODO: write a real LargeMapRenderer:getTile usage example"
  print(_todo)
end

--@api-stub: LargeMapRenderer:getMapSize
-- Returns the map dimensions as (width, height) in tiles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:getMapSize
  local _todo = "TODO: write a real LargeMapRenderer:getMapSize usage example"
  print(_todo)
end

--@api-stub: LargeMapRenderer:setChunkSize
-- Sets the chunk size used for culling (default 16).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:setChunkSize
  local _todo = "TODO: write a real LargeMapRenderer:setChunkSize usage example"
  print(_todo)
end

--@api-stub: LargeMapRenderer:getChunkSize
-- Returns the current chunk size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:getChunkSize
  local _todo = "TODO: write a real LargeMapRenderer:getChunkSize usage example"
  print(_todo)
end

--@api-stub: LargeMapRenderer:invalidateChunk
-- Marks a chunk at chunk-grid coordinates (cx, cy) as dirty,.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:invalidateChunk
  local _todo = "TODO: write a real LargeMapRenderer:invalidateChunk usage example"
  print(_todo)
end

--@api-stub: LargeMapRenderer:invalidateAll
-- Marks every chunk as dirty.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:invalidateAll
  local _todo = "TODO: write a real LargeMapRenderer:invalidateAll usage example"
  print(_todo)
end

--@api-stub: LargeMapRenderer:getVisibleChunks
-- Returns the number of chunks currently within the camera viewport.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:getVisibleChunks
  local _todo = "TODO: write a real LargeMapRenderer:getVisibleChunks usage example"
  print(_todo)
end

--@api-stub: LargeMapRenderer:getTotalChunks
-- Returns the total number of chunks that cover the loaded map.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:getTotalChunks
  local _todo = "TODO: write a real LargeMapRenderer:getTotalChunks usage example"
  print(_todo)
end

--@api-stub: LargeMapRenderer:setCamera
-- Updates the camera position and zoom used for visibility culling.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:setCamera
  local _todo = "TODO: write a real LargeMapRenderer:setCamera usage example"
  print(_todo)
end

--@api-stub: LargeMapRenderer:setViewport
-- Sets the viewport dimensions in pixels used for visibility culling.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:setViewport
  local _todo = "TODO: write a real LargeMapRenderer:setViewport usage example"
  print(_todo)
end

--@api-stub: LargeMapRenderer:setLodEnabled
-- Enables or disables level-of-detail rendering for distant chunks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:setLodEnabled
  local _todo = "TODO: write a real LargeMapRenderer:setLodEnabled usage example"
  print(_todo)
end

--@api-stub: LargeMapRenderer:isLodEnabled
-- Returns whether LOD rendering is currently enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:isLodEnabled
  local _todo = "TODO: write a real LargeMapRenderer:isLodEnabled usage example"
  print(_todo)
end

--@api-stub: LargeMapRenderer:setLodThresholds
-- Sets the distance thresholds (in tile units) at which each LOD level activates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:setLodThresholds
  local _todo = "TODO: write a real LargeMapRenderer:setLodThresholds usage example"
  print(_todo)
end

--@api-stub: LargeMapRenderer:setTilesetColumns
-- Sets the number of tile columns in the atlas texture used for UV calculation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:setTilesetColumns
  local _todo = "TODO: write a real LargeMapRenderer:setTilesetColumns usage example"
  print(_todo)
end

--@api-stub: LargeMapRenderer:getTilesetColumns
-- Returns the number of tileset atlas columns.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: LargeMapRenderer:getTilesetColumns
  local _todo = "TODO: write a real LargeMapRenderer:getTilesetColumns usage example"
  print(_todo)
end

-- ── IsoMap methods ──

--@api-stub: IsoMap:addLevel
-- Appends a new empty Z-level and returns its 1-based index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:addLevel
  local _todo = "TODO: write a real IsoMap:addLevel usage example"
  print(_todo)
end

--@api-stub: IsoMap:getLevelCount
-- Returns the number of Z-levels currently in the map.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:getLevelCount
  local _todo = "TODO: write a real IsoMap:getLevelCount usage example"
  print(_todo)
end

--@api-stub: IsoMap:setLevelVisible
-- Sets the visibility of a level (1-based z).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:setLevelVisible
  local _todo = "TODO: write a real IsoMap:setLevelVisible usage example"
  print(_todo)
end

--@api-stub: IsoMap:isLevelVisible
-- Returns the visibility of a level (1-based z).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:isLevelVisible
  local _todo = "TODO: write a real IsoMap:isLevelVisible usage example"
  print(_todo)
end

--@api-stub: IsoMap:fillLevel
-- Fills every cell in level z with gid for the given part (1-based z; 0-based part).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:fillLevel
  local _todo = "TODO: write a real IsoMap:fillLevel usage example"
  print(_todo)
end

--@api-stub: IsoMap:setOrigin
-- Sets the screen pixel origin.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:setOrigin
  local _todo = "TODO: write a real IsoMap:setOrigin usage example"
  print(_todo)
end

--@api-stub: IsoMap:getWidth
-- Returns the map width in tiles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:getWidth
  local _todo = "TODO: write a real IsoMap:getWidth usage example"
  print(_todo)
end

--@api-stub: IsoMap:getHeight
-- Returns the map height in tiles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:getHeight
  local _todo = "TODO: write a real IsoMap:getHeight usage example"
  print(_todo)
end

--@api-stub: IsoMap:getTileWidth
-- Returns the tile footprint width in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:getTileWidth
  local _todo = "TODO: write a real IsoMap:getTileWidth usage example"
  print(_todo)
end

--@api-stub: IsoMap:getTileHeight
-- Returns the tile footprint height in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:getTileHeight
  local _todo = "TODO: write a real IsoMap:getTileHeight usage example"
  print(_todo)
end

--@api-stub: IsoMap:getLevelHeight
-- Returns the vertical pixel offset between consecutive Z-levels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:getLevelHeight
  local _todo = "TODO: write a real IsoMap:getLevelHeight usage example"
  print(_todo)
end

--@api-stub: IsoMap:tileToScreen
-- Projects isometric tile coordinates (tx, ty, tz) to screen pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:tileToScreen
  local _todo = "TODO: write a real IsoMap:tileToScreen usage example"
  print(_todo)
end

--@api-stub: IsoMap:screenToTile
-- Converts screen pixel coordinates to isometric tile coordinates at Z-level 0.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:screenToTile
  local _todo = "TODO: write a real IsoMap:screenToTile usage example"
  print(_todo)
end

--@api-stub: IsoMap:getPartCount
-- Returns the number of GID slots per tile.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:getPartCount
  local _todo = "TODO: write a real IsoMap:getPartCount usage example"
  print(_todo)
end

--@api-stub: IsoMap:getPartOrder
-- Returns the current draw-order array (0-based part slot indices).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:getPartOrder
  local _todo = "TODO: write a real IsoMap:getPartOrder usage example"
  print(_todo)
end

--@api-stub: IsoMap:setPartOrder
-- Overrides the draw order for this IsoMap.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: IsoMap:setPartOrder
  local _todo = "TODO: write a real IsoMap:setPartOrder usage example"
  print(_todo)
end

-- ── MapBlock methods ──

--@api-stub: MapBlock:getTile
-- Returns the GID of the tile at (x, y) on the given layer (1-based).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapBlock:getTile
  local _todo = "TODO: write a real MapBlock:getTile usage example"
  print(_todo)
end

--@api-stub: MapBlock:getSide
-- Returns the side connection ID for a segment on a given edge.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapBlock:getSide
  local _todo = "TODO: write a real MapBlock:getSide usage example"
  print(_todo)
end

--@api-stub: MapBlock:getWidth
-- Returns the block width in tiles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapBlock:getWidth
  local _todo = "TODO: write a real MapBlock:getWidth usage example"
  print(_todo)
end

--@api-stub: MapBlock:getHeight
-- Returns the block height in tiles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapBlock:getHeight
  local _todo = "TODO: write a real MapBlock:getHeight usage example"
  print(_todo)
end

--@api-stub: MapBlock:getDimensions
-- Returns the block dimensions as (width, height) in tiles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapBlock:getDimensions
  local _todo = "TODO: write a real MapBlock:getDimensions usage example"
  print(_todo)
end

--@api-stub: MapBlock:getLayerCount
-- Returns the number of layers in this block.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapBlock:getLayerCount
  local _todo = "TODO: write a real MapBlock:getLayerCount usage example"
  print(_todo)
end

--@api-stub: MapBlock:getSegmentSize
-- Returns the segment size in tiles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapBlock:getSegmentSize
  local _todo = "TODO: write a real MapBlock:getSegmentSize usage example"
  print(_todo)
end

--@api-stub: MapBlock:getWidthInSegments
-- Returns the number of segments along the width.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapBlock:getWidthInSegments
  local _todo = "TODO: write a real MapBlock:getWidthInSegments usage example"
  print(_todo)
end

--@api-stub: MapBlock:getHeightInSegments
-- Returns the number of segments along the height.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapBlock:getHeightInSegments
  local _todo = "TODO: write a real MapBlock:getHeightInSegments usage example"
  print(_todo)
end

--@api-stub: MapBlock:setName
-- Sets the human-readable name of this block.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapBlock:setName
  local _todo = "TODO: write a real MapBlock:setName usage example"
  print(_todo)
end

--@api-stub: MapBlock:getName
-- Returns the name of this block.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapBlock:getName
  local _todo = "TODO: write a real MapBlock:getName usage example"
  print(_todo)
end

--@api-stub: MapBlock:setWeight
-- Sets the placement weight.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapBlock:setWeight
  local _todo = "TODO: write a real MapBlock:setWeight usage example"
  print(_todo)
end

--@api-stub: MapBlock:getWeight
-- Returns the placement weight.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapBlock:getWeight
  local _todo = "TODO: write a real MapBlock:getWeight usage example"
  print(_todo)
end

-- ── MapGroup methods ──

--@api-stub: MapGroup:addBlock
-- Adds a block to this group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapGroup:addBlock
  local _todo = "TODO: write a real MapGroup:addBlock usage example"
  print(_todo)
end

--@api-stub: MapGroup:getBlockCount
-- Returns the number of blocks in this group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapGroup:getBlockCount
  local _todo = "TODO: write a real MapGroup:getBlockCount usage example"
  print(_todo)
end

--@api-stub: MapGroup:removeBlock
-- Removes a block by 1-based index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapGroup:removeBlock
  local _todo = "TODO: write a real MapGroup:removeBlock usage example"
  print(_todo)
end

--@api-stub: MapGroup:getName
-- Returns the name of this group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapGroup:getName
  local _todo = "TODO: write a real MapGroup:getName usage example"
  print(_todo)
end

--@api-stub: MapGroup:addScript
-- Adds a MapScript to this group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapGroup:addScript
  local _todo = "TODO: write a real MapGroup:addScript usage example"
  print(_todo)
end

--@api-stub: MapGroup:getScriptCount
-- Returns the number of scripts in this group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapGroup:getScriptCount
  local _todo = "TODO: write a real MapGroup:getScriptCount usage example"
  print(_todo)
end

-- ── MapScript methods ──

--@api-stub: MapScript:getStepCount
-- Returns the number of steps in this script.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapScript:getStepCount
  local _todo = "TODO: write a real MapScript:getStepCount usage example"
  print(_todo)
end

--@api-stub: MapScript:addStep
-- Appends a generation step from a step-definition table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/tilemap_api.rs and docs/specs/tilemap.md).
do  -- TODO: MapScript:addStep
  local _todo = "TODO: write a real MapScript:addStep usage example"
  print(_todo)
end

