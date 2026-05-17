-- content/examples/procgen.lua
-- Procedural generation API: noise, dungeons, WFC, L-systems, biomes, names, world graphs.
-- Run: cargo run -- content/examples/procgen.lua

--@api-stub: lurek.procgen.cellularAutomata
-- Generate a cave map using cellular automata rules
do
  -- Use cellular automata to carve natural-looking cave systems.
  -- fill = initial wall density, iterations = smoothing passes.
  local w, h = 80, 60
  local cave = lurek.procgen.cellularAutomata(w, h, {
    fill = 0.45,
    iterations = 5,
    seed = 1337,
  })
  -- Count walkable tiles to ensure the cave is playable
  local floor_count = 0
  for i = 1, #cave do
    if cave[i] == 0 then floor_count = floor_count + 1 end
  end
  local pct = math.floor(floor_count / (w * h) * 100)
  lurek.log.info("cave: " .. floor_count .. " walkable tiles (" .. pct .. "% open)", "procgen")
end

--@api-stub: lurek.procgen.floodFill
-- Flood-fill a grid from a starting cell to find connected regions
do
  -- Useful for validating cave connectivity: fill from the player spawn
  -- and check whether all floor tiles are reachable.
  local w, h = 32, 32
  local grid = lurek.procgen.cellularAutomata(w, h, { fill = 0.4, iterations = 4, seed = 55 })
  -- Find first open cell as spawn point (startX/startY are 0-based)
  local sx, sy = 0, 0
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      if grid[y * w + x + 1] == 0 then
        sx, sy = x, y
        goto found
      end
    end
  end
  ::found::
  -- Fill from spawn; threshold=1, above=false means fill cells < 1 (i.e. floor=0)
  local mask = lurek.procgen.floodFill(grid, w, h, sx, sy, 1, false)
  local reachable = 0
  for i = 1, #mask do if mask[i] == 1 then reachable = reachable + 1 end end
  lurek.log.info("flood fill from (" .. sx .. "," .. sy .. "): " .. reachable .. " reachable cells", "procgen")
end

--@api-stub: lurek.procgen.perlinNoise
-- Sample periodic 2D Perlin noise for tileable terrain
do
  -- Periodic Perlin noise tiles seamlessly across map edges.
  -- periodX/periodY control the tiling repeat distance.
  local period_x, period_y = 8.0, 8.0
  local sample_x, sample_y = 2.5, 3.1
  local n = lurek.procgen.perlinNoise(sample_x, sample_y, period_x, period_y)
  -- Use noise to decide terrain type at this tile
  local terrain = "grass"
  if n > 0.4 then terrain = "rock"
  elseif n < -0.3 then terrain = "water" end
  lurek.log.info("tile(" .. sample_x .. "," .. sample_y .. ") noise=" .. string.format("%.3f", n) .. " -> " .. terrain, "procgen")
end

--@api-stub: lurek.procgen.poissonDisk
-- Place trees/items with even spacing using Poisson disk sampling
do
  -- Generates natural-looking point distributions for object placement.
  -- minDist=40 means no two trees closer than 40px apart.
  local map_w, map_h = 800, 600
  local min_dist = 40
  local trees = lurek.procgen.poissonDisk(map_w, map_h, min_dist, 30, 42)
  lurek.log.info("placed " .. #trees .. " trees across " .. map_w .. "x" .. map_h .. " map", "procgen")
  -- Each point has .x and .y fields ready for sprite placement
  for i = 1, math.min(3, #trees) do
    lurek.log.debug("  tree " .. i .. " at (" .. string.format("%.1f", trees[i].x) .. ", " .. string.format("%.1f", trees[i].y) .. ")", "procgen")
  end
end

--@api-stub: lurek.procgen.voronoi
-- Compute a Voronoi diagram for biome regions or territory maps
do
  -- Voronoi divides space into regions closest to each seed point.
  -- Great for territory borders, biome zones, or shattered terrain.
  local w, h = 128, 128
  local seeds = {
    { x = 32, y = 32 },
    { x = 96, y = 32 },
    { x = 64, y = 96 },
    { x = 20, y = 80 },
    { x = 100, y = 80 },
  }
  -- warp_strength adds organic distortion to the borders
  local regions, dist_near, dist_far = lurek.procgen.voronoi(w, h, seeds, {
    warp_strength = 0.3,
    seed = 7,
  })
  -- dist_far - dist_near gives edge proximity (useful for border rendering)
  local border_cells = 0
  for i = 1, #dist_near do
    if (dist_far[i] - dist_near[i]) < 3.0 then border_cells = border_cells + 1 end
  end
  lurek.log.info("voronoi: " .. #seeds .. " regions, " .. border_cells .. " border cells", "procgen")
end

--@api-stub: lurek.procgen.bspDungeon
-- Generate a dungeon layout using Binary Space Partitioning
do
  -- BSP splits the area recursively, then places rooms in each leaf.
  -- max_depth controls room count; min_size prevents tiny rooms.
  local dungeon = lurek.procgen.bspDungeon({
    width = 80,
    height = 50,
    min_size = 8,
    max_depth = 5,
    seed = 7,
    padding = 1,
  })
  lurek.log.info("bsp dungeon: " .. #dungeon.rooms .. " rooms, " .. #dungeon.corridors .. " corridors", "procgen")
  -- Place player in the first room's center
  local spawn = dungeon.rooms[1]
  local px = spawn.x + math.floor(spawn.w / 2)
  local py = spawn.y + math.floor(spawn.h / 2)
  lurek.log.debug("  player spawn: (" .. px .. ", " .. py .. ")", "procgen")
end

--@api-stub: lurek.procgen.bspDungeonWithPrefabs
-- Generate a BSP dungeon with special prefab rooms stamped into leaves
do
  -- Prefab rooms let you place handcrafted content (boss arenas, shops)
  -- into procedural layouts for a mix of authored + generated feel.
  local prefabs = {
    { name = "boss_arena", width = 6, height = 6 },
    { name = "treasure_vault", width = 4, height = 3 },
  }
  local dungeon, placements = lurek.procgen.bspDungeonWithPrefabs(
    { width = 60, height = 40, max_depth = 4, seed = 9 },
    prefabs
  )
  local dungeon_result = dungeon --[[@as {rooms: table}]]
  lurek.log.info("bsp+prefabs: " .. #dungeon_result.rooms .. " rooms", "procgen")
  for _, p in ipairs(placements) do
    lurek.log.debug("  placed '" .. p.name .. "' at (" .. p.x .. "," .. p.y .. ")", "procgen")
  end
end

--@api-stub: lurek.procgen.roomsDungeon
-- Generate a dungeon with random non-overlapping rooms and corridors
do
  -- Simpler than BSP: place rooms randomly, reject overlaps, then
  -- connect each room to the previous one with L-shaped corridors.
  local dungeon = lurek.procgen.roomsDungeon({
    width = 60,
    height = 40,
    max_rooms = 12,
    min_room_size = 5,
    max_room_size = 10,
    seed = 2,
  })
  -- .grid is a flat tilemap: 0=wall, 1=floor
  local walls, floors = 0, 0
  for i = 1, #dungeon.grid do
    if dungeon.grid[i] == 1 then floors = floors + 1 else walls = walls + 1 end
  end
  lurek.log.info("rooms dungeon: " .. #dungeon.rooms .. " rooms, " .. floors .. " floor tiles", "procgen")
end

--@api-stub: lurek.procgen.roomsDungeonWithPrefabs
-- Generate a rooms dungeon and stamp shaped prefabs into qualifying rooms
do
  -- Prefabs can have masks (shaped footprints) that get stamped onto the grid.
  -- stampValue controls what tile value the prefab cells become.
  local prefabs = {
    { name = "altar", width = 3, height = 3, mask = {
      0, 1, 0,
      1, 1, 1,
      0, 1, 0,
    } },
    { name = "pillar_hall", width = 5, height = 3, mask = {
      1, 0, 1, 0, 1,
      1, 1, 1, 1, 1,
      1, 0, 1, 0, 1,
    } },
  }
  local dungeon, placements = lurek.procgen.roomsDungeonWithPrefabs(
    { width = 50, height = 35, max_rooms = 10, seed = 21 },
    prefabs,
    3  -- stampValue: prefab cells become tile 3 in the grid
  )
  local dungeon_result = dungeon --[[@as {rooms: table}]]
  lurek.log.info("prefab dungeon: " .. #dungeon_result.rooms .. " rooms, " .. #placements .. " prefabs placed", "procgen")
end

--@api-stub: lurek.procgen.heightmap
-- Generate a fractal heightmap for terrain with optional erosion
do
  -- Multi-octave noise creates natural terrain. Erosion carves rivers.
  local hm = lurek.procgen.heightmap({
    width = 128,
    height = 128,
    scale = 0.04,
    octaves = 5,
    persistence = 0.5,
    lacunarity = 2.0,
    seed = 99,
    erosion_passes = 3,
  })
  -- Find min/max to normalize for display or gameplay logic
  local min_h, max_h = 1.0, 0.0
  for i = 1, #hm.cells do
    if hm.cells[i] < min_h then min_h = hm.cells[i] end
    if hm.cells[i] > max_h then max_h = hm.cells[i] end
  end
  lurek.log.info("heightmap " .. hm.width .. "x" .. hm.height .. " range=[" .. string.format("%.2f", min_h) .. ", " .. string.format("%.2f", max_h) .. "]", "procgen")
end

--@api-stub: lurek.procgen.heightmapFromCellular
-- Convert a cave grid into a heightmap via distance transform
do
  -- Converts binary cave data into smooth gradients.
  -- Useful for lighting falloff or elevation-based gameplay.
  local w, h = 32, 32
  local cave = lurek.procgen.cellularAutomata(w, h, { fill = 0.45, iterations = 4, seed = 88 })
  local hm = lurek.procgen.heightmapFromCellular(w, h, cave, 0)
  -- Cells near walls have low height, open areas have high height
  local centre = hm.cells[math.floor(h / 2) * w + math.floor(w / 2)]
  lurek.log.info("cave heightmap centre value=" .. string.format("%.3f", centre), "procgen")
end

--@api-stub: lurek.procgen.wfcGenerate
-- Run Wave Function Collapse to generate constrained tile layouts
do
  -- WFC ensures every tile placement respects adjacency rules.
  -- Great for auto-generating coherent tilemap levels.
  local tiles = {
    { id = 1, weight = 1.0 },  -- ground
    { id = 2, weight = 0.3 },  -- water
    { id = 3, weight = 0.5 },  -- sand (transition)
  }
  -- Define which tiles can appear next to each other
  local adjacencies = {
    [1] = { 1, 3 },     -- ground neighbors: ground, sand
    [2] = { 2, 3 },     -- water neighbors: water, sand
    [3] = { 1, 2, 3 },  -- sand neighbors: anything (transition tile)
  }
  local result = lurek.procgen.wfcGenerate({
    width = 16,
    height = 16,
    tiles = tiles,
    adjacencies = adjacencies,
    seed = 1,
    max_attempts = 10,
  })
  -- Count tile distribution
  local counts = { [1] = 0, [2] = 0, [3] = 0 }
  for i = 1, #result.cells do
    local id = result.cells[i]
    if counts[id] then counts[id] = counts[id] + 1 end
  end
  lurek.log.info("wfc " .. result.width .. "x" .. result.height .. ": ground=" .. counts[1] .. " water=" .. counts[2] .. " sand=" .. counts[3], "procgen")
end

--@api-stub: lurek.procgen.lsystem
-- Expand an L-system grammar for branching structure generation
do
  -- L-systems produce self-similar patterns ideal for vegetation,
  -- river networks, or cave branching paths.
  local rules = { F = "F+F-F-F+F" }
  local result = lurek.procgen.lsystem({
    axiom = "F",
    rules = rules,
    iterations = 3,
  })
  -- The string encodes movement: F=forward, +=turn left, -=turn right
  lurek.log.info("lsystem output length=" .. #result .. " chars (Koch curve variant)", "procgen")
end

--@api-stub: lurek.procgen.lsystemSegments
-- Expand an L-system into drawable line segments (turtle graphics)
do
  -- Interprets an L-system as turtle commands and returns line segments.
  -- Perfect for procedural trees, lightning bolts, or crack patterns.
  local rules = { F = "FF+[+F-F-F]-[-F+F+F]" }
  local segments = lurek.procgen.lsystemSegments(
    { axiom = "F", rules = rules, iterations = 4 },
    25.0,  -- turn angle in degrees
    5.0    -- step length in pixels
  )
  -- Each segment has {x1, y1, x2, y2} ready for line drawing
  lurek.log.info("procedural tree: " .. #segments .. " branch segments", "procgen")
  if #segments > 0 then
    local s = segments[1]
    lurek.log.debug("  first segment: (" .. string.format("%.1f", s.x1) .. "," .. string.format("%.1f", s.y1) .. ") -> (" .. string.format("%.1f", s.x2) .. "," .. string.format("%.1f", s.y2) .. ")", "procgen")
  end
end

--@api-stub: lurek.procgen.generateName
-- Generate a single random fantasy name from sample data
do
  -- Train a Markov chain on sample names, then generate new ones
  -- that feel similar but are unique. Great for NPCs, towns, items.
  local elf_names = { "Aelindra", "Thalion", "Caladwen", "Elowen", "Galadhon", "Nimrodel", "Idril" }
  local name = lurek.procgen.generateName(elf_names, 4, 9, 17)
  lurek.log.info("generated elf name: '" .. name .. "'", "procgen")
end

--@api-stub: lurek.procgen.generateNames
-- Generate multiple random names in one batch
do
  -- Batch generation is faster than calling generateName in a loop.
  -- Use different sample sets for different cultures or item types.
  local dwarf_samples = { "Thorin", "Gimli", "Durin", "Balin", "Dwalin", "Gloin", "Bofur", "Bombur" }
  local party = lurek.procgen.generateNames(dwarf_samples, 5, 4, 8, 42)
  lurek.log.info("dwarf party roster:", "procgen")
  for i = 1, #party do
    lurek.log.debug("  " .. i .. ". " .. party[i], "procgen")
  end
end

--@api-stub: lurek.procgen.newBiomeClassifier
-- Create a BiomeClassifier with custom threshold rules
do
  -- Configure how height/moisture/temperature map to biome types.
  -- Tweak thresholds to control how much ocean, desert, or tundra appears.
  local bc = lurek.procgen.newBiomeClassifier({
    ocean_threshold = 0.3,       -- below this height = ocean
    coast_threshold = 0.35,      -- between ocean and coast = beach
    mountain_threshold = 0.85,   -- above this = mountain
    cold_temperature = 0.2,      -- below = cold biomes
    warm_temperature = 0.7,      -- above = warm biomes
    dry_moisture = 0.3,          -- below = arid biomes
    wet_moisture = 0.7,          -- above = wet biomes
  })
  lurek.log.info("biome classifier created: " .. bc:type(), "procgen")
end

--@api-stub: BiomeClassifier:classify
-- Classify a single terrain point into a biome type
do
  -- Pass height, moisture, and temperature (each 0.0-1.0).
  -- Returns a biome name string for gameplay or rendering logic.
  local bc = lurek.procgen.newBiomeClassifier()
  -- High altitude, low moisture, cold = tundra or mountain
  local mountain_biome = bc:classify(0.9, 0.2, 0.1)
  -- Low altitude, high moisture, warm = tropical
  local tropical_biome = bc:classify(0.4, 0.9, 0.8)
  -- Very low altitude = ocean
  local ocean_biome = bc:classify(0.1, 0.5, 0.5)
  lurek.log.info("biomes: mountain=" .. mountain_biome .. " tropical=" .. tropical_biome .. " ocean=" .. ocean_biome, "procgen")
end

--@api-stub: BiomeClassifier:classifyMap
-- Classify an entire grid of terrain points into biomes in bulk
do
  -- Bulk classification is much faster than calling :classify() per cell.
  -- Feed in parallel arrays of height, moisture, and temperature.
  local bc = lurek.procgen.newBiomeClassifier()
  local w, h = 4, 4
  local heights = {}
  local moisture = {}
  local temperature = {}
  -- Generate simple gradient data for demonstration
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local i = y * w + x + 1
      heights[i] = (x + y) / (w + h - 2)      -- rises toward bottom-right
      moisture[i] = x / (w - 1)                 -- wet on right
      temperature[i] = 1.0 - (y / (h - 1))     -- warm at top
    end
  end
  local biomes = bc:classifyMap(w, h, heights, moisture, temperature)
  lurek.log.info("classifyMap: " .. #biomes .. " cells, corners: TL=" .. biomes[1] .. " BR=" .. biomes[#biomes], "procgen")
end

--@api-stub: BiomeClassifier:type
-- Returns the type name of the classifier object
do
  local bc = lurek.procgen.newBiomeClassifier()
  local t = bc:type()
  lurek.log.debug("classifier type: " .. t, "procgen")
end

--@api-stub: BiomeClassifier:typeOf
-- Check whether this object matches a given type name
do
  -- Useful for polymorphic code that handles multiple object types.
  local bc = lurek.procgen.newBiomeClassifier()
  local is_classifier = bc:typeOf("BiomeClassifier")
  local is_sprite = bc:typeOf("Sprite")
  lurek.log.debug("is BiomeClassifier=" .. tostring(is_classifier) .. ", is Sprite=" .. tostring(is_sprite), "procgen")
end

--@api-stub: lurek.procgen.biomeColor
-- Get the default display color for a biome name (for minimaps/debug views)
do
  -- Returns RGBA 0-255 values for common biome names.
  -- Use these as defaults; override with your own palette if needed.
  local biome_names = { "ocean", "desert", "grassland", "taiga", "tundra" }
  for _, name in ipairs(biome_names) do
    local r, g, b, a = lurek.procgen.biomeColor(name)
    lurek.log.debug("  " .. name .. " -> rgba(" .. r .. "," .. g .. "," .. b .. "," .. a .. ")", "procgen")
  end
end

--@api-stub: lurek.procgen.worldGraph
-- Generate a connected world graph with named regions and trade routes
do
  -- Creates an overworld map structure with regions and weighted edges.
  -- Regions have names, positions, and tags; edges have travel cost.
  local world = lurek.procgen.worldGraph(1024, 768, 8, 5)
  lurek.log.info("world: " .. #world.regions .. " regions, " .. #world.edges .. " connections", "procgen")
  -- Print first few regions as example
  for i = 1, math.min(3, #world.regions) do
    local r = world.regions[i]
    lurek.log.debug("  region '" .. r.name .. "' at (" .. r.x .. "," .. r.y .. ")", "procgen")
  end
  -- Edges connect regions with travel cost (useful for pathfinding)
  if #world.edges > 0 then
    local e = world.edges[1]
    lurek.log.debug("  edge: region " .. e.from .. " <-> " .. e.to .. " cost=" .. e.cost, "procgen")
  end
end

--@api-stub: lurek.procgen.noiseMap
-- Generate a 2D noise map for terrain, moisture, or temperature layers
do
  -- Single-threaded noise map generation for smaller maps.
  -- Use separate noise maps for height, moisture, and temperature.
  local moisture_map = lurek.procgen.noiseMap(64, 64, {
    scale_x = 0.06,
    scale_y = 0.06,
    octaves = 3,
    persistence = 0.5,
    seed = 11,
  })
  -- Normalize noise values for biome input (noise is roughly -1 to 1)
  local min_v, max_v = moisture_map[1], moisture_map[1]
  for i = 2, #moisture_map do
    if moisture_map[i] < min_v then min_v = moisture_map[i] end
    if moisture_map[i] > max_v then max_v = moisture_map[i] end
  end
  lurek.log.info("noise map: " .. #moisture_map .. " samples, range=[" .. string.format("%.3f", min_v) .. "," .. string.format("%.3f", max_v) .. "]", "procgen")
end

--@api-stub: lurek.procgen.noiseMapParallel
-- Generate a large noise map using multiple threads for speed
do
  -- For large maps (256x256+), parallel generation is significantly faster.
  -- Uses seed=0 internally; use noiseMapParallelSeeded for reproducibility.
  local big_map = lurek.procgen.noiseMapParallel(256, 256, {
    scale_x = 0.02,
    scale_y = 0.02,
    octaves = 5,
    lacunarity = 2.0,
    persistence = 0.5,
  })
  -- Sample a few points to verify distribution
  local mid = big_map[256 * 128 + 128]
  lurek.log.info("parallel noise: " .. #big_map .. " cells, centre=" .. string.format("%.4f", mid), "procgen")
end

--@api-stub: lurek.procgen.noiseMapParallelSeeded
-- Generate a reproducible noise map using threads with a fixed seed
do
  -- Same as noiseMapParallel but with explicit seed for deterministic results.
  -- Essential for multiplayer or replay-based games.
  local map_a = lurek.procgen.noiseMapParallelSeeded(64, 64, {
    scale_x = 0.04,
    scale_y = 0.04,
    octaves = 4,
    seed = 12345,
  })
  local map_b = lurek.procgen.noiseMapParallelSeeded(64, 64, {
    scale_x = 0.04,
    scale_y = 0.04,
    octaves = 4,
    seed = 12345,
  })
  -- Same seed = same output, guaranteed
  local match = (map_a[1] == map_b[1]) and (map_a[100] == map_b[100])
  lurek.log.info("seeded parallel: deterministic=" .. tostring(match) .. " first=" .. string.format("%.4f", map_a[1]), "procgen")
end

--@api-stub: lurek.procgen.simplex2d
-- Sample 2D simplex noise for fast single-point queries
do
  -- Simplex noise is faster than Perlin for single-point sampling.
  -- Use it in update loops for real-time procedural effects.
  local terrain_height = lurek.procgen.simplex2d(12.5, 7.25)
  -- Remap from [-1,1] to [0,1] for gameplay use
  local normalized = (terrain_height + 1.0) * 0.5
  local is_water = normalized < 0.3
  lurek.log.info("simplex2d at (12.5, 7.25): raw=" .. string.format("%.3f", terrain_height) .. " water=" .. tostring(is_water), "procgen")
end

--@api-stub: lurek.procgen.simplex3d
-- Sample 3D simplex noise (use z-axis for animation or layering)
do
  -- The third axis is perfect for animating noise over time.
  -- Each frame, increment z slightly for flowing lava, clouds, etc.
  local time = 0.0
  local x, y = 4.0, 4.0
  local cloud_density = lurek.procgen.simplex3d(x, y, time)
  -- Simulate a few frames of cloud movement
  local densities = {}
  for frame = 0, 4 do
    local t = frame * 0.1
    densities[frame + 1] = string.format("%.2f", lurek.procgen.simplex3d(x, y, t))
  end
  lurek.log.info("cloud evolution over 5 frames: " .. table.concat(densities, ", "), "procgen")
end

print("content/examples/procgen.lua")
