-- content/examples/procgen.lua
-- lurek.procgen API examples.
-- Run: cargo run -- content/examples/procgen.lua

--@api-stub: lurek.procgen.cellularAutomata
-- Generate a cave or organic map using cellular automata rules
do
  local w, h = 64, 48
  local cave = lurek.procgen.cellularAutomata(w, h, { fill = 0.45, iterations = 5, seed = 1337 })
  local floor_count = 0
  for i = 1, #cave do if cave[i] == 0 then floor_count = floor_count + 1 end end
  lurek.log.info("cave generated: " .. floor_count .. " walkable cells of " .. (w * h), "procgen")
end

--@api-stub: lurek.procgen.floodFill
-- Flood-fill a grid from a starting cell, marking all connected cells that pass a threshold test
do
  local w, h = 16, 16
  local grid = {}
  for i = 1, w * h do grid[i] = 0 end
  local mask = lurek.procgen.floodFill(grid, w, h, 1, 1, 128, false)
  lurek.log.debug("flood reached " .. #mask .. " cells from (1,1)", "procgen")
end

--@api-stub: lurek.procgen.perlinNoise
-- Sample periodic 2D Perlin noise at a given coordinate
do
  local px, py = 8.0, 8.0
  local n = lurek.procgen.perlinNoise(2.5, 3.1, px, py)
  if n > 0 then lurek.log.debug("perlin sample positive: " .. n, "procgen") end
end

--@api-stub: lurek.procgen.poissonDisk
-- Generate evenly-spaced random points using Poisson disk sampling
do
  local pts = lurek.procgen.poissonDisk(800, 600, 32, 30, 42)
  for i = 1, math.min(3, #pts) do
    lurek.log.debug("tree at " .. pts[i].x .. "," .. pts[i].y, "procgen")
  end
end

--@api-stub: lurek.procgen.voronoi
-- Compute a Voronoi diagram from a set of seed points
do
  local seeds = { { x = 16, y = 16 }, { x = 48, y = 16 }, { x = 32, y = 48 } }
  local regions, dist, dist2 = lurek.procgen.voronoi(64, 64, seeds, { metric = "euclidean" })
  lurek.log.info("voronoi regions=" .. #regions .. " near=" .. dist[1] .. " next=" .. dist2[1], "procgen")
end

--@api-stub: lurek.procgen.bspDungeon
-- Generate a dungeon layout using Binary Space Partitioning
do
  local d = lurek.procgen.bspDungeon({ width = 80, height = 50, min_size = 8, max_depth = 4, seed = 7 })
  local first = d.rooms[1]
  lurek.log.info("bsp dungeon: " .. #d.rooms .. " rooms, " .. #d.corridors .. " corridors", "procgen")
  lurek.log.debug("first room at " .. first.x .. "," .. first.y .. " size " .. first.w .. "x" .. first.h, "procgen")
end

--@api-stub: lurek.procgen.roomsDungeon
-- Generate a dungeon by placing random non-overlapping rooms and connecting them with corridors
do
  local d = lurek.procgen.roomsDungeon({ width = 60, height = 40, max_rooms = 12, min_room_size = 4, max_room_size = 9, seed = 2 })
  local floors = 0
  for i = 1, #d.grid do if d.grid[i] == 1 then floors = floors + 1 end end
  lurek.log.info("rooms dungeon: " .. #d.rooms .. " rooms, " .. floors .. " floor tiles", "procgen")
end

--@api-stub: lurek.procgen.roomsDungeonWithPrefabs
-- Generate a rooms-based dungeon and place named prefabs into qualifying rooms
do
  local prefabs = {
    { name = "altar", width = 3, height = 3, mask = {
      0,1,0,
      1,1,1,
      0,1,0,
    } }
  }
  local d, placements = lurek.procgen.roomsDungeonWithPrefabs({ width = 40, height = 30, max_rooms = 8, seed = 21 }, prefabs, 3)
  lurek.log.info("prefab rooms: " .. #d.rooms .. ", placements=" .. #placements, "procgen")
end

--@api-stub: lurek.procgen.heightmap
-- Generate a fractal heightmap using multi-octave noise with optional hydraulic erosion
do
  local hm = lurek.procgen.heightmap({ width = 128, height = 128, scale = 0.05, octaves = 4, persistence = 0.5, seed = 99 })
  local mid = hm.cells[(hm.height / 2) * hm.width + (hm.width / 2)]
  lurek.log.info("heightmap " .. hm.width .. "x" .. hm.height .. " centre=" .. mid, "procgen")
end

--@api-stub: lurek.procgen.heightmapFromCellular
-- Convert a cellular automata grid into a heightmap by distance-transforming the floor cells
do
  local w, h = 8, 8
  local cells = {}
  for i = 1, w * h do cells[i] = (i % 3 == 0) and 1 or 0 end
  local hm = lurek.procgen.heightmapFromCellular(w, h, cells, 0)
  lurek.log.debug("heightmapFromCellular cells=" .. #hm.cells, "procgen")
end

--@api-stub: lurek.procgen.wfcGenerate
-- Run Wave Function Collapse to generate a grid of tile IDs satisfying adjacency constraints
do
  local tiles = { { id = 1, weight = 1.0 }, { id = 2, weight = 0.5 } }
  local adj   = { [1] = { 1, 2 }, [2] = { 1, 2 } }
  local grid  = lurek.procgen.wfcGenerate({ width = 12, height = 12, tiles = tiles, adjacencies = adj, seed = 1, max_attempts = 5 })
  lurek.log.info("wfc grid " .. grid.width .. "x" .. grid.height .. " first=" .. grid.cells[1], "procgen")
end

--@api-stub: lurek.procgen.lsystem
-- Expand an L-system grammar and return the resulting string
do
  local rules = { F = "F+F-F-F+F" }
  local s = lurek.procgen.lsystem({ axiom = "F", rules = rules, iterations = 3 })
  lurek.log.debug("lsystem string length=" .. #s, "procgen")
end

--@api-stub: lurek.procgen.lsystemSegments
-- Expand an L-system and interpret the result as turtle-graphics commands, returning line segments
do
  local rules = { F = "FF+[+F-F-F]-[-F+F+F]" }
  local segs = lurek.procgen.lsystemSegments({ axiom = "F", rules = rules, iterations = 3 }, 22.5, 4.0)
  lurek.log.info("plant has " .. #segs .. " line segments", "procgen")
end

--@api-stub: lurek.procgen.generateName
-- Generate a single random name based on a Markov chain trained from sample names
do
  local samples = { "Eldoria", "Mythos", "Arden", "Brindlemar", "Caelum", "Drakov", "Eowyn" }
  local name = lurek.procgen.generateName(samples, 4, 9, 17)
  lurek.log.info("npc named '" .. name .. "'", "procgen")
end

--@api-stub: lurek.procgen.newBiomeClassifier
-- Create a BiomeClassifier object with custom threshold rules for mapping height/moisture/temperature to biome types
do
  local bc = lurek.procgen.newBiomeClassifier({ ocean_threshold = 0.25, warm_temperature = 0.7 })
  lurek.log.debug("biome classifier ready: " .. bc:type(), "procgen")
end

--@api-stub: BiomeClassifier:classify
-- Classify a single point into a biome type based on its environmental parameters
do
  local bc = lurek.procgen.newBiomeClassifier()
  local biome = bc:classify(0.62, 0.35, 0.72)
  lurek.log.info("sample biome=" .. biome, "procgen")
end

--@api-stub: BiomeClassifier:classifyMap
-- Classify an entire grid of points into biome types in bulk
do
  local bc = lurek.procgen.newBiomeClassifier()
  local w, h = 2, 2
  local heights = { 0.1, 0.3, 0.6, 0.9 }
  local moisture = { 0.8, 0.3, 0.2, 0.4 }
  local temperature = { 0.5, 0.7, 0.8, 0.2 }
  local biomes = bc:classifyMap(w, h, heights, moisture, temperature)
  lurek.log.debug("classifyMap produced " .. #biomes .. " cells", "procgen")
end

--@api-stub: BiomeClassifier:type
-- Returns the type name of this object
do
  local bc = lurek.procgen.newBiomeClassifier()
  local t = bc:type()
  lurek.log.debug("biome type=" .. t, "procgen")
end

--@api-stub: BiomeClassifier:typeOf
-- Check whether this object matches a given type name
do
  local bc = lurek.procgen.newBiomeClassifier()
  local ok = bc:typeOf("BiomeClassifier")
  if not ok then lurek.log.warn("unexpected biome classifier type", "procgen") end
end

--@api-stub: lurek.procgen.biomeColor
-- Get the default RGBA display color for a biome type name
do
  local r, g, b, a = lurek.procgen.biomeColor("desert")
  lurek.log.debug("desert rgba=" .. r .. "," .. g .. "," .. b .. "," .. a, "procgen")
end

--@api-stub: lurek.procgen.generateNames
-- Generate multiple random names in one call using Markov chains trained from sample data
do
  local samples = { "Frostpeak", "Ironhold", "Stormwall", "Embervale", "Greyfen", "Hollowmere" }
  local towns = lurek.procgen.generateNames(samples, 5, 5, 12, 4)
  for i = 1, #towns do lurek.log.debug("town " .. i .. ": " .. towns[i], "procgen") end
end

--@api-stub: lurek.procgen.worldGraph
-- Generate a connected world graph with named regions and weighted edges
do
  local wg = lurek.procgen.worldGraph(1024, 768, 8, 5)
  local first = wg.regions[1]
  lurek.log.info("world has " .. #wg.regions .. " regions and " .. #wg.edges .. " edges", "procgen")
  lurek.log.debug("region 1 '" .. first.name .. "' at " .. first.x .. "," .. first.y, "procgen")
end

--@api-stub: lurek.procgen.noiseMap
-- Generate a 2D noise map with configurable scale, octaves, and offsets
do
  local map = lurek.procgen.noiseMap(64, 64, { scale_x = 0.08, scale_y = 0.08, octaves = 3, persistence = 0.5, seed = 11 })
  lurek.log.info("noise map " .. #map .. " samples, first=" .. map[1], "procgen")
end

--@api-stub: lurek.procgen.noiseMapParallel
-- Generate a 2D noise map using multiple threads for faster computation on large maps
do
  local big = lurek.procgen.noiseMapParallel(256, 256, { scale_x = 0.02, scale_y = 0.02, octaves = 5, lacunarity = 2.0 })
  local sample = big[#big / 2]
  lurek.log.info("parallel noise map size=" .. #big .. " mid=" .. sample, "procgen")
end

--@api-stub: lurek.procgen.noiseMapParallelSeeded
-- Generate a 2D noise map using multiple threads with a specific seed for reproducible results
do
  local map = lurek.procgen.noiseMapParallelSeeded(64, 64, { scale_x = 0.04, scale_y = 0.04, octaves = 4, seed = 12345 })
  lurek.log.debug("seeded parallel noise first=" .. map[1], "procgen")
end

--@api-stub: lurek.procgen.bspDungeonWithPrefabs
-- Generate a BSP dungeon and stamp named prefab rooms into suitable leaves
do
  local prefabs = {
    { name = "boss_room", width = 5, height = 5 },
    { name = "chest_room", width = 3, height = 3 },
  }
  local d, p = lurek.procgen.bspDungeonWithPrefabs({ width = 60, height = 40, max_depth = 4, seed = 9 }, prefabs)
  lurek.log.info("bsp rooms=" .. #d.rooms .. " prefab placements=" .. #p, "procgen")
end

--@api-stub: lurek.procgen.simplex2d
-- Sample 2D simplex noise at a point
do
  local n = lurek.procgen.simplex2d(12.5, 7.25)
  if math.abs(n) > 0.5 then lurek.log.debug("strong simplex2d response: " .. n, "procgen") end
end

--@api-stub: lurek.procgen.simplex3d
-- Sample 3D simplex noise at a point
do
  local t = 0.0
  local n = lurek.procgen.simplex3d(4.0, 4.0, t)
  lurek.log.debug("simplex3d sample at t=" .. t .. " -> " .. n, "procgen")
end
-- content/examples/procgen.lua
-- EXAMPLEed coverage of the lurek.procgen API (29 items).
--
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/procgen_api.rs   (Lua binding, arg types, return shape)
--   * src/procgen/                 (semantics, side effects)
--   * docs/specs/procgen.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.draw() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/procgen.lua

-- lurek.procgen.* functions
