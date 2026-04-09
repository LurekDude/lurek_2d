-- examples/tilemap.lua
-- lurek.tilemap — Tile-based map authoring: TileMap, TileSet, AutoTileSheet,
-- ChunkMap, IsoMap, MapBlock/MapGroup, and coordinate helper functions.

-- ── TileSet ────────────────────────────────────────────────────────────────────

-- newTileSet(firstGid, tileCount, columns, tileWidth, tileHeight, spacing?, margin?)
-- Describes how to slice an atlas texture into individual tile quads.
-- firstGid = 1 means GIDs 1..tileCount are mapped to this set.
local ts = lurek.tilemap.newTileSet(
    1,     -- firstGid
    256,   -- tileCount
    16,    -- columns
    16,    -- tileWidth  (pixels)
    16,    -- tileHeight (pixels)
    0,     -- spacing    (px between tiles in atlas, optional)
    0      -- margin     (px around atlas edge, optional)
)

-- Metadata queries
local first_gid = ts:getFirstGid()         -- 1
local tile_count = ts:getTileCount()       -- 256
local columns = ts:getColumns()            -- 16
local tw, th = ts:getTileDimensions()      -- 16, 16
local spacing = ts:getSpacing()            -- 0
local margin  = ts:getMargin()             -- 0

-- getQuad(localTileId) → x, y, w, h  (0-based local ID)
-- Returns the source rectangle in the atlas for a local tile index.
local qx, qy, qw, qh = ts:getQuad(0)      -- first tile

-- Solid-tile flags (for collision lookup)
ts:setSolid(5, true)             -- tile ID 5 is solid
local is_solid = ts:isSolid(5)  -- true

-- Tile animation — frames table is { {tileId, durationMs}, ... }
ts:setAnimation(10, { {10, 150}, {11, 150}, {12, 150} })
local anim = ts:getAnimation(10)  -- {{10,150},{11,150},{12,150}} or nil

-- 4-bit cardinal autotile rules (N/E/S/W bits 3/2/1/0)
ts:setAutoTileRule("grass", 0b1111, 32)   -- all 4 neighbours → tile 32
ts:setAutoTileRule("grass", 0b0000, 33)   -- isolated → tile 33
local tile_id = ts:getAutoTileId("grass", 0b1111)  -- 32

-- 8-bit directional autotile rules (cardinal + diagonal)
ts:setAutoTileRule8("grass", 0xFF, 40)
local tile_id8 = ts:getAutoTileId8("grass", 0xFF)  -- 40

-- ── TileMap ────────────────────────────────────────────────────────────────────

-- newTileMap(tileWidth, tileHeight, chunkSize?)
-- chunkSize default is 16; controls spatial partitioning resolution.
local map = lurek.tilemap.newTileMap(16, 16, 16)

-- Attach one or more tilesets
map:addTileSet(ts)
local set_count = map:getTileSetCount()  -- 1

-- Add layers
-- addLayer(name, width, height) → 1-based layer index
local layer1 = map:addLayer("ground",  64, 64)  -- returns 1
local layer2 = map:addLayer("objects", 64, 64)  -- returns 2
local lcount = map:getLayerCount()              -- 2
local lname  = map:getLayerName(1)              -- "ground"

-- Layer visibility
map:setLayerVisible(2, false)
local vis = map:getLayerVisible(2)  -- false

-- Layer RGBA tint (default 1,1,1,1)
map:setLayerColor(1, 1.0, 0.9, 0.8, 1.0)
local r, g, b, a = map:getLayerColor(1)

-- Layer pixel offset (for sub-tile parallax micro-offsets)
map:setLayerOffset(1, 0, 0)
local ox, oy = map:getLayerOffset(1)

-- Layer parallax factor (1 = normal scroll with camera)
map:setLayerParallax(2, 0.5, 0.5)  -- scrolls at half speed
local px, py = map:getLayerParallax(2)

-- ── Tile Data ──────────────────────────────────────────────────────────────────
-- NOTE: All x/y/layer arguments are 1-BASED on the Lua side.
-- The engine subtracts 1 internally before addressing the tile buffer.

-- setTile(layer, x, y, gid)  — gid=0 means empty
map:setTile(1, 3, 4, 10)

-- getTile(layer, x, y) → gid
local gid = map:getTile(1, 3, 4)  -- 10

-- clearTile(layer, x, y) — set gid to 0
map:clearTile(1, 3, 4)

-- fill(layer, gid) — flood entire layer
map:fill(1, 1)  -- fill ground layer with tile GID 1

-- Per-tile tint override
map:setTileTint(1, 5, 5, 1.0, 0.5, 0.5, 1.0)  -- red tint at (5,5)

-- ── Viewport / Render Culling ─────────────────────────────────────────────────

-- setViewport(x, y, w, h) — world-space camera window for frustum culling
map:setViewport(0, 0, 800, 600)
local vx, vy, vw, vh = map:getViewport()

-- ── Tile Animations ───────────────────────────────────────────────────────────

-- update(dt) — advance animation timers; call every frame
map:update(1/60)

-- ── Coordinate Conversion ─────────────────────────────────────────────────────

-- worldToTile(wx, wy) → tx, ty  (1-based output)
local tx, ty = map:worldToTile(100, 80)

-- tileToWorld(tx, ty) → wx, wy  (1-based input)
local wx, wy = map:tileToWorld(7, 5)

-- Tile dimension helpers
local tile_w = map:getTileWidth()   -- 16
local tile_h = map:getTileHeight()  -- 16
local tw2, th2 = map:getTileDimensions()
local chunk_sz = map:getChunkSize()  -- 16

-- ── Orientation ───────────────────────────────────────────────────────────────

-- "topdown" (default) or "sideview"
map:setOrientation("topdown")
local orient = map:getOrientation()  -- "topdown"

-- ── Solid Tile Collision ──────────────────────────────────────────────────────

-- isSolid(layer, x, y) → boolean  (1-based)
local solid = map:isSolid(1, 5, 5)

-- rectOverlapsSolid(layer, x, y, w, h) → boolean
-- x, y is world-space top-left corner of the AABB.
local hit = map:rectOverlapsSolid(1, 80, 64, 14, 14)

-- sweepRect(layer, x, y, w, h, dx, dy) → table? or nil
-- Moves an AABB by (dx, dy) and returns the first solid tile hit, or nil.
local result = map:sweepRect(1, 80, 64, 14, 14, 50, 0)
if result then
    -- result.contactX, result.contactY — world-space contact point
    -- result.normalX,  result.normalY  — surface normal
    -- result.tileX,    result.tileY    — 1-based tile that was hit
    -- result.t                         — fraction of motion completed (0..1)
    local safe_x = 80 + 50 * result.t
    local safe_y = 64 + 0  * result.t
end

-- ── AutoTile Application ──────────────────────────────────────────────────────

-- applyAutoTile(layer, typeName) — rewrite entire layer using 4-bit autotile rules
map:applyAutoTile(1, "grass")

-- applyAutoTileAt(layer, x, y, typeName) — rewrite single cell + its 3x3 neighbourhood
map:applyAutoTileAt(1, 5, 5, "grass")

-- applyAutoTile8(layer, typeName) — 8-bit (cardinal + diagonal) full layer pass
map:applyAutoTile8(1, "grass")

-- applyAutoTile8At(layer, x, y, typeName) — 8-bit single cell pass
map:applyAutoTile8At(1, 5, 5, "grass")

-- ── AutoTileSheet ─────────────────────────────────────────────────────────────

-- newAutoTileSheet(tileWidth, tileHeight, layout?)
-- layout: "blob47" (default) | "composite48" | "minimal16"
local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")

local layout    = sheet:getLayout()      -- "blob47"
local stw       = sheet:getTileWidth()   -- 16
local sth       = sheet:getTileHeight()  -- 16
local stcount   = sheet:getTileCount()   -- 47

-- applyToTileSet(tileset, typeName, startGid?)
-- Mass-register autotile rules from sheet into an existing TileSet.
sheet:applyToTileSet(ts, "grass", 1)

-- getBitmaskForTile(idx) → integer — bitmask value at 0-based sheet index
local bitmask = sheet:getBitmaskForTile(0)

-- getTileForBitmask(bitmask) → integer? — reverse lookup
local t_idx = sheet:getTileForBitmask(255)

-- getQuad(idx) → x, y, w, h — atlas source rect for sheet index
local sx, sy, sw2, sh2 = sheet:getQuad(0)

-- ── ChunkMap (infinite tile world) ───────────────────────────────────────────

-- newChunkMap(chunkSize?) → ChunkMap
-- ChunkMap stores tiles in dynamically-allocated 2D chunks.
-- All coordinates in ChunkMap are signed integers (no 1-based offset).
local cmap = lurek.tilemap.newChunkMap(16)  -- 16×16 chunks

-- getTile(x, y) / setTile(x, y, gid) — unbounded world coordinates
cmap:setTile(0, 0, 5)
local tval = cmap:getTile(0, 0)  -- 5

cmap:clearTile(0, 0)

-- fillRect(x0, y0, x1, y1, gid) — fill a rectangular region
cmap:fillRect(-10, -10, 10, 10, 1)

-- Chunk management
cmap:loadChunk(0, 0)             -- pre-allocate chunk at chunk coord (0,0)
cmap:unloadChunk(10, 10)         -- free chunk from memory
local csz = cmap:getChunkSize()  -- 16

-- getLoadedChunks() → {{cx,cy},...}
local loaded = cmap:getLoadedChunks()

-- getChunksInView(vx, vy, vw, vh, tileW, tileH) → {{cx,cy},...}
-- Determine which chunks overlap a camera viewport (world-pixel space).
local visible_chunks = cmap:getChunksInView(0, 0, 800, 600, 16, 16)

-- chunkTileRange(cx, cy) → x0, y0, x1, y1
local x0, y0, x1, y1 = cmap:chunkTileRange(0, 0)

-- ── IsoMap (isometric multi-level) ───────────────────────────────────────────

-- newIsoMap(width, height, tileW, tileH, levelHeight) → IsoMap
-- tileW / tileH is the footprint diamond size in pixels.
local iso_map = lurek.tilemap.newIsoMap(32, 32, 64, 32, 16)

-- Level management (Z layers)
local z1 = iso_map:addLevel()          -- returns 1-based index
local z_count = iso_map:getLevelCount()  -- 1
iso_map:setLevelVisible(1, true)
local lv = iso_map:isLevelVisible(1)   -- true

-- setTilePart(z, x, y, part, gid) — z, x, y are 1-based; part is 0-based
-- IsoMap tiles can have multiple overlapping parts (e.g. floor + wall).
iso_map:setTilePart(1, 5, 5, 0, 10)
local p_gid = iso_map:getTilePart(1, 5, 5, 0)  -- 10

-- fillLevel(z, part, gid)  — fill all cells in a level for a given part
iso_map:fillLevel(1, 0, 1)

-- Screen origin offset
iso_map:setOrigin(400, 100)

-- Dimension queries
local iw = iso_map:getWidth()         -- 32
local ih = iso_map:getHeight()        -- 32
local itw = iso_map:getTileWidth()    -- 64
local ith = iso_map:getTileHeight()   -- 32
local ilh = iso_map:getLevelHeight()  -- 16

-- tileToScreen(tx, ty, tz) → sx, sy — project tile coords to screen pixels
local sx, sy = iso_map:tileToScreen(5, 5, 0)

-- screenToTile(sx, sy) → tx, ty — inverse projection at Z=0
local itx, ity = iso_map:screenToTile(400, 200)

-- ── MapBlock / MapGroup (procedural map assembly) ────────────────────────────

-- newMapBlock(width, height, layers?, segmentSize?) → MapBlock
local block = lurek.tilemap.newMapBlock(8, 8, 2, 4)

-- setTile(layer, x, y, gid) — 1-based layer, x, y
block:setTile(1, 1, 1, 100)
local bg = block:getTile(1, 1, 1)  -- 100

-- Dimension/meta helpers
local bw, bh = block:getDimensions()   -- 8, 8
local bl = block:getLayerCount()       -- 2
local segw = block:getWidthInSegments()  -- 2  (8/4)
local segh = block:getHeightInSegments()
local segsz = block:getSegmentSize()   -- 4
block:setName("room_a")
local bname = block:getName()          -- "room_a"
block:setWeight(2.5)
local wt = block:getWeight()           -- 2.5

-- newMapGroup(name) → MapGroup
local grp = lurek.tilemap.newMapGroup("village")
grp:addBlock(block)
local gc = grp:getBlockCount()    -- 1
grp:removeBlock(1)
grp:addBlock(block)
local gname = grp:getName()       -- "village"

-- ── Coordinate Helpers ────────────────────────────────────────────────────────

-- ── Diamond Isometric ─────────────────────────────────────────────────────────

-- toScreenIso(tx, ty, tileW, tileH) → sx, sy
local isx, isy = lurek.tilemap.toScreenIso(5, 3, 64, 32)

-- fromScreenIso(sx, sy, tileW, tileH) → tx, ty
local itx2, ity2 = lurek.tilemap.fromScreenIso(isx, isy, 64, 32)

-- ── Hexagon (pointy-top, axial coordinates) ───────────────────────────────────

-- toScreenHex(q, r, size) → sx, sy
local hsx, hsy = lurek.tilemap.toScreenHex(2, 1, 30)

-- fromScreenHex(sx, sy, size) → q, r
local hq, hr = lurek.tilemap.fromScreenHex(hsx, hsy, 30)

-- hexNeighbors(q, r) → {{q,r},...} — 6 axial neighbours
local neighbors = lurek.tilemap.hexNeighbors(2, 1)
for _, n in ipairs(neighbors) do
    local nq, nr = n[1], n[2]
end

-- hexDistance(q1, r1, q2, r2) → integer
local dist = lurek.tilemap.hexDistance(0, 0, 3, -1)  -- 3

-- hexRound(q, r) → q, r  — snap fractional coords to nearest hex
local rq, rr = lurek.tilemap.hexRound(1.7, 0.2)  -- 2, 0

-- hexLine(q1, r1, q2, r2) → {{q,r},...}
local line = lurek.tilemap.hexLine(0, 0, 3, -3)

-- hexRing(q, r, radius) → {{q,r},...}
local ring = lurek.tilemap.hexRing(0, 0, 2)  -- 12 cells at distance 2

-- hexSpiral(q, r, radius) → {{q,r},...}
-- Returns cells center outward, ring by ring.
-- (Available if defined in your build.)
local spiral = lurek.tilemap.hexSpiral(0, 0, 2)

-- ─── MapBlock ──────────────────────────────────────────────────────────────────

local side = mapblock:getSide("right", 1)  -- Returns the side connection ID for a segment on a given edge

-- ─── MapGroup ──────────────────────────────────────────────────────────────────

mapgroup:addScript(mapscript)  -- Adds a MapScript to this group
local script_count = mapgroup:getScriptCount()  -- Returns the number of scripts in this group

-- ─── MapScript ─────────────────────────────────────────────────────────────────

mapscript:addStep({})  -- Appends a generation step from a step-definition table
local step_count = mapscript:getStepCount()  -- Returns the number of steps in this script

-- ─── TileMap ───────────────────────────────────────────────────────────────────

local tile_set = tilemap:getTileSet(1)  -- Returns a tileset by 1-based index, or nil if out of range

-- ─── lurek.tilemap ──────────────────────────────────────────────────────────────
local hex_area = lurek.tilemap.hexArea(1, 1, 1)  -- Returns all hex cells within radius distance (filled hex circle) as a table
local hex_reflect = lurek.tilemap.hexReflect(0, 0, 3, 2, "q")  -- Reflects hex coordinates across an axis through the center
local hex_rotate = lurek.tilemap.hexRotate(1, 1, 1, 1, 1)  -- Rotates hex coordinates around a center by steps x 60 degrees clockwise
local iso_direction_from_angle = lurek.tilemap.isoDirectionFromAngle(1.0)  -- Snaps an angle (in radians) to the nearest isometric direction (1-4)
local iso_direction_name = lurek.tilemap.isoDirectionName(1)  -- Returns the name of an isometric direction (1-4)
local iso_rotate = lurek.tilemap.isoRotate(1, 1)  -- Rotates an isometric direction (1-4) clockwise by steps
local load_t_m_x = lurek.tilemap.loadTMX(tmx_xml_string)  -- Parses a TMX XML string and returns a table with map metadata and layers
local map_gen = lurek.tilemap.newMapGen(mapgroup, "rooms", 1)  -- Creates a MapGen from a MapGroup, a preset name or dimensions, and a segment size
local map_script = lurek.tilemap.newMapScript()  -- Creates a new empty MapScript procedural generation script

-- MapGen tile type constants (used with MapScript and dungeon generators)
local t_floor      = lurek.tilemap.FLOOR       -- Tile type: walkable floor (1)
local t_north_wall = lurek.tilemap.NORTH_WALL  -- Tile type: north-facing wall (2)
local t_west_wall  = lurek.tilemap.WEST_WALL   -- Tile type: west-facing wall (3)
local t_object     = lurek.tilemap.OBJECT      -- Tile type: object/decoration cell (4)
