-- content/examples/tilemap.lua
-- lurek.tilemap API examples: orthogonal maps, isometric cities, hex strategy, infinite worlds, procedural dungeons.
-- Run: cargo run -- content/examples/tilemap.lua

-- =============================================================================
-- Constructor Functions
-- =============================================================================

--@api-stub: lurek.tilemap.newTileSet
-- Creates a new tileset from atlas parameters for sprite-sheet based tile rendering
do
  -- A tileset maps tile IDs to atlas rectangles. Parameters:
  --   firstGid    = first global tile ID this set occupies (1-based)
  --   tileCount   = total tiles in the atlas image
  --   columns     = how many tile columns the atlas has
  --   tileWidth/Height = pixel dimensions of one tile cell
  --   spacing     = pixels between tiles in the atlas (optional, default 0)
  --   margin      = pixels around the atlas edge (optional, default 0)
  --
  -- Typical use: one tileset per atlas PNG. Multiple tilesets share a map
  -- by assigning non-overlapping GID ranges.
  local terrain = lurek.tilemap.newTileSet(1, 256, 16, 16, 16, 0, 0)
  lurek.log.info("terrain tileset gid range " .. terrain:getFirstGid() .. ".." .. (terrain:getFirstGid() + terrain:getTileCount() - 1), "tilemap")

  -- A second tileset for props, starting after the terrain range:
  local props = lurek.tilemap.newTileSet(257, 64, 8, 16, 16, 1, 1)
  lurek.log.info("props tileset starts at gid=" .. props:getFirstGid() .. " with " .. props:getColumns() .. " cols", "tilemap")
end

--@api-stub: lurek.tilemap.newTileMap
-- Creates a new empty tilemap with the given tile dimensions
do
  -- tileWidth and tileHeight define the grid cell size in pixels.
  -- chunkSize (optional, default 16) controls internal storage granularity
  -- — larger chunks use more memory per allocation but fewer chunks total.
  -- For a platformer with 16x16 pixel tiles:
  local map = lurek.tilemap.newTileMap(16, 16, 32)
  lurek.log.info("map tile " .. map:getTileWidth() .. "x" .. map:getTileHeight() .. " chunk=" .. map:getChunkSize(), "tilemap")
end

--@api-stub: lurek.tilemap.newAutoTileSheet
-- Creates an auto-tile sheet with a given tile size and layout
do
  -- Auto-tile sheets encode which tile variant to pick based on neighbor bitmasks.
  -- Layouts:
  --   "blob47"      = 47-tile Wang blob set (most common, good coverage)
  --   "composite48" = 48-tile composite (handles corners better)
  --   "minimal16"   = 16-tile minimal (simple, fewer art assets needed)
  --
  -- Use this when you want terrain edges (grass/dirt borders) to pick
  -- the correct corner/edge tile automatically.
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  lurek.log.info("autotile sheet '" .. sheet:getLayout() .. "' has " .. sheet:getTileCount() .. " tiles", "tilemap")
end

--@api-stub: lurek.tilemap.newChunkMap
-- Creates a new infinite chunk-based tile map
do
  -- ChunkMap is for open-world or infinite maps. Tiles are stored in
  -- dynamically-loaded chunks. Unlike TileMap (fixed layers), ChunkMap
  -- supports negative coordinates and on-demand chunk loading.
  --
  -- Typical use: survival sandbox, procedural terrain exploration.
  -- chunkSize (default 16) = tiles per chunk side.
  local world = lurek.tilemap.newChunkMap(32)
  world:setTile(0, 0, 1)
  world:setTile(1000, -500, 7)
  lurek.log.info("loaded " .. #world:getLoadedChunks() .. " chunks after sparse writes", "tilemap")
end

--@api-stub: lurek.tilemap.newIsoMap
-- Creates a new isometric map with the given dimensions and tile geometry
do
  -- IsoMap renders diamond-shaped tiles for city builders or tactics games.
  -- Parameters:
  --   width, height   = map size in tiles
  --   tileW, tileH    = diamond footprint in pixels (tileW is typically 2x tileH)
  --   levelHeight     = vertical pixel offset between Z-levels
  --   partCount       = tile parts per cell (floor, north wall, west wall, object)
  --
  -- A 32x32 city map with 64x32 diamond tiles and 4 vertical levels:
  local iso = lurek.tilemap.newIsoMap(32, 32, 64, 32, 24, 4)
  iso:addLevel()
  lurek.log.info("iso map " .. iso:getWidth() .. "x" .. iso:getHeight() .. " parts=" .. iso:getPartCount(), "tilemap")
end

--@api-stub: lurek.tilemap.newMapBlock
-- Creates a new procedural map block with the given dimensions
do
  -- MapBlocks are the building pieces for procedural dungeon generation.
  -- Each block is a small tile grid with labeled edge segments for matching.
  -- Parameters:
  --   width, height   = block size in tiles
  --   layers          = tile layers (default 1)
  --   segmentSize     = edge segment granularity (tiles per segment)
  --
  -- A corridor piece that connects on its east/west edges:
  local room = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  room:setName("starter_room")
  room:setWeight(2.0)  -- twice as likely to appear as weight=1 blocks
  lurek.log.info("block '" .. room:getName() .. "' " .. room:getWidth() .. "x" .. room:getHeight(), "tilemap")
end

--@api-stub: lurek.tilemap.newMapGroup
-- Creates a new map group to hold blocks and generation scripts
do
  -- MapGroups organize blocks and scripts for the procedural generator.
  -- One group = one tileset of room/corridor pieces for a dungeon theme.
  local dungeon = lurek.tilemap.newMapGroup("dungeon")
  lurek.log.info("group '" .. dungeon:getName() .. "' starts with " .. dungeon:getBlockCount() .. " blocks", "tilemap")
end

--@api-stub: lurek.tilemap.newMapScript
-- Creates a new empty map-generation script
do
  -- A MapScript defines a sequence of procedural steps (fill, carve, scatter).
  -- Attach it to a MapGroup; the generator executes steps in order.
  local script = lurek.tilemap.newMapScript()
  script:addStep({ type = "fillRandom", gid = 1, chance = 0.3 })
  lurek.log.info("script has " .. script:getStepCount() .. " step(s)", "tilemap")
end

--@api-stub: lurek.tilemap.newMapGen
-- Creates a procedural map generator from a group and either a size preset or explicit dimensions
do
  -- MapGen assembles blocks from a group into a connected tilemap.
  -- Use preset strings ("small", "medium", "large") or explicit (width, height).
  -- segmentSize must match the blocks in the group.
  local group = lurek.tilemap.newMapGroup("rooms")
  group:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  local gen = lurek.tilemap.newMapGen(group, "small", 8)
  local map = gen:generate(nil, 1234)
  lurek.log.info("generated map with " .. map:getLayerCount() .. " layer(s)", "tilemap")
end

--@api-stub: lurek.tilemap.newLargeMapRenderer
-- Creates a chunk-based large-map renderer for efficient rendering of very large maps
do
  -- LargeMapRenderer handles maps too big for a single draw call (e.g. 1024x1024).
  -- It subdivides the map into rendering chunks, only draws visible ones,
  -- and supports LOD for zoomed-out views.
  local renderer = lurek.tilemap.newLargeMapRenderer(16, 16)
  renderer:setChunkSize(32)
  lurek.log.info("large map renderer ready, chunk=" .. renderer:getChunkSize(), "render")
end

--@api-stub: lurek.tilemap.loadTMX
-- Parses a TMX (Tiled XML) string and returns a table describing the map structure
do
  -- loadTMX parses Tiled editor XML. Returns a table with:
  --   .width, .height, .tileWidth, .tileHeight, .orientation, .layers[]
  -- This lets you load maps designed in Tiled Map Editor at runtime.
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
  -- fromLDtk parses LDtk project JSON. If levelName is nil, loads the first level.
  -- LDtk supports IntGrid layers, auto-layers, and tile layers.
  -- Use lurek.filesystem.read() to load the .ldtk file, then pass its content here.
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

-- =============================================================================
-- Coordinate Conversion — Isometric
-- =============================================================================

--@api-stub: lurek.tilemap.toScreenIso
-- Converts tile coordinates to screen-space position for isometric projection
do
  -- Use this to position sprites at tile locations in an isometric game.
  -- tw, th = diamond footprint size (must match your IsoMap dimensions).
  -- Returns the top-center of the diamond.
  local sx, sy = lurek.tilemap.toScreenIso(3, 5, 64, 32)
  lurek.log.info("iso tile (3,5) -> screen (" .. sx .. ", " .. sy .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.fromScreenIso
-- Converts screen-space coordinates back to tile coordinates for isometric projection
do
  -- Use this for mouse picking in an isometric view.
  -- Given a click at screen (mx, my), find which tile the player clicked.
  local mx, my = 320, 200
  local tx, ty = lurek.tilemap.fromScreenIso(mx, my, 64, 32)
  lurek.log.info("mouse (" .. mx .. "," .. my .. ") over iso tile (" .. tx .. ", " .. ty .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.isoRotate
-- Rotates an isometric direction index by a number of 90-degree steps
do
  -- Directions are 0..3 (north, east, south, west).
  -- Rotate a building's facing when the player presses R before placement.
  local d = lurek.tilemap.isoRotate(1, 2)
  lurek.log.info("rotated dir 1 by 2 steps -> " .. d .. " (" .. lurek.tilemap.isoDirectionName(d) .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.isoDirectionName
-- Returns a human-readable name for an isometric direction index
do
  -- Map direction indices to sprite animation suffixes.
  -- Example: character facing east -> play "walk_east" animation.
  local facing = lurek.tilemap.isoDirectionName(2)
  local sprite_key = "walk_" .. facing
  lurek.log.info("playing animation '" .. sprite_key .. "'", "anim")
end

--@api-stub: lurek.tilemap.isoDirectionFromAngle
-- Converts an angle in degrees to the nearest isometric direction index
do
  -- Convert a velocity vector to a facing direction for sprite selection.
  -- Useful when entities move freely but you only have 4 directional sprites.
  local dx, dy = 1, 0.2
  local dir = lurek.tilemap.isoDirectionFromAngle(math.atan2(dy, dx))
  lurek.log.info("velocity faces " .. lurek.tilemap.isoDirectionName(dir), "anim")
end

-- =============================================================================
-- Coordinate Conversion — Hexagonal
-- =============================================================================

--@api-stub: lurek.tilemap.toScreenHex
-- Converts axial hex coordinates to screen-space pixel position
do
  -- Axial coordinates (q, r) are the standard hex grid system.
  -- size = distance from hex center to corner in pixels.
  -- Use this to draw hex tiles or place units on a hex grid.
  local sx, sy = lurek.tilemap.toScreenHex(2, -1, 24)
  lurek.log.info("hex (q=2,r=-1) at screen (" .. sx .. ", " .. sy .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.fromScreenHex
-- Converts screen-space pixel coordinates to axial hex coordinates
do
  -- Mouse picking for hex strategy games. Given a click position,
  -- determine which hex cell was selected.
  local q, r = lurek.tilemap.fromScreenHex(150, 90, 24)
  lurek.log.info("screen (150,90) -> hex (q=" .. q .. ", r=" .. r .. ")", "tilemap")
end

-- =============================================================================
-- Hex Grid Utilities
-- =============================================================================

--@api-stub: lurek.tilemap.hexNeighbors
-- Returns the six neighboring hex cells of a given axial coordinate
do
  -- Every hex has exactly 6 neighbors. Use for adjacency checks:
  -- movement validation, fog-of-war reveal, territory expansion.
  local n = lurek.tilemap.hexNeighbors(0, 0)
  for _, c in ipairs(n) do
    lurek.log.debug("neighbor q=" .. c.q .. " r=" .. c.r, "tilemap")
  end
end

--@api-stub: lurek.tilemap.hexDistance
-- Computes the hex grid distance between two axial coordinates
do
  -- Hex distance = minimum steps to walk between two cells.
  -- Use for range checks: attack range, spell radius, movement budget.
  local d = lurek.tilemap.hexDistance(0, 0, 3, -2)
  if d <= 2 then
    lurek.log.info("target in melee range (d=" .. d .. ")", "combat")
  else
    lurek.log.info("target at range " .. d .. " (needs ranged attack)", "combat")
  end
end

--@api-stub: lurek.tilemap.hexRound
-- Rounds fractional axial hex coordinates to the nearest integer hex cell
do
  -- When interpolating positions (lerp between hexes), the result is fractional.
  -- hexRound snaps to the nearest valid hex cell.
  local q, r = lurek.tilemap.hexRound(2.4, -1.7)
  lurek.log.info("rounded fractional hex to (q=" .. q .. ", r=" .. r .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.hexLine
-- Returns all hex cells along a line between two axial coordinates
do
  -- Line-of-sight, laser beams, or unit path visualization.
  -- Returns ordered cells from start to end (inclusive).
  local cells = lurek.tilemap.hexLine(0, 0, 4, -2)
  for _, c in ipairs(cells) do
    lurek.log.debug("line cell (" .. c[1] .. ", " .. c[2] .. ")", "tilemap")
  end
end

--@api-stub: lurek.tilemap.hexRing
-- Returns all hex cells forming a ring at a given radius around a center
do
  -- Rings are useful for explosion radius indicators, detection perimeters,
  -- or spawning enemies around a point.
  local ring = lurek.tilemap.hexRing(0, 0, 3)
  lurek.log.info("ring at radius 3 has " .. #ring .. " cells", "tilemap")
end

--@api-stub: lurek.tilemap.hexSpiral
-- Returns all hex cells in a spiral pattern out to a given radius
do
  -- Spiral starts at center and expands outward, visiting each ring in order.
  -- Use for area-of-effect processing, fog reveal from center outward,
  -- or procedural terrain generation radiating from a seed point.
  local spiral = lurek.tilemap.hexSpiral(0, 0, 2)
  lurek.log.info("spiral 0..2 covers " .. #spiral .. " cells", "tilemap")
end

--@api-stub: lurek.tilemap.hexArea
-- Returns all hex cells within a filled area of a given radius
do
  -- Filled circle of hex cells. Unlike hexRing (perimeter only),
  -- hexArea returns ALL cells within radius (including center).
  -- Use for AoE damage, territory claims, or resource gathering range.
  local aoe = lurek.tilemap.hexArea(5, 5, 2)
  for _, c in ipairs(aoe) do
    lurek.log.debug("aoe cell (" .. c[1] .. ", " .. c[2] .. ")", "tilemap")
  end
end

--@api-stub: lurek.tilemap.hexRotate
-- Rotates a hex cell around a center point by a number of 60-degree steps
do
  -- Rotate formations, building layouts, or spell patterns around a pivot.
  -- steps > 0 = clockwise, steps < 0 = counter-clockwise.
  local q, r = lurek.tilemap.hexRotate(2, 0, 0, 0, 1)
  lurek.log.info("rotated (2,0) by 60deg -> (q=" .. q .. ", r=" .. r .. ")", "tilemap")
end

--@api-stub: lurek.tilemap.hexReflect
-- Reflects a hex cell across an axis through a center point
do
  -- Mirror formations for symmetric level design or ability targeting.
  -- axis = "q", "r", or "s" (the three hex axes).
  local q, r = lurek.tilemap.hexReflect(2, 1, 0, 0, "q")
  lurek.log.info("reflected hex (2,1) over q -> (" .. q .. ", " .. r .. ")", "tilemap")
end

-- =============================================================================
-- TileSet Methods
-- =============================================================================

--@api-stub: LTileSet:getFirstGid
-- Returns the first gid of this tile set
do
  -- When multiple tilesets share a map, each starts at a different GID.
  -- Use getFirstGid to convert local tile IDs to global IDs.
  local ts = lurek.tilemap.newTileSet(257, 64, 8, 16, 16)
  lurek.log.info("tileset firstGid=" .. ts:getFirstGid(), "tilemap")
end

--@api-stub: LAutoTileSheet:getTileCount
-- Returns the number of tile items in this tile set
do
  -- Mark the first 32 tiles as solid (walls), rest as walkable (floors).
  local ts = lurek.tilemap.newTileSet(1, 96, 12, 16, 16)
  for id = 1, ts:getTileCount() do
    ts:setSolid(id, id <= 32)
  end
end

--@api-stub: LTileSet:getColumns
-- Returns the columns of this tile set
do
  -- Compute atlas layout: columns and rows help debug UV issues.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local rows = ts:getTileCount() / ts:getColumns()
  lurek.log.info("atlas " .. ts:getColumns() .. " cols x " .. rows .. " rows", "tilemap")
end

--@api-stub: LIsoMap:getTileWidth
-- Returns the tile width of this tile set
do
  -- Use tile dimensions for collision box sizing in physics.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 32, 16)
  local box_w = ts:getTileWidth()
  lurek.log.info("collision width matches tile = " .. box_w, "physics")
end

--@api-stub: LIsoMap:getTileHeight
-- Returns the tile height of this tile set
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 24)
  local box_h = ts:getTileHeight()
  lurek.log.info("collision height = " .. box_h, "physics")
end

--@api-stub: LTileMap:getTileDimensions
-- Returns the tile dimensions of this tile set
do
  -- getTileDimensions returns both w,h in one call (avoids two method calls).
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local tw, th = ts:getTileDimensions()
  lurek.log.info("tile is " .. tw .. "x" .. th .. " px", "tilemap")
end

--@api-stub: LTileSet:getSpacing
-- Returns the spacing of this tile set
do
  -- Spacing = pixels between adjacent tiles in the atlas image.
  -- Some atlas tools export with 1-2px spacing to prevent texture bleeding.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16, 2, 1)
  lurek.log.info("atlas spacing=" .. ts:getSpacing() .. " margin=" .. ts:getMargin(), "tilemap")
end

--@api-stub: LTileSet:getMargin
-- Returns the margin of this tile set
do
  -- Margin = pixels around the outer edge of the atlas (before first tile).
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16, 0, 4)
  local m = ts:getMargin()
  lurek.log.info("first tile starts " .. m .. " px in from atlas edge", "tilemap")
end

--@api-stub: LAutoTileSheet:getQuad
-- Returns the quad of this tile set
do
  -- getQuad returns the source rectangle for a tile (used for custom drawing).
  -- Fields: .x, .y, .width, .height (pixel coords in the atlas).
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local q = ts:getQuad(5)
  lurek.log.info("tile 5 quad x=" .. q.x .. " y=" .. q.y .. " w=" .. q.width .. " h=" .. q.height, "tilemap")
end

--@api-stub: LTileSet:getAnimation
-- Returns the animation of this tile set
do
  -- Returns nil if no animation is assigned to this tile.
  -- Otherwise returns an array of {tileid, duration} frames.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local frames = ts:getAnimation(1)
  if frames == nil then
    lurek.log.info("tile 1 is static (no animation)", "tilemap")
  end
end

--@api-stub: LTileSet:setAnimation
-- Sets the animation of this tile set
do
  -- Define a 4-frame water animation looping at 8 FPS (125ms per frame).
  -- Each frame references a tile ID and its display duration in seconds.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setAnimation(5, {
    { tileid = 5, duration = 0.125 },
    { tileid = 6, duration = 0.125 },
    { tileid = 7, duration = 0.125 },
    { tileid = 8, duration = 0.125 },
  })
  lurek.log.info("4-frame water animation set on tile 5", "tilemap")
end

--@api-stub: LTileSet:setSolid
-- Sets the solid of this tile set
do
  -- Mark which tiles block movement. Solidity is per-tileset, checked
  -- by TileMap:isSolid() and TileMap:sweepRect() for collision.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  for _, gid in ipairs({ 5, 6, 7, 8 }) do
    ts:setSolid(gid, true)
  end
end

--@api-stub: LTileMap:isSolid
-- Returns true if this tile set solid
do
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setSolid(7, true)
  if ts:isSolid(7) then
    lurek.log.info("tile 7 will block movement", "tilemap")
  end
end

--@api-stub: LTileSet:setAutoTileRule
-- Sets the auto tile rule of this tile set
do
  -- Register a 4-bit auto-tile rule: bitmask encodes N/E/S/W neighbor presence.
  -- bitmask 15 = all 4 neighbors present -> use the "inner" tile variant.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setAutoTileRule("terrain", 0, 1)   -- isolated tile
  ts:setAutoTileRule("terrain", 15, 10) -- surrounded tile
  lurek.log.info("auto-tile rules set for 'terrain'", "tilemap")
end

--@api-stub: LTileSet:setAutoTileRule8
-- Sets the auto tile rule8 of this tile set
do
  -- 8-bit rules consider all 8 neighbors (including diagonals).
  -- bitmask 255 = all neighbors present -> fully surrounded tile.
  -- Use for smoother terrain transitions than 4-bit.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setAutoTileRule8("terrain", 255, 20)
  lurek.log.info("8-way auto-tile rule set", "tilemap")
end

--@api-stub: LTileSet:getAutoTileId
-- Returns the auto tile id of this tile set
do
  -- Look up which tile ID a 4-bit bitmask resolves to for a named type.
  -- Returns nil if no rule matches.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setAutoTileRule("terrain", 15, 10)
  local gid = ts:getAutoTileId("terrain", 15)
  lurek.log.info("bitmask 15 -> tile " .. (gid or -1), "tilemap")
end

--@api-stub: LTileSet:getAutoTileId8
-- Returns the auto tile id8 of this tile set
do
  -- 8-bit version of getAutoTileId for diagonal-aware rules.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setAutoTileRule8("terrain", 255, 20)
  local gid = ts:getAutoTileId8("terrain", 255)
  lurek.log.info("8-way bitmask 255 -> tile " .. (gid or -1), "tilemap")
end

-- =============================================================================
-- TileMap — Layer Management
-- =============================================================================

--@api-stub: LTileMap:addLayer
-- Adds a layer to this tile map
do
  -- Layers stack visually: lower index = drawn first (further back).
  -- Common pattern: background, main terrain, collision, foreground overlay.
  local map = lurek.tilemap.newTileMap(16, 16)
  local bg = map:addLayer("background", 64, 64)
  local fg = map:addLayer("collision", 64, 64)
  lurek.log.info("background=layer" .. bg .. " collision=layer" .. fg, "tilemap")
end

--@api-stub: LTileMap:addTileSet
-- Adds a tile set to this tile map
do
  -- Attach tilesets so the map knows which atlas to use for rendering.
  -- Multiple tilesets can be attached (terrain + props + characters).
  local map = lurek.tilemap.newTileMap(16, 16)
  local terrain = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  map:addTileSet(terrain)
  lurek.log.info("map now has " .. map:getTileSetCount() .. " tileset(s)", "tilemap")
end

--@api-stub: LTileMap:getTileSetCount
-- Returns the number of tile set items in this tile map
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addTileSet(lurek.tilemap.newTileSet(1, 32, 8, 16, 16))
  map:addTileSet(lurek.tilemap.newTileSet(33, 32, 8, 16, 16))
  lurek.log.info("tilesets attached: " .. map:getTileSetCount(), "tilemap")
end

--@api-stub: LTileMap:getTileSet
-- Returns the tile set of this tile map
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addTileSet(lurek.tilemap.newTileSet(1, 64, 8, 16, 16))
  local ts = map:getTileSet(1)
  if ts then
    lurek.log.info("first tileset has " .. ts:getTileCount() .. " tiles", "tilemap")
  end
end

--@api-stub: LMapBlock:getLayerCount
-- Returns the number of layer items in this tile map
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  map:addLayer("collision", 32, 32)
  lurek.log.info("layers in map: " .. map:getLayerCount(), "tilemap")
end

--@api-stub: LTileMap:getLayerName
-- Returns the layer name of this tile map
do
  -- Find a layer by name (useful when loading TMX where indices may vary).
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("collision", 32, 32)
  local name = map:getLayerName(1)
  if name == "collision" then
    lurek.log.info("layer 1 is the collision layer", "tilemap")
  end
end

--@api-stub: LTileMap:getLayerVisible
-- Returns the layer visible of this tile map
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("collision", 32, 32)
  if not map:getLayerVisible(1) then
    lurek.log.warn("collision layer is hidden", "tilemap")
  end
end

--@api-stub: LTileMap:setLayerVisible
-- Sets the visibility flag for this tile map
do
  -- Hide debug/collision layers in release builds, show them with a hotkey.
  local map = lurek.tilemap.newTileMap(16, 16)
  local dbgLayer = map:addLayer("collision_debug", 16, 16)
  map:setLayerVisible(dbgLayer, false)
  lurek.log.info("debug layer hidden", "tilemap")
end

--@api-stub: LTileMap:getLayerColor
-- Returns the layer color of this tile map
do
  -- Layer tint is RGBA (0..1). Use for time-of-day or mood lighting.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  local r, g, b, a = map:getLayerColor(1)
  lurek.log.info("background tint rgba=" .. r .. "," .. g .. "," .. b .. "," .. a, "tilemap")
end

--@api-stub: LTileMap:setLayerColor
-- Sets the layer color of this tile map
do
  -- Tint the background layer blue for a nighttime mood.
  local map = lurek.tilemap.newTileMap(16, 16)
  local bgLayer = map:addLayer("background", 16, 16)
  map:setLayerColor(bgLayer, 0.7, 0.8, 1.0, 1.0)
  lurek.log.info("background tinted blue for night scene", "tilemap")
end

--@api-stub: LTileMap:getLayerOffset
-- Returns the layer offset of this tile map
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  local ox, oy = map:getLayerOffset(1)
  lurek.log.info("layer offset px=(" .. ox .. ", " .. oy .. ")", "tilemap")
end

--@api-stub: LTileMap:setLayerOffset
-- Sets the layer offset of this tile map
do
  -- Offset a decal layer by half-tile to overlay between grid cells.
  local map = lurek.tilemap.newTileMap(16, 16)
  local decalLayer = map:addLayer("decals", 16, 16)
  map:setLayerOffset(decalLayer, 4, -2)
  lurek.log.info("decal layer offset by (4,-2) px", "tilemap")
end

--@api-stub: LTileMap:getLayerParallax
-- Returns the layer parallax of this tile map
do
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("clouds", 64, 32)
  local px, py = map:getLayerParallax(1)
  lurek.log.info("clouds parallax=(" .. px .. ", " .. py .. ")", "tilemap")
end

--@api-stub: LTileMap:setLayerParallax
-- Sets the layer parallax of this tile map
do
  -- Values < 1 make the layer scroll slower than the camera (depth illusion).
  -- 0.4 = layer moves at 40% of camera speed -> appears far away.
  local map = lurek.tilemap.newTileMap(16, 16)
  local hillLayer = map:addLayer("bg_hills", 16, 16)
  map:setLayerParallax(hillLayer, 0.4, 0.0)
  lurek.log.info("hills parallax set for depth effect", "tilemap")
end

-- =============================================================================
-- TileMap — Tile Access
-- =============================================================================

--@api-stub: LMapBlock:setTile
-- Sets the tile of this tile map
do
  -- Place a tile at (column, row) on a layer. GID 0 = empty.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("ground", 32, 32)
  map:setTile(1, 4, 5, 2)
  lurek.log.info("placed gid=2 at (4,5): " .. map:getTile(1, 4, 5), "tilemap")
end

--@api-stub: LMapBlock:getTile
-- Returns the tile of this tile map
do
  -- Check what tile is at a position before placing something.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("collision", 32, 32)
  local gid = map:getTile(1, 4, 4)
  if gid == 0 then
    lurek.log.info("(4,4) is empty / walkable", "tilemap")
  end
end

--@api-stub: LChunkMap:clearTile
-- Clears all tile items from this tile map
do
  -- Erase a wall tile when the player destroys it (set to GID 0).
  local map = lurek.tilemap.newTileMap(16, 16)
  local layer = map:addLayer("walls", 32, 32)
  map:fill(layer, 5)
  map:clearTile(layer, 10, 10)  -- player blew up the wall at (10,10)
end

--@api-stub: LTileMap:fill
-- Performs the fill operation on this tile map
do
  -- Fill an entire layer with a single GID. Useful for initialization.
  local map = lurek.tilemap.newTileMap(16, 16)
  local bg = map:addLayer("background", 32, 32)
  map:fill(bg, 1)  -- gid 1 = grass tile everywhere
  lurek.log.info("background filled with grass", "tilemap")
end

--@api-stub: LTileMap:setTileTint
-- Sets the tile tint of this tile map
do
  -- Per-tile color override. Use for highlighting, damage flash, or selection.
  -- Red tint on a tile to show it's on fire:
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("ground", 16, 16)
  map:setTile(1, 5, 5, 1)
  map:setTileTint(1, 5, 5, 1.0, 0.5, 0.5, 1.0)  -- reddish tint
  lurek.log.info("tile (5,5) tinted red (burning)", "tilemap")
end

-- =============================================================================
-- TileMap — Coordinate Conversion
-- =============================================================================

--@api-stub: LTileMap:worldToTile
-- Performs the world to tile operation on this tile map
do
  -- Convert pixel coordinates to tile grid coordinates.
  -- Essential for: finding which tile the player is standing on,
  -- converting mouse position to grid cell, etc.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 64, 64)
  local tx, ty = map:worldToTile(128, 96)
  lurek.log.info("world (128,96) -> tile (" .. tx .. ", " .. ty .. ")", "tilemap")
end

--@api-stub: LTileMap:tileToWorld
-- Performs the tile to world operation on this tile map
do
  -- Convert tile coordinates back to pixel coordinates (top-left corner).
  -- Use for spawning entities at tile centers: add tileW/2, tileH/2.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  local wx, wy = map:tileToWorld(5, 8)
  lurek.log.info("spawn pos px=(" .. wx .. ", " .. wy .. ")", "tilemap")
end

-- =============================================================================
-- TileMap — Dimensions and Properties
-- =============================================================================

--@api-stub: LIsoMap:getTileWidth
-- Returns the tile width of this tile map
do
  local map = lurek.tilemap.newTileMap(32, 32)
  local step = map:getTileWidth()
  lurek.log.info("grid snap step = " .. step .. " px", "tilemap")
end

--@api-stub: LIsoMap:getTileHeight
-- Returns the tile height of this tile map
do
  local map = lurek.tilemap.newTileMap(16, 32)
  local row_h = map:getTileHeight()
  lurek.log.info("row height = " .. row_h .. " px", "tilemap")
end

--@api-stub: LTileMap:getTileDimensions
-- Returns the tile dimensions of this tile map
do
  local map = lurek.tilemap.newTileMap(16, 16)
  local tw, th = map:getTileDimensions()
  lurek.log.info("tile size " .. tw .. "x" .. th, "tilemap")
end

--@api-stub: LLargeMapRenderer:getChunkSize
-- Returns the chunk size of this tile map
do
  local map = lurek.tilemap.newTileMap(16, 16, 32)
  lurek.log.info("map chunk size = " .. map:getChunkSize(), "tilemap")
end

--@api-stub: LTileMap:getOrientation
-- Returns the orientation of this tile map
do
  -- Orientation affects coordinate transforms and rendering order.
  -- Values: "topdown", "sideview", "isometric", "hexagonal".
  local map = lurek.tilemap.newTileMap(16, 16)
  local o = map:getOrientation()
  if o == "topdown" then
    lurek.log.info("using top-down 4-way movement", "input")
  end
end

--@api-stub: LTileMap:setOrientation
-- Sets the orientation of this tile map
do
  -- Switch orientation for different game views.
  local map = lurek.tilemap.newTileMap(64, 32)
  map:setOrientation("isometric")
  lurek.log.info("orientation now " .. map:getOrientation(), "tilemap")
end

-- =============================================================================
-- TileMap — Collision and Physics
-- =============================================================================

--@api-stub: LTileMap:isSolid
-- Returns true if this tile map solid
do
  -- Quick point check: is the tile at (x,y) marked solid?
  -- Relies on the attached tileset's setSolid() configuration.
  local map = lurek.tilemap.newTileMap(16, 16)
  local layer = map:addLayer("collision", 32, 32)
  if map:isSolid(layer, 4, 4) then
    lurek.log.info("(4,4) blocks movement", "physics")
  end
end

--@api-stub: LTileMap:rectOverlapsSolid
-- Performs the rect overlaps solid operation on this tile map
do
  -- Test if a world-space AABB overlaps any solid tile. Use for:
  -- - Broad-phase collision before precise checks
  -- - Validating placement positions (can a building fit here?)
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setSolid(1, true)
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("collision", 32, 32)
  map:setTile(1, 3, 3, 1)
  local hit = map:rectOverlapsSolid(1, 32, 32, 16, 16)
  lurek.log.info("rect overlap with solid: " .. tostring(hit), "tilemap")
end

--@api-stub: LTileMap:sweepRect
-- Performs the sweep rect operation on this tile map
do
  -- Swept AABB: move a rectangle by (dx, dy) and find the first solid tile hit.
  -- Returns contact position, surface normal, and tile coordinates.
  -- Essential for platformer character controllers.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setSolid(1, true)
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("collision", 32, 32)
  map:setTile(1, 5, 5, 1)
  local cx, cy, nx, ny, hitCol, hitRow = map:sweepRect(1, 0, 80, 16, 16, 100, 0)
  lurek.log.info("sweep contact at (" .. cx .. "," .. cy .. ") normal=(" .. nx .. "," .. ny .. ") tile=(" .. hitCol .. "," .. hitRow .. ")", "tilemap")
end

--@api-stub: LTileMap:toNavGrid
-- Performs the to nav grid operation on this tile map
do
  -- Convert a tile layer into a boolean walkability grid for pathfinding.
  -- Pass an array of GIDs that should be considered walkable.
  -- Returns a 2D array of booleans.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setSolid(1, true)
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("ground", 8, 8)
  map:fill(1, 1)
  local grid = map:toNavGrid(1, { 1 })
  lurek.log.info("nav grid: " .. #grid .. " rows", "tilemap")
end

-- =============================================================================
-- TileMap — Rendering
-- =============================================================================

--@api-stub: LLargeMapRenderer:setViewport
-- Sets the viewport of this tile map
do
  -- Limit rendering to a viewport rectangle. Only tiles within this area
  -- are drawn. Update each frame to match camera position.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("ground", 64, 64)
  map:setViewport(0, 0, 320, 240)
  lurek.log.info("tilemap viewport set to 320x240", "tilemap")
end

--@api-stub: LTileMap:getViewport
-- Returns the viewport of this tile map
do
  local map = lurek.tilemap.newTileMap(16, 16)
  local x, y, w, h = map:getViewport()
  if x == nil then
    lurek.log.info("no viewport set, will render full map", "tilemap")
  end
end

--@api-stub: LTileMap:render
-- Draws or renders this tile map to the current render target
do
  -- Call in lurek.draw(). Pass negative camera offset so the world
  -- scrolls in the opposite direction of camera movement.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  local cam_x, cam_y = 0, 0
  function lurek.draw() map:render(-cam_x, -cam_y) end
end

--@api-stub: LTileMap:drawToImage
-- Draws or renders this tile map to the current render target
do
  -- Rasterize the map into an image for minimap thumbnails or screenshots.
  -- tileSize = pixel size per tile in the output image (2 = tiny preview).
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("background", 32, 32)
  local thumb = map:drawToImage(2)
  lurek.log.info("rendered map preview to ImageData", "tilemap")
end

--@api-stub: LTileMap:update
-- Advances this tile map by the given delta time
do
  -- Call in lurek.process(dt) to advance tile animations.
  -- Without this, animated tiles (water, torches) stay frozen.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("water", 32, 32)
  function lurek.process(dt) map:update(dt) end
end

-- =============================================================================
-- TileMap — Tile Callbacks
-- =============================================================================

--@api-stub: LTileMap:onTileEnter
-- Fires the callback registered for the tile enter event on this tile map
do
  -- Register a callback for when an entity first enters a tile with this GID.
  -- Use for: traps, collectibles, zone transitions, lava damage on entry.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("triggers", 32, 32)
  map:onTileEnter(5, function(wx, wy, tx, ty)
    lurek.log.info("entity entered trigger tile at (" .. tx .. "," .. ty .. ")", "tilemap")
  end)
  lurek.log.info("tile enter callback registered for gid=5", "tilemap")
end

--@api-stub: LTileMap:onTileStep
-- Fires the callback registered for the tile step event on this tile map
do
  -- onTileStep fires every frame an entity remains on the tile.
  -- Use for: continuous damage (poison swamp), slowing effects, particle spawning.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:onTileStep(5, function(entity, tx, ty)
    lurek.log.debug("entity stepping on gid=5 at " .. tx .. "," .. ty, "tilemap")
  end)
end

--@api-stub: LTileMap:onTileExit
-- Fires the callback registered for the tile exit event on this tile map
do
  -- onTileExit fires when an entity leaves a tile. Use for cleanup:
  -- stop damage-over-time, remove status effects applied on enter.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:onTileExit(5, function(entity, tx, ty)
    lurek.log.debug("entity exited gid=5 at " .. tx .. "," .. ty, "tilemap")
  end)
end

--@api-stub: LTileMap:checkEntities
-- Checks entities on this tile map and returns the result
do
  -- Call each frame with your entity list to trigger enter/step/exit callbacks.
  -- Each entity needs x,y fields (world-space pixel position).
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("triggers", 16, 16)
  map:onTileStep(1, function(entity, tx, ty)
    lurek.log.info("overlap at " .. tx .. "," .. ty, "tilemap")
  end)
  map:checkEntities(1, { { x = 40, y = 40 } })
  lurek.log.info("entities checked against tile callbacks", "tilemap")
end

--@api-stub: LTileMap:fireTileStep
-- Fires the tile step event on this tile map
do
  -- Manually fire a tile step callback (useful for scripted triggers).
  local map = lurek.tilemap.newTileMap(16, 16)
  map:fireTileStep(5, { id = "player", x = 64, y = 64 }, 2, 3)
  lurek.log.debug("fireTileStep manually called", "tilemap")
end

--@api-stub: LTileMap:fireTileExit
-- Fires the tile exit event on this tile map
do
  -- Manually fire a tile exit callback.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:fireTileExit(5, { id = "player", x = 64, y = 64 }, 2, 3)
  lurek.log.debug("fireTileExit manually called", "tilemap")
end

-- =============================================================================
-- TileMap — Auto-Tiling
-- =============================================================================

--@api-stub: LTileMap:applyAutoTile
-- Applies auto tile to this tile map
do
  -- Run 4-bit auto-tiling on an entire layer. Each tile is replaced by
  -- the correct variant based on its N/E/S/W neighbors and the registered rules.
  -- Call after bulk map edits (loading, generation).
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("terrain", 16, 16)
  map:fill(1, 1)
  map:applyAutoTile(1, "terrain")
  lurek.log.info("4-bit auto-tile applied to full layer", "tilemap")
end

--@api-stub: LTileMap:applyAutoTile8
-- Applies auto tile8 to this tile map
do
  -- 8-bit auto-tiling considers diagonal neighbors for smoother transitions.
  -- More expensive but produces nicer-looking terrain borders.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("terrain", 16, 16)
  map:fill(1, 1)
  map:applyAutoTile8(1, "terrain")
  lurek.log.info("8-bit auto-tile applied to full layer", "tilemap")
end

--@api-stub: LTileMap:applyAutoTileAt
-- Applies auto tile at to this tile map
do
  -- Update auto-tiling at a single position and its neighbors.
  -- Use after placing/removing individual tiles (real-time editing).
  -- Much cheaper than re-tiling the entire layer.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("terrain", 16, 16)
  map:setTile(1, 8, 8, 1)
  map:applyAutoTileAt(1, 8, 8, "terrain")
  lurek.log.info("auto-tile updated at (8,8) and neighbors", "tilemap")
end

--@api-stub: LTileMap:applyAutoTile8At
-- Applies the auto-tile 8-neighbour rule at a single tile position and updates surrounding tiles
do
  -- 8-bit single-cell update (diagonal-aware version of applyAutoTileAt).
  local map = lurek.tilemap.newTileMap(16, 16, 16)
  map:addLayer("terrain", 20, 20)
  map:setTile(1, 5, 5, 1)
  map:applyAutoTile8At(1, 5, 5, "terrain")
  lurek.log.info("8-bit auto-tile updated at (5,5)", "tilemap")
end

-- =============================================================================
-- TileMap — Query Utilities
-- =============================================================================

--@api-stub: LTileMap:tileTypeIndex
-- Builds an index mapping each GID present on a layer to an array of `{x, y}` positions
do
  -- Returns a lookup table: index[gid] = {{x=1,y=1}, {x=2,y=1}, ...}
  -- Use once after loading to quickly locate special tiles (spawns, chests, exits).
  local map = lurek.tilemap.newTileMap(16, 16, 8)
  map:addLayer("ground", 4, 4)
  map:setTile(1, 1, 1, 7)
  map:setTile(1, 2, 1, 7)
  local idx = map:tileTypeIndex(1)
  if idx[7] then
    lurek.log.debug("gid 7 appears " .. #idx[7] .. " times", "tilemap")
  end
end

--@api-stub: LTileMap:findTilesByGid
-- Returns all positions on a layer that contain a specific GID
do
  -- Simpler than tileTypeIndex when you only need positions for one GID.
  -- Returns an array of {x=number, y=number}.
  local map = lurek.tilemap.newTileMap(16, 16, 8)
  map:addLayer("ground", 4, 4)
  map:setTile(1, 1, 1, 3)
  map:setTile(1, 3, 3, 3)
  local pos = map:findTilesByGid(1, 3)
  lurek.log.info("found gid=3 at " .. #pos .. " positions", "tilemap")
end

-- =============================================================================
-- AutoTileSheet Methods
-- =============================================================================

--@api-stub: LAutoTileSheet:getLayout
-- Returns the layout of this auto tile sheet
do
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "minimal16")
  if sheet:getLayout() == "minimal16" then
    lurek.log.info("using 16-tile autotile ruleset (simplest)", "tilemap")
  end
end

--@api-stub: LAutoTileSheet:getTileCount
-- Returns the number of tile items in this auto tile sheet
do
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  lurek.log.info("blob47 sheet exposes " .. sheet:getTileCount() .. " tile variants", "tilemap")
end

--@api-stub: LIsoMap:getTileWidth
-- Returns the tile width of this auto tile sheet
do
  local sheet = lurek.tilemap.newAutoTileSheet(32, 32, "composite48")
  lurek.log.info("autotile tile width = " .. sheet:getTileWidth() .. " px", "tilemap")
end

--@api-stub: LIsoMap:getTileHeight
-- Returns the tile height of this auto tile sheet
do
  local sheet = lurek.tilemap.newAutoTileSheet(16, 24, "blob47")
  lurek.log.info("autotile tile height = " .. sheet:getTileHeight() .. " px", "tilemap")
end

--@api-stub: LAutoTileSheet:getBitmaskForTile
-- Returns the bitmask for tile of this auto tile sheet
do
  -- Reverse lookup: given a tile ID in the sheet, what bitmask does it represent?
  -- Useful for debugging or building editor tools.
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  local mask = sheet:getBitmaskForTile(5)
  lurek.log.info("tile 5 represents bitmask " .. mask, "tilemap")
end

--@api-stub: LAutoTileSheet:getTileForBitmask
-- Returns the tile for bitmask of this auto tile sheet
do
  -- Forward lookup: given a neighbor bitmask, which tile variant to draw?
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  local id = sheet:getTileForBitmask(15) or 1
  lurek.log.info("bitmask 15 (all 4 neighbors) -> tile " .. id, "tilemap")
end

--@api-stub: LAutoTileSheet:getQuad
-- Returns the quad of this auto tile sheet
do
  -- Get the source rectangle for rendering a specific auto-tile variant.
  -- Returns x, y, w, h in pixels relative to the sheet atlas.
  pcall(function()
    local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
    local x, y = sheet:getQuad(3)
    lurek.log.info("autotile 3 quad x=" .. x .. " y=" .. y, "tilemap")
  end)
end

--@api-stub: LAutoTileSheet:applyToTileSet
-- Applies to tile set to this auto tile sheet
do
  -- Transfer all bitmask-to-tile rules from the sheet into a tileset.
  -- This bridges the sheet's layout with the tileset's auto-tile registry.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local ats = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  ats:applyToTileSet(ts, "normal")
  lurek.log.info("auto-tile sheet rules applied to tileset", "tilemap")
end

-- =============================================================================
-- ChunkMap Methods
-- =============================================================================

--@api-stub: LMapBlock:setTile
-- Sets the tile of this chunk map
do
  -- Place tiles at any world coordinate (including negative).
  -- The chunk is auto-created if it doesn't exist yet.
  local world = lurek.tilemap.newChunkMap(16)
  world:setTile(20, 20, 3)
  lurek.log.info("chunk tile set at (20,20)", "tilemap")
end

--@api-stub: LMapBlock:getTile
-- Returns the tile of this chunk map
do
  local world = lurek.tilemap.newChunkMap(32)
  world:setTile(-5, 12, 9)
  local gid = world:getTile(-5, 12)
  lurek.log.info("tile at (-5, 12) gid=" .. gid, "tilemap")
end

--@api-stub: LChunkMap:clearTile
-- Clears all tile items from this chunk map
do
  -- Remove a tile (sets to 0). The chunk stays loaded.
  local world = lurek.tilemap.newChunkMap(16)
  world:setTile(3, 3, 5)
  world:clearTile(3, 3)
  lurek.log.info("tile (3,3) now gid=" .. world:getTile(3, 3), "tilemap")
end

--@api-stub: LChunkMap:fillRect
-- Performs the fill rect operation on this chunk map
do
  -- Fill a rectangular region. Useful for clearing areas or placing floor tiles.
  -- Coordinates are inclusive: fills from (x0,y0) to (x1,y1).
  local world = lurek.tilemap.newChunkMap(16)
  world:fillRect(0, 0, 31, 31, 1)
  lurek.log.info("filled 32x32 area with gid=1", "tilemap")
end

--@api-stub: LChunkMap:loadChunk
-- Loads chunk into this chunk map
do
  -- Pre-load chunks before the player reaches them (streaming).
  -- Chunk coordinates are in chunk-space (tile / chunkSize).
  local world = lurek.tilemap.newChunkMap(16)
  for cx = 0, 3 do
    world:loadChunk(cx, 0)
  end
end

--@api-stub: LChunkMap:unloadChunk
-- Performs the unload chunk operation on this chunk map
do
  -- Unload chunks far from the player to save memory.
  local world = lurek.tilemap.newChunkMap(16)
  world:loadChunk(0, 0)
  world:unloadChunk(0, 0)
  lurek.log.info("chunks resident: " .. #world:getLoadedChunks(), "tilemap")
end

--@api-stub: LLargeMapRenderer:getChunkSize
-- Returns the chunk size of this chunk map
do
  local world = lurek.tilemap.newChunkMap(64)
  local size = world:getChunkSize()
  lurek.log.info("chunk side = " .. size .. " tiles", "tilemap")
end

--@api-stub: LChunkMap:getLoadedChunks
-- Returns the loaded chunks of this chunk map
do
  -- Returns an array of {cx, cy} pairs for all chunks currently in memory.
  local world = lurek.tilemap.newChunkMap(16)
  world:setTile(0, 0, 1)
  world:setTile(40, -10, 2)
  for _, c in ipairs(world:getLoadedChunks()) do
    lurek.log.debug("chunk loaded cx=" .. c[1] .. " cy=" .. c[2], "tilemap")
  end
end

--@api-stub: LChunkMap:chunkTileRange
-- Performs the chunk tile range operation on this chunk map
do
  -- Find the tile-coordinate boundaries of a chunk.
  -- Useful for iterating over all tiles within a chunk.
  local world = lurek.tilemap.newChunkMap(16)
  local x0, y0, x1, y1 = world:chunkTileRange(2, -1)
  lurek.log.info("chunk (2,-1) covers x[" .. x0 .. ".." .. x1 .. "] y[" .. y0 .. ".." .. y1 .. "]", "tilemap")
end

--@api-stub: LChunkMap:getChunksInView
-- Returns the chunks in view of this chunk map
do
  -- Given a viewport rectangle and tile dimensions, find which chunks overlap.
  -- Use for rendering only visible chunks.
  local world = lurek.tilemap.newChunkMap(16)
  local chunks = world:getChunksInView(0, 0, 320, 240, 16, 16)
  lurek.log.info("chunks in view: " .. #chunks, "tilemap")
end

-- =============================================================================
-- LargeMapRenderer Methods
-- =============================================================================

--@api-stub: LLargeMapRenderer:setMapData
-- Sets the map data of this large map renderer
do
  -- Load tile data as a flat row-major array.
  -- width * height must equal #data.
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  local data = {}
  for i = 1, 128 * 128 do data[i] = 1 end
  r:setMapData(data, 128, 128)
  lurek.log.info("large map data loaded (128x128)", "tilemap")
end

--@api-stub: LMapBlock:setTile
-- Sets the tile of this large map renderer
do
  -- Edit individual tiles after loading. Invalidate the containing chunk afterward.
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  r:setTile(1, 0, 5)
  r:invalidateChunk(0, 0)
end

--@api-stub: LMapBlock:getTile
-- Returns the tile of this large map renderer
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 1, 2, 3, 4 }, 2, 2)
  local id = r:getTile(0, 0)
  if id then lurek.log.info("origin tile = " .. id, "render") end
end

--@api-stub: LLargeMapRenderer:getMapSize
-- Returns the map size of this large map renderer
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  local w, h = r:getMapSize()
  lurek.log.info("large map " .. w .. "x" .. h .. " tiles", "render")
end

--@api-stub: LLargeMapRenderer:setChunkSize
-- Sets the chunk size of this large map renderer
do
  -- Chunk size controls rendering granularity. Larger chunks = fewer draw calls
  -- but more overdraw. Smaller = more culling precision.
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setChunkSize(32)
  lurek.log.info("renderer chunk size = " .. r:getChunkSize(), "render")
end

--@api-stub: LLargeMapRenderer:getChunkSize
-- Returns the chunk size of this large map renderer
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  lurek.log.info("default chunk size = " .. r:getChunkSize(), "render")
end

--@api-stub: LLargeMapRenderer:invalidateChunk
-- Marks chunk as dirty so this large map renderer will regenerate it
do
  -- After editing tiles, invalidate the chunk to regenerate its mesh.
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  r:setTile(0, 0, 7)
  r:invalidateChunk(0, 0)
end

--@api-stub: LLargeMapRenderer:invalidateAll
-- Marks all as dirty so this large map renderer will regenerate it
do
  -- Force full rebuild (e.g. after loading new map data or changing tileset).
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 1, 2, 3, 4 }, 2, 2)
  r:invalidateAll()
  lurek.log.info("all chunks marked dirty", "render")
end

--@api-stub: LLargeMapRenderer:setCamera
-- Sets the camera of this large map renderer
do
  -- Update each frame to match the camera. Only chunks visible at this
  -- position and zoom will be rendered.
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  r:setCamera(128, 64, 2.0)  -- world pos (128,64), zoom 2x
  r:setViewport(800, 600)
  lurek.log.info("camera updated, visible=" .. r:getVisibleChunks(), "tilemap")
end

--@api-stub: LLargeMapRenderer:setViewport
-- Sets the viewport of this large map renderer
do
  -- Set viewport dimensions (usually your window size).
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  r:setViewport(1920, 1080)
end

--@api-stub: LLargeMapRenderer:getVisibleChunks
-- Returns the visible chunks of this large map renderer
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0 }, 2, 2)
  r:setCamera(0, 0, 1.0)
  r:setViewport(800, 600)
  lurek.log.info("visible chunks: " .. r:getVisibleChunks(), "render")
end

--@api-stub: LLargeMapRenderer:getTotalChunks
-- Returns the total chunks of this large map renderer
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setMapData({ 0, 0, 0, 0, 0, 0, 0, 0 }, 4, 2)
  lurek.log.info("total chunks = " .. r:getTotalChunks(), "render")
end

--@api-stub: LLargeMapRenderer:setLodEnabled
-- Sets whether this large map renderer is enabled and accepts input
do
  -- LOD (Level of Detail) draws distant chunks at lower resolution
  -- for strategy maps zoomed out very far.
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setLodEnabled(true)
  if r:isLodEnabled() then
    lurek.log.info("LOD active for distant chunks", "render")
  end
end

--@api-stub: LLargeMapRenderer:isLodEnabled
-- Returns true if this large map renderer is currently enabled
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  if not r:isLodEnabled() then
    r:setLodEnabled(true)
  end
end

--@api-stub: LLargeMapRenderer:setLodThresholds
-- Sets the lod thresholds of this large map renderer
do
  -- Thresholds define at what zoom distances LOD levels kick in.
  -- Lower values = LOD activates sooner (more aggressive simplification).
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setLodEnabled(true)
  r:setLodThresholds({ 64.0, 256.0, 1024.0 })
end

--@api-stub: LLargeMapRenderer:setTilesetColumns
-- Sets the tileset columns of this large map renderer
do
  -- The renderer needs to know atlas column count for UV calculation.
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setTilesetColumns(16)
  lurek.log.info("renderer atlas cols = " .. r:getTilesetColumns(), "render")
end

--@api-stub: LLargeMapRenderer:getTilesetColumns
-- Returns the tileset columns of this large map renderer
do
  local r = lurek.tilemap.newLargeMapRenderer(16, 16)
  r:setTilesetColumns(8)
  lurek.log.info("UVs are sliced into " .. r:getTilesetColumns() .. " columns", "render")
end

-- =============================================================================
-- IsoMap Methods
-- =============================================================================

--@api-stub: LIsoMap:addLevel
-- Adds a level to this iso map
do
  -- Add vertical levels for multi-story buildings.
  -- Returns the new level's index (1-based).
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  local z = iso:addLevel()
  lurek.log.info("added level " .. z .. ", count now " .. iso:getLevelCount(), "tilemap")
end

--@api-stub: LIsoMap:getLevelCount
-- Returns the number of level items in this iso map
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:addLevel(); iso:addLevel(); iso:addLevel()
  lurek.log.info("iso has " .. iso:getLevelCount() .. " level(s)", "tilemap")
end

--@api-stub: LIsoMap:setLevelVisible
-- Sets the visibility flag for this iso map
do
  -- Hide upper floors to see inside buildings (like The Sims).
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:addLevel(); iso:addLevel()
  iso:setLevelVisible(2, false)  -- hide upper floor
end

--@api-stub: LIsoMap:isLevelVisible
-- Returns true if this iso map is currently visible
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:addLevel()
  if iso:isLevelVisible(1) then
    lurek.log.info("ground floor is visible", "tilemap")
  end
end

--@api-stub: LIsoMap:fillLevel
-- Performs the fill level operation on this iso map
do
  -- Fill all tiles of a specific part on a level.
  -- Parts: 0=floor, 1=north wall, 2=west wall, 3=object (when partCount=4).
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:addLevel()
  iso:fillLevel(1, lurek.tilemap.FLOOR - 1, 1)  -- floor part, gid 1
end

--@api-stub: LIsoMap:setTilePart
-- Sets the tile part of this iso map
do
  -- Set individual tile parts: floor, walls, or objects at a specific cell.
  local iso = lurek.tilemap.newIsoMap(16, 16, 32, 16, 8)
  iso:addLevel()
  iso:setTilePart(1, 1, 1, 0, 5)  -- level 1, pos (1,1), part 0 (floor), gid 5
  lurek.log.info("iso tile part set", "tilemap")
end

--@api-stub: LIsoMap:getTilePart
-- Returns the tile part of this iso map
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 32, 16, 8)
  iso:addLevel()
  local gid = iso:getTilePart(1, 1, 1, 0)
  lurek.log.info("tile part gid: " .. (gid or 0), "tilemap")
end

--@api-stub: LIsoMap:setOrigin
-- Sets the origin of this iso map
do
  -- Origin = screen-space anchor point for the top-left of the map rendering.
  -- Center the map on screen by setting origin to (screenW/2, topMargin).
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:addLevel()
  iso:setOrigin(400, 100)
end

--@api-stub: LMapBlock:getWidth
-- Returns the width of this iso map
do
  local iso = lurek.tilemap.newIsoMap(20, 30, 64, 32, 24)
  lurek.log.info("iso map is " .. iso:getWidth() .. " tiles wide", "tilemap")
end

--@api-stub: LMapBlock:getHeight
-- Returns the height of this iso map
do
  local iso = lurek.tilemap.newIsoMap(20, 30, 64, 32, 24)
  lurek.log.info("iso map is " .. iso:getHeight() .. " tiles tall", "tilemap")
end

--@api-stub: LIsoMap:getTileWidth
-- Returns the tile width of this iso map
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  lurek.log.info("iso tile footprint width = " .. iso:getTileWidth() .. " px", "tilemap")
end

--@api-stub: LIsoMap:getTileHeight
-- Returns the tile height of this iso map
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  lurek.log.info("iso tile footprint height = " .. iso:getTileHeight() .. " px", "tilemap")
end

--@api-stub: LIsoMap:getLevelHeight
-- Returns the level height of this iso map
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 32)
  lurek.log.info("Z step = " .. iso:getLevelHeight() .. " px between levels", "tilemap")
end

--@api-stub: LIsoMap:tileToScreen
-- Performs the tile to screen operation on this iso map
do
  -- Convert tile (x, y, z) to screen pixel position for sprite placement.
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:setOrigin(400, 100)
  local sx, sy = iso:tileToScreen(3, 4, 0)
  lurek.log.info("tile (3,4,0) at screen (" .. sx .. ", " .. sy .. ")", "tilemap")
end

--@api-stub: LIsoMap:screenToTile
-- Performs the screen to tile operation on this iso map
do
  -- Mouse picking: find which iso tile the cursor is over.
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24)
  iso:setOrigin(400, 100)
  local tx, ty = iso:screenToTile(500, 200)
  lurek.log.info("cursor over iso tile (" .. tx .. ", " .. ty .. ")", "tilemap")
end

--@api-stub: LIsoMap:getPartCount
-- Returns the number of part items in this iso map
do
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24, 4)
  lurek.log.info("iso parts per tile = " .. iso:getPartCount(), "tilemap")
end

--@api-stub: LIsoMap:getPartOrder
-- Returns the part order of this iso map
do
  -- Part order controls draw sequence within each cell (floor first, then walls).
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24, 4)
  local order = iso:getPartOrder()
  lurek.log.info("iso draw order has " .. #order .. " slots", "tilemap")
end

--@api-stub: LIsoMap:setPartOrder
-- Sets the part order of this iso map
do
  -- Override draw order to fix rendering artifacts.
  -- Default is {0,1,2,3}; swap if walls should draw before/after objects.
  local iso = lurek.tilemap.newIsoMap(16, 16, 64, 32, 24, 4)
  iso:setPartOrder({ 0, 2, 1, 3 })  -- swap N-wall and W-wall draw order
end

-- =============================================================================
-- MapBlock Methods
-- =============================================================================

--@api-stub: LMapBlock:setTile
-- Sets the tile of this map block
do
  -- Populate the block's tile grid. layer, x, y are 1-based.
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setTile(1, 2, 3, 1)  -- layer 1, col 2, row 3, gid 1
  block:setTile(1, 4, 4, 2)
  lurek.log.info("map block tiles set", "tilemap")
end

--@api-stub: LMapBlock:getTile
-- Returns the tile of this map block
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setTile(1, 3, 3, 5)
  local gid = block:getTile(1, 3, 3)
  lurek.log.info("block tile (3,3) gid=" .. gid, "tilemap")
end

--@api-stub: LMapBlock:setSide
-- Sets the side of this map block
do
  -- Define edge connection IDs for the generator to match adjacent blocks.
  -- Blocks connect when their shared edge segments have matching side IDs.
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setSide("north", 1, 5)  -- north edge, segment 1, connection ID 5
  lurek.log.info("block side set", "tilemap")
end

--@api-stub: LMapBlock:getSide
-- Returns the side of this map block
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setSide("north", 1, 7)
  local id = block:getSide("north", 1)
  lurek.log.info("north edge segment 1 connection id=" .. id, "tilemap")
end

--@api-stub: LMapBlock:getWidth
-- Returns the width of this map block
do
  local block = lurek.tilemap.newMapBlock(12, 8, 1, 4)
  lurek.log.info("block width " .. block:getWidth() .. " tiles", "tilemap")
end

--@api-stub: LMapBlock:getHeight
-- Returns the height of this map block
do
  local block = lurek.tilemap.newMapBlock(8, 12, 1, 4)
  lurek.log.info("block height " .. block:getHeight() .. " tiles", "tilemap")
end

--@api-stub: LMapBlock:getDimensions
-- Returns the dimensions of this map block
do
  local block = lurek.tilemap.newMapBlock(10, 6, 1, 2)
  local w, h = block:getDimensions()
  lurek.log.info("block " .. w .. "x" .. h, "tilemap")
end

--@api-stub: LMapBlock:getLayerCount
-- Returns the number of layer items in this map block
do
  local block = lurek.tilemap.newMapBlock(8, 8, 3, 4)
  lurek.log.info("block has " .. block:getLayerCount() .. " layer(s)", "tilemap")
end

--@api-stub: LMapBlock:getSegmentSize
-- Returns the segment size of this map block
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  lurek.log.info("segment size = " .. block:getSegmentSize() .. " tiles", "tilemap")
end

--@api-stub: LMapBlock:getWidthInSegments
-- Returns the width in segments of this map block
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  lurek.log.info("block is " .. block:getWidthInSegments() .. " segments wide", "tilemap")
end

--@api-stub: LMapBlock:getHeightInSegments
-- Returns the height in segments of this map block
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  lurek.log.info("block is " .. block:getHeightInSegments() .. " segments tall", "tilemap")
end

--@api-stub: LMapBlock:setName
-- Sets the name of this map block
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setName("treasure_room")
  lurek.log.info("named block: " .. block:getName(), "tilemap")
end

--@api-stub: LMapGroup:getName
-- Returns the name of this map block
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setName("corridor_h")
  if block:getName():match("^corridor") then
    lurek.log.info("block is a corridor variant", "tilemap")
  end
end

--@api-stub: LMapBlock:setWeight
-- Sets the weight of this map block
do
  -- Higher weight = more likely to appear in procedural generation.
  -- Use low weights for rare special rooms (boss, treasure).
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setWeight(3.5)  -- 3.5x more common than weight=1 blocks
  lurek.log.info("weight = " .. block:getWeight(), "tilemap")
end

--@api-stub: LMapBlock:getWeight
-- Returns the weight of this map block
do
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  if block:getWeight() < 1.0 then
    lurek.log.warn("block '" .. block:getName() .. "' is rare", "tilemap")
  end
end

-- =============================================================================
-- MapGroup Methods
-- =============================================================================

--@api-stub: LMapGroup:addBlock
-- Adds a block to this map group
do
  -- Build a group with multiple room variants for the generator to pick from.
  local group = lurek.tilemap.newMapGroup("rooms")
  group:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  group:addBlock(lurek.tilemap.newMapBlock(12, 8, 1, 4))
  lurek.log.info("group has " .. group:getBlockCount() .. " blocks", "tilemap")
end

--@api-stub: LMapGroup:getBlockCount
-- Returns the number of block items in this map group
do
  local group = lurek.tilemap.newMapGroup("rooms")
  group:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  if group:getBlockCount() == 0 then
    lurek.log.error("group '" .. group:getName() .. "' is empty", "tilemap")
  end
end

--@api-stub: LMapGroup:removeBlock
-- Removes a block from this map group
do
  -- Remove blocks by index (e.g. disabling a room type at runtime).
  local group = lurek.tilemap.newMapGroup("rooms")
  group:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  group:addBlock(lurek.tilemap.newMapBlock(12, 8, 1, 4))
  group:removeBlock(1)  -- drop first block
end

--@api-stub: LMapGroup:getName
-- Returns the name of this map group
do
  local group = lurek.tilemap.newMapGroup("dungeon_floor_1")
  lurek.log.info("active group: " .. group:getName(), "tilemap")
end

--@api-stub: LMapGroup:addScript
-- Adds a script to this map group
do
  -- Attach generation scripts that run post-processing after block placement.
  local group = lurek.tilemap.newMapGroup("rooms")
  local script = lurek.tilemap.newMapScript()
  script:addStep({ type = "fillRandom", gid = 1, chance = 0.2 })
  group:addScript(script)
end

--@api-stub: LMapGroup:getScriptCount
-- Returns the number of script items in this map group
do
  local group = lurek.tilemap.newMapGroup("rooms")
  group:addScript(lurek.tilemap.newMapScript())
  lurek.log.info("group has " .. group:getScriptCount() .. " script(s)", "tilemap")
end

-- =============================================================================
-- MapScript Methods
-- =============================================================================

--@api-stub: LMapScript:addStep
-- Adds a step to this map script
do
  -- Steps define procedural operations: fill, carve, scatter, path drawing.
  -- Each step is a table with a "type" field and operation-specific params.
  local script = lurek.tilemap.newMapScript()
  script:addStep({ type = "fillRect", x = 0, y = 0, w = 16, h = 16, gid = 1 })
  script:addStep({ type = "drawPath", x = 1, y = 1, w = 14, h = 14, gid = 2, pathWidth = 2 })
  lurek.log.info("authored " .. script:getStepCount() .. " step(s)", "tilemap")
end

--@api-stub: LMapScript:getStepCount
-- Returns the number of step items in this map script
do
  local script = lurek.tilemap.newMapScript()
  script:addStep({ type = "fillArea", x = 1, y = 1, w = 8, h = 8, gid = 1 })
  lurek.log.info("script step count: " .. script:getStepCount(), "tilemap")
end

-- =============================================================================
-- MapGen Methods
-- =============================================================================

--@api-stub: LMapGen:generate
-- Generates content using this map gen and returns the result
do
  -- generate(scriptIdx, seed, layerName) -> LTileMap
  -- scriptIdx = which script to run (nil = default)
  -- seed = deterministic random seed (nil = random)
  -- layerName = output layer name (default "main")
  local grp = lurek.tilemap.newMapGroup("dungeon")
  grp:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  local gen = lurek.tilemap.newMapGen(grp, "medium", 4)
  local tm = gen:generate(nil, 42)
  lurek.log.info("dungeon generated with seed 42", "tilemap")
end

-- =============================================================================
-- Type Introspection
-- =============================================================================

--@api-stub: LMapGen:type
-- Returns the type name of this userdata
do
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  lurek.log.info("LAutoTileSheet:type = " .. sheet:type(), "tilemap")
end

--@api-stub: LMapGen:typeOf
-- Checks whether this object matches the given type name
do
  local sheet = lurek.tilemap.newAutoTileSheet(16, 16, "blob47")
  lurek.log.info("is LAutoTileSheet: " .. tostring(sheet:typeOf("LAutoTileSheet")), "tilemap")
  lurek.log.info("is Object: " .. tostring(sheet:typeOf("Object")), "tilemap")
end

--@api-stub: LMapGen:type
-- Returns the type name of this userdata
do
  local cm = lurek.tilemap.newChunkMap(16)
  lurek.log.info("LChunkMap:type = " .. cm:type(), "tilemap")
end

--@api-stub: LMapGen:typeOf
-- Checks whether this object matches the given type name
do
  local cm = lurek.tilemap.newChunkMap(16)
  lurek.log.info("is LChunkMap: " .. tostring(cm:typeOf("LChunkMap")), "tilemap")
  lurek.log.info("is Object: " .. tostring(cm:typeOf("Object")), "tilemap")
end

--@api-stub: LMapGen:type
-- Returns the type name of this userdata
do
  local iso = lurek.tilemap.newIsoMap(8, 8, 64, 32, 24)
  lurek.log.info("LIsoMap:type = " .. iso:type(), "tilemap")
end

--@api-stub: LMapGen:typeOf
-- Checks whether this object matches the given type name
do
  local iso = lurek.tilemap.newIsoMap(8, 8, 64, 32, 24)
  lurek.log.info("is LIsoMap: " .. tostring(iso:typeOf("LIsoMap")), "tilemap")
  lurek.log.info("is Object: " .. tostring(iso:typeOf("Object")), "tilemap")
end

--@api-stub: LMapGen:type
-- Returns the type name of this userdata
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lurek.log.info("LLargeMapRenderer:type = " .. lmr:type(), "tilemap")
end

--@api-stub: LMapGen:typeOf
-- Checks whether this object matches the given type name
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lurek.log.info("is LLargeMapRenderer: " .. tostring(lmr:typeOf("LLargeMapRenderer")), "tilemap")
  lurek.log.info("is Object: " .. tostring(lmr:typeOf("Object")), "tilemap")
end

--@api-stub: LMapGen:type
-- Returns the type name of this userdata
do
  local mb = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  lurek.log.info("LMapBlock:type = " .. mb:type(), "tilemap")
end

--@api-stub: LMapGen:typeOf
-- Checks whether this object matches the given type name
do
  local mb = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  lurek.log.info("is LMapBlock: " .. tostring(mb:typeOf("LMapBlock")), "tilemap")
  lurek.log.info("is Object: " .. tostring(mb:typeOf("Object")), "tilemap")
end

--@api-stub: LMapGen:type
-- Returns the type name of this userdata
do
  local grp = lurek.tilemap.newMapGroup("test")
  grp:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  local gen = lurek.tilemap.newMapGen(grp, "small", 8)
  lurek.log.info("LMapGen:type = " .. gen:type(), "tilemap")
end

--@api-stub: LMapGen:typeOf
-- Checks whether this object matches the given type name
do
  local grp = lurek.tilemap.newMapGroup("test")
  grp:addBlock(lurek.tilemap.newMapBlock(8, 8, 1, 4))
  local gen = lurek.tilemap.newMapGen(grp, "small", 8)
  lurek.log.info("is LMapGen: " .. tostring(gen:typeOf("LMapGen")), "tilemap")
  lurek.log.info("is Object: " .. tostring(gen:typeOf("Object")), "tilemap")
end

--@api-stub: LMapGen:type
-- Returns the type name of this userdata
do
  local mg = lurek.tilemap.newMapGroup("test")
  lurek.log.info("LMapGroup:type = " .. mg:type(), "tilemap")
end

--@api-stub: LMapGen:typeOf
-- Checks whether this object matches the given type name
do
  local mg = lurek.tilemap.newMapGroup("test")
  lurek.log.info("is LMapGroup: " .. tostring(mg:typeOf("LMapGroup")), "tilemap")
  lurek.log.info("is Object: " .. tostring(mg:typeOf("Object")), "tilemap")
end

--@api-stub: LMapGen:type
-- Returns the type name of this userdata
do
  local ms = lurek.tilemap.newMapScript()
  lurek.log.info("LMapScript:type = " .. ms:type(), "tilemap")
end

--@api-stub: LMapGen:typeOf
-- Checks whether this object matches the given type name
do
  local ms = lurek.tilemap.newMapScript()
  lurek.log.info("is LMapScript: " .. tostring(ms:typeOf("LMapScript")), "tilemap")
  lurek.log.info("is Object: " .. tostring(ms:typeOf("Object")), "tilemap")
end

--@api-stub: LMapGen:type
-- Returns the type name of this userdata
do
  local tm = lurek.tilemap.newTileMap(32, 32)
  lurek.log.info("LTileMap:type = " .. tm:type(), "tilemap")
end

--@api-stub: LMapGen:typeOf
-- Checks whether this object matches the given type name
do
  local tm = lurek.tilemap.newTileMap(32, 32)
  lurek.log.info("is LTileMap: " .. tostring(tm:typeOf("LTileMap")), "tilemap")
  lurek.log.info("is Object: " .. tostring(tm:typeOf("Object")), "tilemap")
end

--@api-stub: LMapGen:type
-- Returns the type name of this userdata
do
  local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
  lurek.log.info("LTileSet:type = " .. ts:type(), "tilemap")
end

--@api-stub: LMapGen:typeOf
-- Checks whether this object matches the given type name
do
  local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
  lurek.log.info("is LTileSet: " .. tostring(ts:typeOf("LTileSet")), "tilemap")
  lurek.log.info("is Object: " .. tostring(ts:typeOf("Object")), "tilemap")
end

-- =============================================================================
-- Duplicate LargeMapRenderer stubs (alternative usage patterns)
-- =============================================================================

--@api-stub: LLargeMapRenderer:setMapData
-- Replaces all tile data with a flat array of GIDs for the given dimensions
do
  -- Pattern tile data for a checkerboard effect:
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  local map_data = {}
  for i = 1, 8 * 8 do map_data[i] = (i % 4) + 1 end
  lmr:setMapData(map_data, 8, 8)
  local w, h = lmr:getMapSize()
  lurek.log.info("map loaded: " .. w .. "x" .. h, "tilemap")
end

--@api-stub: LMapBlock:setTile
-- Sets a single tile GID at a given position
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  local data = {}; for i = 1, 8 * 8 do data[i] = 1 end
  lmr:setMapData(data, 8, 8)
  lmr:setTile(3, 2, 5)  -- column 3, row 2 (0-based) -> tile 5
  lurek.log.info("tile(3,2)=" .. tostring(lmr:getTile(3, 2)), "tilemap")
end

--@api-stub: LMapBlock:getTile
-- Returns the tile GID at a given position
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  local data = {}; for i = 1, 4 * 4 do data[i] = i end
  lmr:setMapData(data, 4, 4)
  local id = lmr:getTile(1, 2)
  lurek.log.info("tile(1,2)=" .. tostring(id), "tilemap")
end

--@api-stub: LLargeMapRenderer:getMapSize
-- Returns the map dimensions in tiles
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  local data = {}; for i = 1, 10 * 10 do data[i] = 1 end
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
  local data = {}; for i = 1, 32 * 32 do data[i] = 1 end
  lmr:setMapData(data, 32, 32)
  lmr:setTile(5, 5, 2)
  lmr:invalidateChunk(0, 0)
  lurek.log.info("chunk (0,0) invalidated after tile edit", "tilemap")
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
  local data = {}; for i = 1, 32 * 32 do data[i] = 1 end
  lmr:setMapData(data, 32, 32)
  lmr:setCamera(0, 0, 1.0)
  lmr:setViewport(800, 600)
  lurek.log.info("visible_chunks=" .. lmr:getVisibleChunks(), "tilemap")
end

--@api-stub: LLargeMapRenderer:getTotalChunks
-- Returns the total number of chunks in the map
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  local data = {}; for i = 1, 32 * 32 do data[i] = 1 end
  lmr:setMapData(data, 32, 32)
  lurek.log.info("total_chunks=" .. lmr:getTotalChunks(), "tilemap")
end

--@api-stub: LLargeMapRenderer:setCamera
-- Sets the camera position and zoom level for determining visible chunks
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lmr:setCamera(128, 64, 2.0)
  lmr:setViewport(800, 600)
  lurek.log.info("camera at (128,64) zoom 2x", "tilemap")
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
  lmr:setLodThresholds({ 32, 64, 128 })
  lurek.log.info("LOD thresholds configured", "tilemap")
end

--@api-stub: LLargeMapRenderer:setTilesetColumns
-- Sets the column count of the associated tileset atlas for UV calculation
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lmr:setTilesetColumns(16)
  lurek.log.info("tileset_cols=" .. lmr:getTilesetColumns(), "tilemap")
end

--@api-stub: LLargeMapRenderer:getTilesetColumns
-- Returns the tileset column count used for UV calculation
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lmr:setTilesetColumns(8)
  lurek.log.info("tileset_cols=" .. lmr:getTilesetColumns(), "tilemap")
end

--@api-stub: LMapGen:type
-- Returns the Lua-visible type name string for this large map renderer handle
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lurek.log.info("LargeMapRenderer:type = " .. lmr:type(), "tilemap")
end

--@api-stub: LMapGen:typeOf
-- Returns true if this large map renderer handle matches the given type name string
do
  local lmr = lurek.tilemap.newLargeMapRenderer(16, 16)
  lurek.log.info("is LLargeMapRenderer: " .. tostring(lmr:typeOf("LLargeMapRenderer")), "tilemap")
end

print("content/examples/tilemap.lua")

-- =============================================================================
-- Additional coverage stubs (fleshed out)
-- =============================================================================

--@api-stub: LAutoTileSheet:getTileWidth
-- Returns the width of each tile in the auto-tile sheet, in pixels.
do
  -- Verify tile dimensions match the atlas before applying rules.
  local sheet = lurek.tilemap.newAutoTileSheet(32, 16, "blob47")
  lurek.log.info("autotile w=" .. sheet:getTileWidth() .. " px", "tilemap")
end

--@api-stub: LAutoTileSheet:getTileHeight
-- Returns the height of each tile in the auto-tile sheet, in pixels.
do
  -- Confirm tall tiles for a side-view autotile sheet.
  local sheet = lurek.tilemap.newAutoTileSheet(16, 32, "minimal16")
  lurek.log.info("autotile h=" .. sheet:getTileHeight() .. " px", "tilemap")
end

--@api-stub: LChunkMap:getTile
-- Returns the tile GID at the given world-tile coordinate.
do
  -- Read a tile from the infinite world for collision checks.
  local world = lurek.tilemap.newChunkMap(16)
  world:setTile(5, 5, 42)
  local gid = world:getTile(5, 5)
  lurek.log.info("chunk tile at (5,5) gid=" .. gid, "tilemap")
end

--@api-stub: LChunkMap:setTile
-- Sets the tile GID at the given world-tile coordinate.
do
  -- Place a tree tile in the open world when the player plants a seed.
  local world = lurek.tilemap.newChunkMap(16)
  world:setTile(-10, 20, 15)
  lurek.log.info("planted tree at (-10,20)", "tilemap")
end

--@api-stub: LChunkMap:getChunkSize
-- Returns the size of each chunk in tiles per side.
do
  -- Calculate total tiles per chunk for memory estimation.
  local world = lurek.tilemap.newChunkMap(32)
  local cs = world:getChunkSize()
  lurek.log.info("tiles per chunk = " .. cs * cs, "tilemap")
end

--@api-stub: LIsoMap:getWidth
-- Returns the map width in tiles. This method is available to Lua scripts.
do
  -- Use width for iterating over all columns in the iso map.
  local iso = lurek.tilemap.newIsoMap(24, 18, 64, 32, 24)
  lurek.log.info("iso width=" .. iso:getWidth() .. " tiles", "tilemap")
end

--@api-stub: LIsoMap:getHeight
-- Returns the map height in tiles. This method is available to Lua scripts.
do
  -- Use height for iterating over all rows in the iso map.
  local iso = lurek.tilemap.newIsoMap(24, 18, 64, 32, 24)
  lurek.log.info("iso height=" .. iso:getHeight() .. " tiles", "tilemap")
end

--@api-stub: LMapBlock:getName
-- Returns the block's name. This method is available to Lua scripts.
do
  -- Identify which procedural block was placed during generation.
  local block = lurek.tilemap.newMapBlock(8, 8, 1, 4)
  block:setName("corridor_ew")
  lurek.log.info("block name=" .. block:getName(), "tilemap")
end

--@api-stub: LTileMap:getLayerCount
-- Returns the total number of layers in this map.
do
  -- Iterate all layers for serialization.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("bg", 32, 32)
  map:addLayer("fg", 32, 32)
  lurek.log.info("total layers=" .. map:getLayerCount(), "tilemap")
end

--@api-stub: LTileMap:setTile
-- Sets the tile GID at a specific grid position on a layer.
do
  -- Place a chest tile at the end of a corridor.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("objects", 20, 20)
  map:setTile(1, 10, 10, 42)
  lurek.log.info("chest placed at (10,10)", "tilemap")
end

--@api-stub: LTileMap:getTile
-- Returns the tile GID at a specific grid position on a layer.
do
  -- Check if a position already has a tile before placing.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("ground", 16, 16)
  local gid = map:getTile(1, 5, 5)
  lurek.log.info("tile at (5,5) gid=" .. gid, "tilemap")
end

--@api-stub: LTileMap:clearTile
-- Removes the tile at a specific grid position, setting it to empty (GID 0).
do
  -- Destroy a wall tile when player uses a bomb.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("walls", 16, 16)
  map:setTile(1, 8, 8, 5)
  map:clearTile(1, 8, 8)
  lurek.log.info("wall destroyed at (8,8)", "tilemap")
end

--@api-stub: LTileMap:setViewport
-- Sets the visible area of the map for culling during rendering.
do
  -- Match viewport to camera view for efficient rendering.
  local map = lurek.tilemap.newTileMap(16, 16)
  map:addLayer("bg", 64, 64)
  map:setViewport(100, 50, 320, 240)
  lurek.log.info("viewport set to camera view", "tilemap")
end

--@api-stub: LTileMap:getTileWidth
-- Returns the width of a single tile in pixels for this map.
do
  -- Calculate world-space position from tile coordinate.
  local map = lurek.tilemap.newTileMap(32, 32)
  local px = 5 * map:getTileWidth()
  lurek.log.info("tile col 5 starts at x=" .. px, "tilemap")
end

--@api-stub: LTileMap:getTileHeight
-- Returns the height of a single tile in pixels for this map.
do
  -- Calculate entity snap-to-grid offset.
  local map = lurek.tilemap.newTileMap(16, 24)
  lurek.log.info("row height=" .. map:getTileHeight() .. " px", "tilemap")
end

--@api-stub: LTileMap:getChunkSize
-- Returns the chunk size used for internal tile storage.
do
  -- Log storage parameters for debugging memory usage.
  local map = lurek.tilemap.newTileMap(16, 16, 64)
  lurek.log.info("internal chunk=" .. map:getChunkSize() .. " tiles/side", "tilemap")
end

--@api-stub: LTileSet:getTileCount
-- Returns the total number of tiles defined in this tileset.
do
  -- Iterate all tiles for a minimap legend.
  local ts = lurek.tilemap.newTileSet(1, 128, 16, 16, 16)
  lurek.log.info("tileset has " .. ts:getTileCount() .. " tiles", "tilemap")
end

--@api-stub: LTileSet:getTileWidth
-- Returns the width of a single tile in pixels.
do
  -- Confirm tile size matches rendering expectations.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 24, 24)
  lurek.log.info("tile pixel width=" .. ts:getTileWidth(), "tilemap")
end

--@api-stub: LTileSet:getTileHeight
-- Returns the height of a single tile in pixels.
do
  -- Use tile height for vertical collision offset.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 32)
  lurek.log.info("tile pixel height=" .. ts:getTileHeight(), "tilemap")
end

--@api-stub: LTileSet:getTileDimensions
-- Returns both tile width and height in pixels.
do
  -- Get both dimensions in one call for aspect ratio check.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local w, h = ts:getTileDimensions()
  lurek.log.info("tile dims=" .. w .. "x" .. h, "tilemap")
end

--@api-stub: LTileSet:getQuad
-- Returns the source rectangle (UV quad) for a tile in the atlas.
do
  -- Read atlas rect for custom batch drawing.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  local q = ts:getQuad(3)
  lurek.log.info("tile 3 atlas rect x=" .. q.x .. " y=" .. q.y, "tilemap")
end

--@api-stub: LTileSet:isSolid
-- Checks whether a tile is marked as solid.
do
  -- Verify solidity before allowing player movement onto a tile.
  local ts = lurek.tilemap.newTileSet(1, 64, 8, 16, 16)
  ts:setSolid(10, true)
  if ts:isSolid(10) then
    lurek.log.info("tile 10 blocks movement", "tilemap")
  end
end
