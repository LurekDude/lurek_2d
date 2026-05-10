-- content/examples/procgen.lua
-- Hand-written coverage of the lurek.procgen API (29 items).
--
-- Stateless world-building helpers: dungeon layouts, noise fields,
-- cave automata, Voronoi/Poisson scatter, name generation and L-systems.
-- Every function is pure (returns Lua tables / scalars), so snippets run
-- at file load time without an init/render callback.
--
-- Run: cargo run -- content/examples/procgen.lua

-- â”€â”€ lurek.procgen.* functions â”€â”€

--@api-stub: lurek.procgen.cellularAutomata
-- Generates a cave-like map using cellular automata.
-- Use to seed organic cave levels; the returned flat byte array is row-major width * height.
do -- lurek.procgen.cellularAutomata
  local w, h = 64, 48
  local cave = lurek.procgen.cellularAutomata(w, h, { fill = 0.45, iterations = 5, seed = 1337 })
  local floor_count = 0
  for i = 1, #cave do if cave[i] == 0 then floor_count = floor_count + 1 end end
  lurek.log.info("cave generated: " .. floor_count .. " walkable cells of " .. (w * h), "procgen")
end

--@api-stub: lurek.procgen.floodFill
-- BFS flood fill on a flat grid of bytes.
-- Pair with cellularAutomata to find the largest connected cave region; the result is a 0/1 mask.
do -- lurek.procgen.floodFill
  local w, h = 16, 16
  local grid = {}
  for i = 1, w * h do grid[i] = 0 end
  local mask = lurek.procgen.floodFill(grid, w, h, 1, 1, 128, false)
  lurek.log.debug("flood reached " .. #mask .. " cells from (1,1)", "procgen")
end

--@api-stub: lurek.procgen.perlinNoise
-- Evaluates periodic Perlin noise at a point.
-- Useful for tileable textures: sample the same px,py period to get a seamless wrap.
do -- lurek.procgen.perlinNoise
  local px, py = 8.0, 8.0
  local n = lurek.procgen.perlinNoise(2.5, 3.1, px, py)
  if n > 0 then lurek.log.debug("perlin sample positive: " .. n, "procgen") end
end

--@api-stub: lurek.procgen.poissonDisk
-- Generates Poisson disk sample points using Bridson's algorithm.
-- Use for non-overlapping props (trees, rocks); min_dist is in the same units as w/h.
do -- lurek.procgen.poissonDisk
  local pts = lurek.procgen.poissonDisk(800, 600, 32, 30, 42)
  for i = 1, math.min(3, #pts) do
    lurek.log.debug("tree at " .. pts[i].x .. "," .. pts[i].y, "procgen")
  end
end

--@api-stub: lurek.procgen.voronoi
-- Generates a Voronoi diagram for a set of seed points.
-- Returns three flat arrays (region id, distance, second-nearest distance) ideal for biome maps.
do -- lurek.procgen.voronoi
  local seeds = { { x = 16, y = 16 }, { x = 48, y = 16 }, { x = 32, y = 48 } }
  local regions, dist, dist2 = lurek.procgen.voronoi(64, 64, seeds, { metric = "euclidean" })
  lurek.log.info("voronoi regions=" .. #regions .. " near=" .. dist[1] .. " next=" .. dist2[1], "procgen")
end

--@api-stub: lurek.procgen.bspDungeon
-- Generates a dungeon using Binary Space Partitioning.
-- Good for top-down roguelikes; rooms is a list of {x,y,w,h} and corridors are line segments.
do -- lurek.procgen.bspDungeon
  local d = lurek.procgen.bspDungeon({ width = 80, height = 50, min_size = 8, max_depth = 4, seed = 7 })
  local first = d.rooms[1]
  lurek.log.info("bsp dungeon: " .. #d.rooms .. " rooms, " .. #d.corridors .. " corridors", "procgen")
  lurek.log.debug("first room at " .. first.x .. "," .. first.y .. " size " .. first.w .. "x" .. first.h, "procgen")
end

--@api-stub: lurek.procgen.roomsDungeon
-- Generates a rooms-and-corridors dungeon.
-- Returns rooms, corridors, AND a flat grid (1=floor, 0=wall) so you can paint a tilemap directly.
do -- lurek.procgen.roomsDungeon
  local d = lurek.procgen.roomsDungeon({ width = 60, height = 40, max_rooms = 12, min_room_size = 4, max_room_size = 9, seed = 2 })
  local floors = 0
  for i = 1, #d.grid do if d.grid[i] == 1 then floors = floors + 1 end end
  lurek.log.info("rooms dungeon: " .. #d.rooms .. " rooms, " .. floors .. " floor tiles", "procgen")
end

--@api-stub: lurek.procgen.heightmap
-- Generates a heightmap using fractal noise.
-- Tune octaves/persistence for terrain detail; erosion_passes adds simple thermal smoothing.
do -- lurek.procgen.heightmap
  local hm = lurek.procgen.heightmap({ width = 128, height = 128, scale = 0.05, octaves = 4, persistence = 0.5, seed = 99 })
  local mid = hm.cells[(hm.height / 2) * hm.width + (hm.width / 2)]
  lurek.log.info("heightmap " .. hm.width .. "x" .. hm.height .. " centre=" .. mid, "procgen")
end

--@api-stub: lurek.procgen.wfcGenerate
-- Generates a tile grid using Wave Function Collapse.
-- Provide tiles and adjacency rules; collapse may fail, so check for sentinel 0 cells.
do -- lurek.procgen.wfcGenerate
  local tiles = { { id = 1, weight = 1.0 }, { id = 2, weight = 0.5 } }
  local adj   = { [1] = { 1, 2 }, [2] = { 1, 2 } }
  local grid  = lurek.procgen.wfcGenerate({ width = 12, height = 12, tiles = tiles, adjacencies = adj, seed = 1, max_attempts = 5 })
  lurek.log.info("wfc grid " .. grid.width .. "x" .. grid.height .. " first=" .. grid.cells[1], "procgen")
end

--@api-stub: lurek.procgen.lsystem
-- Generates an L-system string.
-- Use for procedural plants/fractals; the output string drives lsystemSegments() for rendering.
do -- lurek.procgen.lsystem
  local rules = { F = "F+F-F-F+F" }
  local s = lurek.procgen.lsystem({ axiom = "F", rules = rules, iterations = 3 })
  lurek.log.debug("lsystem string length=" .. #s, "procgen")
end

--@api-stub: lurek.procgen.lsystemSegments
-- Generates L-system line segments for rendering.
-- Returns {x1,y1,x2,y2} pairs in turtle-graphics units; multiply by a scale factor to draw.
do -- lurek.procgen.lsystemSegments
  local rules = { F = "FF+[+F-F-F]-[-F+F+F]" }
  local segs = lurek.procgen.lsystemSegments({ axiom = "F", rules = rules, iterations = 3 }, 22.5, 4.0)
  lurek.log.info("plant has " .. #segs .. " line segments", "procgen")
end

--@api-stub: lurek.procgen.generateName
-- Generates a single procedural name using a Markov chain.
-- Feed 8+ samples for plausible output; min/max_len bound the result without truncating mid-word.
do -- lurek.procgen.generateName
  local samples = { "Eldoria", "Mythos", "Arden", "Brindlemar", "Caelum", "Drakov", "Eowyn" }
  local name = lurek.procgen.generateName(samples, 4, 9, 17)
  lurek.log.info("npc named '" .. name .. "'", "procgen")
end

--@api-stub: lurek.procgen.generateNames
-- Generates N procedural names using a Markov chain.
-- Cheaper than calling generateName N times because the chain is built once.
do -- lurek.procgen.generateNames
  local samples = { "Frostpeak", "Ironhold", "Stormwall", "Embervale", "Greyfen", "Hollowmere" }
  local towns = lurek.procgen.generateNames(samples, 5, 5, 12, 4)
  for i = 1, #towns do lurek.log.debug("town " .. i .. ": " .. towns[i], "procgen") end
end

--@api-stub: lurek.procgen.worldGraph
-- Generates a world graph with scattered regions and edges.
-- Use for over-world maps; each region carries id, name, position, and free-form tags.
do -- lurek.procgen.worldGraph
  local wg = lurek.procgen.worldGraph(1024, 768, 8, 5)
  local first = wg.regions[1]
  lurek.log.info("world has " .. #wg.regions .. " regions and " .. #wg.edges .. " edges", "procgen")
  lurek.log.debug("region 1 '" .. first.name .. "' at " .. first.x .. "," .. first.y, "procgen")
end

--@api-stub: lurek.procgen.noiseMap
-- Generates a noise map using the configurable NoiseGenerator.
-- Adjust scale_x/scale_y independently for stretched terrain; the result is row-major flat array.
do -- lurek.procgen.noiseMap
  local map = lurek.procgen.noiseMap(64, 64, { scale_x = 0.08, scale_y = 0.08, octaves = 3, persistence = 0.5, seed = 11 })
  lurek.log.info("noise map " .. #map .. " samples, first=" .. map[1], "procgen")
end

--@api-stub: lurek.procgen.noiseMapParallel
-- Generates a noise map using rayon parallel processing.
-- Use for large maps (> 256x256) where the parallel speedup outweighs thread setup overhead.
do -- lurek.procgen.noiseMapParallel
  local big = lurek.procgen.noiseMapParallel(256, 256, { scale_x = 0.02, scale_y = 0.02, octaves = 5, lacunarity = 2.0 })
  local sample = big[#big / 2]
  lurek.log.info("parallel noise map size=" .. #big .. " mid=" .. sample, "procgen")
end

--@api-stub: lurek.procgen.simplex2d
-- Returns a single Simplex noise value at the given 2-D coordinate.
-- Faster than Perlin and isotropic; output is in roughly [-1, 1].
do -- lurek.procgen.simplex2d
  local n = lurek.procgen.simplex2d(12.5, 7.25)
  if math.abs(n) > 0.5 then lurek.log.debug("strong simplex2d response: " .. n, "procgen") end
end

--@api-stub: lurek.procgen.simplex3d
-- Returns a single Simplex noise value at the given 3-D coordinate.
-- Use the third axis as time for animated noise (clouds, water) without seams between frames.
do -- lurek.procgen.simplex3d
  local t = 0.0
  local n = lurek.procgen.simplex3d(4.0, 4.0, t)
  lurek.log.debug("simplex3d sample at t=" .. t .. " -> " .. n, "procgen")
end
-- content/examples/procgen.lua
-- EXAMPLEed coverage of the lurek.procgen API (29 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
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

-- â”€â”€ lurek.procgen.* functions â”€â”€
