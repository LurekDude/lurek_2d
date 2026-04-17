-- content/examples/tilemap.lua
-- Lurek2D lurek.tilemap API Reference
-- Run with: cargo run -- content/examples/tilemap
--
-- Scenario: A top-down RPG with a multi-layer overworld, hex grid combat arenas,
-- isometric town views, chunk-streamed large maps, auto-tiling for terrain transitions,
-- procedural dungeon generation, and a TMX-imported village map.

print("=== lurek.tilemap — RPG Tilemap Systems ===\n")

-- =============================================================================
-- TileSet & TileMap Creation (module-level functions)
-- =============================================================================

-- ---- Stub: lurek.tilemap.newTileSet ---------------------------------------
--@api-stub: lurek.tilemap.newTileSet
-- Create a tileset from a sprite sheet. Defines the tile dimensions and layout.
local overworld_ts = lurek.tilemap.newTileSet("assets/tilesets/overworld.png", {
    tile_width = 16,
    tile_height = 16,
    columns = 20,
    spacing = 0,
    margin = 0
})
print("overworld tileset: 16x16 tiles, 20 columns")

-- ---- Stub: lurek.tilemap.newTileMap ---------------------------------------
--@api-stub: lurek.tilemap.newTileMap
-- Create a tilemap with a fixed grid size. Layers are added separately.
local overworld = lurek.tilemap.newTileMap(100, 80, 16, 16)
print("overworld map: 100x80 tiles at 16x16 pixels each")

-- ---- Stub: lurek.tilemap.newAutoTileSheet ---------------------------------
--@api-stub: lurek.tilemap.newAutoTileSheet
-- Auto-tile sheets handle terrain transitions automatically.
-- The sheet contains all 47 (or 16) tile variants for a terrain type.
local grass_auto = lurek.tilemap.newAutoTileSheet("assets/tilesets/grass_autotile.png", {
    tile_width = 16,
    tile_height = 16,
    layout = "blob47"  -- 47-tile blob pattern (Wang tiles)
})
print("grass auto-tile: blob47 layout (47 transition variants)")

-- ---- Stub: lurek.tilemap.newChunkMap --------------------------------------
--@api-stub: lurek.tilemap.newChunkMap
-- Chunk maps load/unload regions dynamically for large worlds.
local world_chunks = lurek.tilemap.newChunkMap({
    chunk_width = 32,
    chunk_height = 32,
    tile_width = 16,
    tile_height = 16
})
print("chunk map: 32x32 tile chunks, streaming loader")

-- ---- Stub: lurek.tilemap.newIsoMap ----------------------------------------
--@api-stub: lurek.tilemap.newIsoMap
-- Isometric map for town views or tactical combat arenas.
local town_iso = lurek.tilemap.newIsoMap({
    width = 20,
    height = 20,
    tile_width = 64,
    tile_height = 32
})
print("isometric town: 20x20 tiles at 64x32 diamond projection")

-- ---- Stub: lurek.tilemap.newMapBlock --------------------------------------
--@api-stub: lurek.tilemap.newMapBlock
-- Map blocks are reusable rectangular tile patterns for procedural assembly.
local room_block = lurek.tilemap.newMapBlock(8, 6, {
    tile_width = 16,
    tile_height = 16,
    layers = 1
})
print("map block: 8x6 room template for dungeon assembly")

-- ---- Stub: lurek.tilemap.newMapGroup --------------------------------------
--@api-stub: lurek.tilemap.newMapGroup
-- Map groups collect map blocks for procedural map generation.
local dungeon_group = lurek.tilemap.newMapGroup("dungeon_rooms")
print("map group: 'dungeon_rooms' for procedural assembly")

-- ---- Stub: lurek.tilemap.newMapScript -------------------------------------
--@api-stub: lurek.tilemap.newMapScript
-- Map scripts define step-by-step generation sequences.
local gen_script = lurek.tilemap.newMapScript()
print("map generation script created")

-- ---- Stub: lurek.tilemap.newMapGen ----------------------------------------
--@api-stub: lurek.tilemap.newMapGen
-- Procedural map generator that assembles blocks into complete maps.
local map_gen = lurek.tilemap.newMapGen({
    width = 64,
    height = 64,
    seed = 42
})
print("map generator: 64x64, seed=42")

-- =============================================================================
-- File Import (module-level functions)
-- =============================================================================

-- ---- Stub: lurek.tilemap.loadTMX ------------------------------------------
--@api-stub: lurek.tilemap.loadTMX
-- Load a Tiled editor (.tmx) file — layers, tilesets, objects all imported.
local village = lurek.tilemap.loadTMX("assets/maps/village.tmx")
print("TMX loaded: village map (Tiled editor format)")

-- ---- Stub: lurek.tilemap.fromLDtk ----------------------------------------
--@api-stub: lurek.tilemap.fromLDtk
-- Load an LDtk map project — modern level editor with auto-tiling support.
local ldtk_map = lurek.tilemap.fromLDtk("assets/maps/dungeon.ldtk")
print("LDtk loaded: dungeon project")

-- ---- Stub: lurek.tilemap.newLargeMapRenderer ------------------------------
--@api-stub: lurek.tilemap.newLargeMapRenderer
-- Optimised renderer for very large maps — caches visible chunks on the GPU.
local large_renderer = lurek.tilemap.newLargeMapRenderer(overworld, {
    chunk_size = 16,
    max_cached_chunks = 64
})
print("large map renderer: 16-tile chunks, 64 cache slots")

-- =============================================================================
-- Coordinate Conversions — Isometric (module-level functions)
-- =============================================================================

-- ---- Stub: lurek.tilemap.toScreenIso --------------------------------------
--@api-stub: lurek.tilemap.toScreenIso
-- Convert tile (col, row) to screen pixel position in isometric projection.
local sx, sy = lurek.tilemap.toScreenIso(5, 3, 64, 32)
print("iso tile (5,3) -> screen (" .. sx .. ", " .. sy .. ")")

-- ---- Stub: lurek.tilemap.fromScreenIso ------------------------------------
--@api-stub: lurek.tilemap.fromScreenIso
-- Reverse: screen position back to tile coordinates (e.g. for mouse picking).
local tx, ty = lurek.tilemap.fromScreenIso(sx, sy, 64, 32)
print("screen -> iso tile (" .. tx .. ", " .. ty .. ")")

-- ---- Stub: lurek.tilemap.isoRotate ---------------------------------------
--@api-stub: lurek.tilemap.isoRotate
-- Rotate tile coordinates in isometric space by 90-degree increments.
local rx, ry = lurek.tilemap.isoRotate(5, 3, 1)  -- 1 = 90 degrees CW
print("iso rotated (5,3) by 90°: (" .. rx .. ", " .. ry .. ")")

-- ---- Stub: lurek.tilemap.isoDirectionName ---------------------------------
--@api-stub: lurek.tilemap.isoDirectionName
-- Get a human-readable name for an isometric direction index.
print("direction 0: " .. lurek.tilemap.isoDirectionName(0))

-- ---- Stub: lurek.tilemap.isoDirectionFromAngle ----------------------------
--@api-stub: lurek.tilemap.isoDirectionFromAngle
-- Map an angle (radians) to the closest isometric direction index.
local dir = lurek.tilemap.isoDirectionFromAngle(math.rad(45))
print("45 degrees -> iso direction: " .. dir)

-- =============================================================================
-- Coordinate Conversions — Hex Grid (module-level functions)
-- =============================================================================

-- ---- Stub: lurek.tilemap.toScreenHex --------------------------------------
--@api-stub: lurek.tilemap.toScreenHex
-- Convert hex axial coordinates (q, r) to screen pixel position.
local hx, hy = lurek.tilemap.toScreenHex(3, 2, 32)
print("hex (3,2) -> screen (" .. hx .. ", " .. hy .. ")")

-- ---- Stub: lurek.tilemap.fromScreenHex ------------------------------------
--@api-stub: lurek.tilemap.fromScreenHex
-- Screen position to hex coordinates (mouse picking on hex grid).
local hq, hr = lurek.tilemap.fromScreenHex(hx, hy, 32)
print("screen -> hex (" .. hq .. ", " .. hr .. ")")

-- ---- Stub: lurek.tilemap.hexNeighbors -------------------------------------
--@api-stub: lurek.tilemap.hexNeighbors
-- Get all 6 neighboring hex cells. Returns array of {q, r} pairs.
local neighbors = lurek.tilemap.hexNeighbors(3, 2)
print("hex (3,2) neighbors: " .. #neighbors .. " cells")

-- ---- Stub: lurek.tilemap.hexDistance --------------------------------------
--@api-stub: lurek.tilemap.hexDistance
-- Manhattan distance between two hex cells.
local hdist = lurek.tilemap.hexDistance(0, 0, 3, 2)
print("hex distance (0,0) -> (3,2): " .. hdist)

-- ---- Stub: lurek.tilemap.hexRound -----------------------------------------
--@api-stub: lurek.tilemap.hexRound
-- Round fractional hex coordinates to the nearest hex cell.
local rq, rr = lurek.tilemap.hexRound(2.7, 1.3)
print("hex round (2.7, 1.3) -> (" .. rq .. ", " .. rr .. ")")

-- ---- Stub: lurek.tilemap.hexLine ------------------------------------------
--@api-stub: lurek.tilemap.hexLine
-- Draw a line between two hex cells — returns all cells the line passes through.
local line_cells = lurek.tilemap.hexLine(0, 0, 5, 3)
print("hex line (0,0) -> (5,3): " .. #line_cells .. " cells")

-- ---- Stub: lurek.tilemap.hexRing ------------------------------------------
--@api-stub: lurek.tilemap.hexRing
-- Get all cells at exactly N distance from center (a ring).
local ring = lurek.tilemap.hexRing(3, 2, 2)
print("hex ring radius 2 around (3,2): " .. #ring .. " cells")

-- ---- Stub: lurek.tilemap.hexSpiral ----------------------------------------
--@api-stub: lurek.tilemap.hexSpiral
-- Spiral outward from center up to radius N.
local spiral = lurek.tilemap.hexSpiral(3, 2, 3)
print("hex spiral radius 3: " .. #spiral .. " cells (including center)")

-- ---- Stub: lurek.tilemap.hexArea ------------------------------------------
--@api-stub: lurek.tilemap.hexArea
-- All cells within N distance from center (filled circle).
local area = lurek.tilemap.hexArea(3, 2, 2)
print("hex area radius 2: " .. #area .. " cells")

-- ---- Stub: lurek.tilemap.hexRotate ----------------------------------------
--@api-stub: lurek.tilemap.hexRotate
-- Rotate a hex vector by 60-degree increments around origin.
local rotq, rotr = lurek.tilemap.hexRotate(1, -2, 1)  -- 1 step CW
print("hex rotate (1,-2) by 60°: (" .. rotq .. ", " .. rotr .. ")")

-- ---- Stub: lurek.tilemap.hexReflect ---------------------------------------
--@api-stub: lurek.tilemap.hexReflect
-- Reflect hex coordinates across an axis.
local refq, refr = lurek.tilemap.hexReflect(3, -1, "q")
print("hex reflect (3,-1) across q-axis: (" .. refq .. ", " .. refr .. ")")

-- =============================================================================
-- TileSet Object Methods
-- =============================================================================

-- ---- Stub: TileSet:getFirstGid --------------------------------------------
--@api-stub: TileSet:getFirstGid
print("tileset first GID: " .. overworld_ts:getFirstGid())

-- ---- Stub: TileSet:getTileCount -------------------------------------------
--@api-stub: TileSet:getTileCount
print("tileset tile count: " .. overworld_ts:getTileCount())

-- ---- Stub: TileSet:getColumns ---------------------------------------------
--@api-stub: TileSet:getColumns
print("tileset columns: " .. overworld_ts:getColumns())

-- ---- Stub: TileSet:getTileWidth -------------------------------------------
--@api-stub: TileSet:getTileWidth
print("tile width: " .. overworld_ts:getTileWidth() .. "px")

-- ---- Stub: TileSet:getTileHeight ------------------------------------------
--@api-stub: TileSet:getTileHeight
print("tile height: " .. overworld_ts:getTileHeight() .. "px")

-- ---- Stub: TileSet:getTileDimensions --------------------------------------
--@api-stub: TileSet:getTileDimensions
local tw, th = overworld_ts:getTileDimensions()
print("tile dimensions: " .. tw .. "x" .. th)

-- ---- Stub: TileSet:getSpacing ---------------------------------------------
--@api-stub: TileSet:getSpacing
print("tileset spacing: " .. overworld_ts:getSpacing() .. "px")

-- ---- Stub: TileSet:getMargin ----------------------------------------------
--@api-stub: TileSet:getMargin
print("tileset margin: " .. overworld_ts:getMargin() .. "px")

-- ---- Stub: TileSet:getQuad ------------------------------------------------
--@api-stub: TileSet:getQuad
-- Get the texture quad (UV region) for a specific tile index.
local quad = overworld_ts:getQuad(5)
print("tile 5 quad: " .. tostring(quad))

-- ---- Stub: TileSet:getAnimation -------------------------------------------
--@api-stub: TileSet:getAnimation
-- Get animation frames for an animated tile (e.g. water, torch).
local anim = overworld_ts:getAnimation(42)
if anim then
    print("tile 42 animation: " .. #anim .. " frames")
else
    print("tile 42: no animation")
end

-- ---- Stub: TileSet:setSolid -----------------------------------------------
--@api-stub: TileSet:setSolid
-- Mark specific tiles as solid for collision detection.
overworld_ts:setSolid(1, true)   -- wall tile
overworld_ts:setSolid(15, true)  -- rock tile
print("tiles 1, 15 marked solid")

-- ---- Stub: TileSet:isSolid -----------------------------------------------
--@api-stub: TileSet:isSolid
print("tile 1 solid: " .. tostring(overworld_ts:isSolid(1)))
print("tile 0 solid: " .. tostring(overworld_ts:isSolid(0)))

-- =============================================================================
-- TileMap Object Methods — Layer management and tile access
-- =============================================================================

-- ---- Stub: TileMap:addTileSet ---------------------------------------------
--@api-stub: TileMap:addTileSet
overworld:addTileSet(overworld_ts)
print("overworld tileset added to map")

-- ---- Stub: TileMap:getTileSetCount ----------------------------------------
--@api-stub: TileMap:getTileSetCount
print("tilemap tilesets: " .. overworld:getTileSetCount())

-- ---- Stub: TileMap:getTileSet ---------------------------------------------
--@api-stub: TileMap:getTileSet
local ts_ref = overworld:getTileSet(0)
print("tileset 0 retrieved: " .. tostring(ts_ref))

-- ---- Stub: TileMap:addLayer -----------------------------------------------
--@api-stub: TileMap:addLayer
-- Add layers: ground, decoration, collision overlay.
overworld:addLayer("ground")
overworld:addLayer("decoration")
overworld:addLayer("collision")
print("3 layers added: ground, decoration, collision")

-- ---- Stub: TileMap:getLayerCount ------------------------------------------
--@api-stub: TileMap:getLayerCount
print("layer count: " .. overworld:getLayerCount())

-- ---- Stub: TileMap:getLayerName -------------------------------------------
--@api-stub: TileMap:getLayerName
print("layer 0: " .. overworld:getLayerName(0))
print("layer 1: " .. overworld:getLayerName(1))

-- ---- Stub: TileMap:getLayerVisible ----------------------------------------
--@api-stub: TileMap:getLayerVisible
print("ground visible: " .. tostring(overworld:getLayerVisible(0)))

-- ---- Stub: TileMap:getLayerColor ------------------------------------------
--@api-stub: TileMap:getLayerColor
local lr, lg, lb, la = overworld:getLayerColor(0)
print("ground layer color: (" .. tostring(lr) .. "," .. tostring(lg) .. "," .. tostring(lb) .. ")")

-- ---- Stub: TileMap:getLayerOffset -----------------------------------------
--@api-stub: TileMap:getLayerOffset
local ox, oy = overworld:getLayerOffset(1)
print("decoration offset: (" .. tostring(ox) .. ", " .. tostring(oy) .. ")")

-- ---- Stub: TileMap:getLayerParallax ---------------------------------------
--@api-stub: TileMap:getLayerParallax
-- Parallax factor for background layers that scroll slower than the camera.
local px, py = overworld:getLayerParallax(0)
print("ground parallax: (" .. tostring(px) .. ", " .. tostring(py) .. ")")

-- ---- Stub: TileMap:getTile ------------------------------------------------
--@api-stub: TileMap:getTile
-- Read a tile ID at a specific position and layer.
local tile_id = overworld:getTile(0, 10, 5)  -- layer 0, col 10, row 5
print("tile at (10,5) layer 0: " .. tostring(tile_id))

-- ---- Stub: TileMap:clearTile ----------------------------------------------
--@api-stub: TileMap:clearTile
overworld:clearTile(0, 10, 5)
print("tile at (10,5) layer 0 cleared")

-- ---- Stub: TileMap:fill ---------------------------------------------------
--@api-stub: TileMap:fill
-- Fill an entire layer with a single tile ID. Good for base terrain.
overworld:fill(0, 3)  -- layer 0, tile ID 3 (grass)
print("ground layer filled with grass (tile 3)")

-- ---- Stub: TileMap:getViewport --------------------------------------------
--@api-stub: TileMap:getViewport
local vx, vy, vw, vh = overworld:getViewport()
print("viewport: (" .. tostring(vx) .. "," .. tostring(vy) .. "," .. tostring(vw) .. "," .. tostring(vh) .. ")")

-- ---- Stub: TileMap:update -------------------------------------------------
--@api-stub: TileMap:update
-- Update tile animations (water ripple, torch flicker).
overworld:update(0.016)
print("tilemap updated (16ms frame)")

-- ---- Stub: TileMap:worldToTile --------------------------------------------
--@api-stub: TileMap:worldToTile
-- Convert pixel position to tile coordinates for mouse picking.
local tx2, ty2 = overworld:worldToTile(256, 128)
print("world (256,128) -> tile (" .. tostring(tx2) .. ", " .. tostring(ty2) .. ")")

-- ---- Stub: TileMap:tileToWorld --------------------------------------------
--@api-stub: TileMap:tileToWorld
-- Convert tile coordinates to pixel position for placing sprites.
local wx, wy = overworld:tileToWorld(10, 8)
print("tile (10,8) -> world (" .. tostring(wx) .. ", " .. tostring(wy) .. ")")

-- ---- Stub: TileMap:getTileWidth -------------------------------------------
--@api-stub: TileMap:getTileWidth
print("map tile width: " .. overworld:getTileWidth() .. "px")

-- ---- Stub: TileMap:getTileHeight ------------------------------------------
--@api-stub: TileMap:getTileHeight
print("map tile height: " .. overworld:getTileHeight() .. "px")

-- ---- Stub: TileMap:getTileDimensions --------------------------------------
--@api-stub: TileMap:getTileDimensions
local mtw, mth = overworld:getTileDimensions()
print("map tile dimensions: " .. mtw .. "x" .. mth)

-- ---- Stub: TileMap:getChunkSize -------------------------------------------
--@api-stub: TileMap:getChunkSize
print("tilemap chunk size: " .. tostring(overworld:getChunkSize()))

-- ---- Stub: TileMap:isSolid -----------------------------------------------
--@api-stub: TileMap:isSolid
-- Check if a tile at position is solid (for collision queries).
print("tile (5,3) solid: " .. tostring(overworld:isSolid(5, 3)))

-- ---- Stub: TileMap:getOrientation -----------------------------------------
--@api-stub: TileMap:getOrientation
print("orientation: " .. tostring(overworld:getOrientation()))

-- ---- Stub: TileMap:setOrientation -----------------------------------------
--@api-stub: TileMap:setOrientation
overworld:setOrientation("orthogonal")
print("orientation set to orthogonal")

-- ---- Stub: TileMap:render -------------------------------------------------
--@api-stub: TileMap:render
-- Draw all visible layers. Call inside lurek.render() callback.
overworld:render()
print("tilemap rendered")

-- ---- Stub: TileMap:drawToImage --------------------------------------------
--@api-stub: TileMap:drawToImage
-- Export the full map to an image file for mini-map or debug view.
overworld:drawToImage("output/overworld_preview.png")
print("tilemap exported to PNG")

-- ---- Stub: TileMap:toNavGrid ----------------------------------------------
--@api-stub: TileMap:toNavGrid
-- Generate a navigation grid from solid tiles for pathfinding.
local nav = overworld:toNavGrid()
print("navigation grid generated from tilemap solids")

-- =============================================================================
-- AutoTileSheet Object Methods
-- =============================================================================

-- ---- Stub: AutoTileSheet:getLayout ----------------------------------------
--@api-stub: AutoTileSheet:getLayout
print("auto-tile layout: " .. grass_auto:getLayout())

-- ---- Stub: AutoTileSheet:getTileCount -------------------------------------
--@api-stub: AutoTileSheet:getTileCount
print("auto-tile count: " .. grass_auto:getTileCount())

-- ---- Stub: AutoTileSheet:getTileWidth -------------------------------------
--@api-stub: AutoTileSheet:getTileWidth
print("auto-tile width: " .. grass_auto:getTileWidth() .. "px")

-- ---- Stub: AutoTileSheet:getTileHeight ------------------------------------
--@api-stub: AutoTileSheet:getTileHeight
print("auto-tile height: " .. grass_auto:getTileHeight() .. "px")

-- ---- Stub: AutoTileSheet:getBitmaskForTile ---------------------------------
--@api-stub: AutoTileSheet:getBitmaskForTile
-- Get the bitmask that a specific tile index represents.
local bitmask = grass_auto:getBitmaskForTile(12)
print("auto-tile 12 bitmask: " .. tostring(bitmask))

-- ---- Stub: AutoTileSheet:getTileForBitmask --------------------------------
--@api-stub: AutoTileSheet:getTileForBitmask
-- Reverse lookup: given neighbor bitmask, get the correct tile variant.
local auto_idx = grass_auto:getTileForBitmask(0xFF)
print("bitmask 0xFF (all neighbors) -> tile: " .. tostring(auto_idx))

-- ---- Stub: AutoTileSheet:getQuad ------------------------------------------
--@api-stub: AutoTileSheet:getQuad
local auto_quad = grass_auto:getQuad(0)
print("auto-tile 0 quad: " .. tostring(auto_quad))

-- =============================================================================
-- ChunkMap Object Methods — streaming tile access
-- =============================================================================

-- ---- Stub: ChunkMap:loadChunk ---------------------------------------------
--@api-stub: ChunkMap:loadChunk
-- Explicitly load a chunk by its chunk coordinates.
world_chunks:loadChunk(0, 0)
world_chunks:loadChunk(1, 0)
print("chunks (0,0) and (1,0) loaded")

-- ---- Stub: ChunkMap:unloadChunk -------------------------------------------
--@api-stub: ChunkMap:unloadChunk
world_chunks:unloadChunk(1, 0)
print("chunk (1,0) unloaded (player moved away)")

-- ---- Stub: ChunkMap:setTile -----------------------------------------------
--@api-stub: ChunkMap:setTile
-- Set a tile using world-space tile coordinates (chunk resolved automatically).
world_chunks:setTile(5, 3, 7)
print("chunk tile (5,3) set to ID 7")

-- ---- Stub: ChunkMap:getTile -----------------------------------------------
--@api-stub: ChunkMap:getTile
print("chunk tile (5,3): " .. tostring(world_chunks:getTile(5, 3)))

-- ---- Stub: ChunkMap:clearTile ---------------------------------------------
--@api-stub: ChunkMap:clearTile
world_chunks:clearTile(5, 3)
print("chunk tile (5,3) cleared")

-- ---- Stub: ChunkMap:getChunkSize ------------------------------------------
--@api-stub: ChunkMap:getChunkSize
print("chunk size: " .. tostring(world_chunks:getChunkSize()) .. " tiles")

-- ---- Stub: ChunkMap:getLoadedChunks ---------------------------------------
--@api-stub: ChunkMap:getLoadedChunks
local loaded = world_chunks:getLoadedChunks()
print("loaded chunks: " .. #loaded)

-- ---- Stub: ChunkMap:chunkTileRange ----------------------------------------
--@api-stub: ChunkMap:chunkTileRange
-- Get the world-space tile range covered by a specific chunk.
local cmin_x, cmin_y, cmax_x, cmax_y = world_chunks:chunkTileRange(0, 0)
print("chunk (0,0) tiles: (" .. cmin_x .. "," .. cmin_y .. ") to (" .. cmax_x .. "," .. cmax_y .. ")")

-- =============================================================================
-- LargeMapRenderer Object Methods
-- =============================================================================

-- ---- Stub: LargeMapRenderer:setTile ---------------------------------------
--@api-stub: LargeMapRenderer:setTile
large_renderer:setTile(50, 40, 12)
print("large renderer: tile (50,40) set to 12")

-- ---- Stub: LargeMapRenderer:getTile ---------------------------------------
--@api-stub: LargeMapRenderer:getTile
print("large renderer tile (50,40): " .. tostring(large_renderer:getTile(50, 40)))

-- ---- Stub: LargeMapRenderer:getMapSize ------------------------------------
--@api-stub: LargeMapRenderer:getMapSize
local lmw, lmh = large_renderer:getMapSize()
print("large map size: " .. lmw .. "x" .. lmh)

-- ---- Stub: LargeMapRenderer:setChunkSize ----------------------------------
--@api-stub: LargeMapRenderer:setChunkSize
large_renderer:setChunkSize(16)
print("large renderer chunk size: 16")

-- ---- Stub: LargeMapRenderer:getChunkSize ----------------------------------
--@api-stub: LargeMapRenderer:getChunkSize
print("large renderer chunk size: " .. tostring(large_renderer:getChunkSize()))

-- ---- Stub: LargeMapRenderer:invalidateChunk -------------------------------
--@api-stub: LargeMapRenderer:invalidateChunk
-- Force a chunk to be re-rendered (after modifying tiles in it).
large_renderer:invalidateChunk(3, 2)
print("chunk (3,2) invalidated — will re-render next frame")

-- ---- Stub: LargeMapRenderer:invalidateAll ---------------------------------
--@api-stub: LargeMapRenderer:invalidateAll
large_renderer:invalidateAll()
print("all chunks invalidated (tileset changed)")

-- ---- Stub: LargeMapRenderer:getVisibleChunks ------------------------------
--@api-stub: LargeMapRenderer:getVisibleChunks
print("visible chunks: " .. tostring(large_renderer:getVisibleChunks()))

-- ---- Stub: LargeMapRenderer:getTotalChunks --------------------------------
--@api-stub: LargeMapRenderer:getTotalChunks
print("total chunks: " .. tostring(large_renderer:getTotalChunks()))

-- ---- Stub: LargeMapRenderer:setCamera -------------------------------------
--@api-stub: LargeMapRenderer:setCamera
-- Set the camera position for culling — only visible chunks are drawn.
large_renderer:setCamera(800, 600)
print("large renderer camera at (800, 600)")

-- ---- Stub: LargeMapRenderer:setViewport -----------------------------------
--@api-stub: LargeMapRenderer:setViewport
large_renderer:setViewport(0, 0, 800, 600)
print("large renderer viewport: 800x600")

-- ---- Stub: LargeMapRenderer:setLodEnabled ---------------------------------
--@api-stub: LargeMapRenderer:setLodEnabled
-- Level-of-detail: far-away chunks use lower-res rendering.
large_renderer:setLodEnabled(true)
print("LOD enabled (distant chunks render at lower detail)")

-- ---- Stub: LargeMapRenderer:isLodEnabled ----------------------------------
--@api-stub: LargeMapRenderer:isLodEnabled
print("LOD enabled: " .. tostring(large_renderer:isLodEnabled()))

-- ---- Stub: LargeMapRenderer:setLodThresholds ------------------------------
--@api-stub: LargeMapRenderer:setLodThresholds
-- Distance thresholds for LOD levels.
large_renderer:setLodThresholds({ 512, 1024, 2048 })
print("LOD thresholds: 512, 1024, 2048 pixels from camera")

-- ---- Stub: LargeMapRenderer:setTilesetColumns -----------------------------
--@api-stub: LargeMapRenderer:setTilesetColumns
large_renderer:setTilesetColumns(20)
print("large renderer tileset columns: 20")

-- ---- Stub: LargeMapRenderer:getTilesetColumns -----------------------------
--@api-stub: LargeMapRenderer:getTilesetColumns
print("tileset columns: " .. tostring(large_renderer:getTilesetColumns()))

-- =============================================================================
-- IsoMap Object Methods — isometric map with levels
-- =============================================================================

-- ---- Stub: IsoMap:addLevel ------------------------------------------------
--@api-stub: IsoMap:addLevel
-- Add vertical levels for multi-story buildings.
town_iso:addLevel()
town_iso:addLevel()
print("2 levels added to isometric town (ground + 1st floor)")

-- ---- Stub: IsoMap:getLevelCount -------------------------------------------
--@api-stub: IsoMap:getLevelCount
print("iso levels: " .. town_iso:getLevelCount())

-- ---- Stub: IsoMap:setLevelVisible -----------------------------------------
--@api-stub: IsoMap:setLevelVisible
-- Toggle level visibility (show/hide upper floors).
town_iso:setLevelVisible(1, false)
print("level 1 hidden (roof removed for top-down view)")

-- ---- Stub: IsoMap:isLevelVisible ------------------------------------------
--@api-stub: IsoMap:isLevelVisible
print("level 0 visible: " .. tostring(town_iso:isLevelVisible(0)))
print("level 1 visible: " .. tostring(town_iso:isLevelVisible(1)))

-- ---- Stub: IsoMap:fillLevel -----------------------------------------------
--@api-stub: IsoMap:fillLevel
town_iso:fillLevel(0, 5)  -- Fill ground level with tile 5 (cobblestone)
print("ground level filled with cobblestone (tile 5)")

-- ---- Stub: IsoMap:setOrigin -----------------------------------------------
--@api-stub: IsoMap:setOrigin
-- Set the world-space origin of the isometric grid.
town_iso:setOrigin(400, 100)
print("iso origin: (400, 100)")

-- ---- Stub: IsoMap:getWidth ------------------------------------------------
--@api-stub: IsoMap:getWidth
print("iso width: " .. town_iso:getWidth() .. " tiles")

-- ---- Stub: IsoMap:getHeight -----------------------------------------------
--@api-stub: IsoMap:getHeight
print("iso height: " .. town_iso:getHeight() .. " tiles")

-- ---- Stub: IsoMap:getTileWidth --------------------------------------------
--@api-stub: IsoMap:getTileWidth
print("iso tile width: " .. town_iso:getTileWidth() .. "px")

-- ---- Stub: IsoMap:getTileHeight -------------------------------------------
--@api-stub: IsoMap:getTileHeight
print("iso tile height: " .. town_iso:getTileHeight() .. "px")

-- ---- Stub: IsoMap:getLevelHeight -------------------------------------------
--@api-stub: IsoMap:getLevelHeight
print("iso level height: " .. tostring(town_iso:getLevelHeight()) .. "px")

-- ---- Stub: IsoMap:tileToScreen --------------------------------------------
--@api-stub: IsoMap:tileToScreen
local isx, isy = town_iso:tileToScreen(5, 3)
print("iso tile (5,3) -> screen (" .. tostring(isx) .. ", " .. tostring(isy) .. ")")

-- ---- Stub: IsoMap:screenToTile --------------------------------------------
--@api-stub: IsoMap:screenToTile
local itx, ity = town_iso:screenToTile(isx, isy)
print("screen -> iso tile (" .. tostring(itx) .. ", " .. tostring(ity) .. ")")

-- ---- Stub: IsoMap:getPartCount --------------------------------------------
--@api-stub: IsoMap:getPartCount
print("iso parts: " .. tostring(town_iso:getPartCount()))

-- ---- Stub: IsoMap:getPartOrder --------------------------------------------
--@api-stub: IsoMap:getPartOrder
local order = town_iso:getPartOrder()
print("iso part order: " .. tostring(order))

-- ---- Stub: IsoMap:setPartOrder --------------------------------------------
--@api-stub: IsoMap:setPartOrder
-- Change rendering order for depth-sorting control.
town_iso:setPartOrder("back-to-front")
print("iso render order: back-to-front")

-- =============================================================================
-- MapBlock Object Methods — tile pattern templates
-- =============================================================================

-- ---- Stub: MapBlock:getTile -----------------------------------------------
--@api-stub: MapBlock:getTile
print("block tile (0,0): " .. tostring(room_block:getTile(0, 0)))

-- ---- Stub: MapBlock:getSide -----------------------------------------------
--@api-stub: MapBlock:getSide
-- Get the tile pattern along a specific side for block-matching.
local side = room_block:getSide("north")
print("block north side: " .. tostring(side))

-- ---- Stub: MapBlock:getWidth ----------------------------------------------
--@api-stub: MapBlock:getWidth
print("block width: " .. room_block:getWidth())

-- ---- Stub: MapBlock:getHeight ---------------------------------------------
--@api-stub: MapBlock:getHeight
print("block height: " .. room_block:getHeight())

-- ---- Stub: MapBlock:getDimensions -----------------------------------------
--@api-stub: MapBlock:getDimensions
local bw, bh = room_block:getDimensions()
print("block dimensions: " .. bw .. "x" .. bh)

-- ---- Stub: MapBlock:getLayerCount -----------------------------------------
--@api-stub: MapBlock:getLayerCount
print("block layers: " .. room_block:getLayerCount())

-- ---- Stub: MapBlock:getSegmentSize ----------------------------------------
--@api-stub: MapBlock:getSegmentSize
print("block segment size: " .. tostring(room_block:getSegmentSize()))

-- ---- Stub: MapBlock:getWidthInSegments ------------------------------------
--@api-stub: MapBlock:getWidthInSegments
print("block width in segments: " .. tostring(room_block:getWidthInSegments()))

-- ---- Stub: MapBlock:getHeightInSegments -----------------------------------
--@api-stub: MapBlock:getHeightInSegments
print("block height in segments: " .. tostring(room_block:getHeightInSegments()))

-- ---- Stub: MapBlock:setName -----------------------------------------------
--@api-stub: MapBlock:setName
room_block:setName("entrance_hall")
print("block named: entrance_hall")

-- ---- Stub: MapBlock:getName -----------------------------------------------
--@api-stub: MapBlock:getName
print("block name: " .. room_block:getName())

-- ---- Stub: MapBlock:setWeight ---------------------------------------------
--@api-stub: MapBlock:setWeight
-- Higher weight = more likely to be chosen by the map generator.
room_block:setWeight(2.0)
print("block weight: 2.0 (appears twice as often)")

-- ---- Stub: MapBlock:getWeight ---------------------------------------------
--@api-stub: MapBlock:getWeight
print("block weight: " .. tostring(room_block:getWeight()))

-- =============================================================================
-- MapGroup Object Methods — block collections for generation
-- =============================================================================

-- ---- Stub: MapGroup:addBlock ----------------------------------------------
--@api-stub: MapGroup:addBlock
dungeon_group:addBlock(room_block)
print("entrance_hall added to dungeon group")

-- ---- Stub: MapGroup:getBlockCount -----------------------------------------
--@api-stub: MapGroup:getBlockCount
print("blocks in group: " .. dungeon_group:getBlockCount())

-- ---- Stub: MapGroup:removeBlock -------------------------------------------
--@api-stub: MapGroup:removeBlock
dungeon_group:removeBlock(0)
print("block 0 removed from group")

-- ---- Stub: MapGroup:getName -----------------------------------------------
--@api-stub: MapGroup:getName
print("group name: " .. dungeon_group:getName())

-- ---- Stub: MapGroup:addScript ---------------------------------------------
--@api-stub: MapGroup:addScript
dungeon_group:addScript(gen_script)
print("generation script attached to group")

-- ---- Stub: MapGroup:getScriptCount ----------------------------------------
--@api-stub: MapGroup:getScriptCount
print("group scripts: " .. dungeon_group:getScriptCount())

-- =============================================================================
-- MapScript Object Methods — generation step sequences
-- =============================================================================

-- ---- Stub: MapScript:addStep ----------------------------------------------
--@api-stub: MapScript:addStep
-- Add generation steps: each step transforms the map in sequence.
gen_script:addStep({ type = "fill", tile = 1 })
gen_script:addStep({ type = "carve_rooms", count = 8, min_size = 4, max_size = 10 })
gen_script:addStep({ type = "connect_rooms", algorithm = "corridors" })
print("3 generation steps added: fill, carve, connect")

-- ---- Stub: MapScript:getStepCount -----------------------------------------
--@api-stub: MapScript:getStepCount
print("generation steps: " .. gen_script:getStepCount())

print("\n-- tilemap.lua example complete --")
