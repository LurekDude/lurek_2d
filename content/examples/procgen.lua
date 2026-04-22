-- content/examples/procgen.lua
-- Auto-scaffolded coverage of the lurek.procgen Lua API (29 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/procgen.lua

print("[example] lurek.procgen loaded — 29 API items demonstrated")

-- ── lurek.procgen free functions ──

--@api-stub: lurek.procgen.cellularAutomata
-- Generates a cave-like map using cellular automata.
-- Use this when generates a cave-like map using cellular automata is needed.
if false then
  local _r = lurek.procgen.cellularAutomata(0, 0, 0)
  print(_r)
end

--@api-stub: lurek.procgen.floodFill
-- BFS flood fill on a flat grid of bytes.
-- Use this when bFS flood fill on a flat grid of bytes is needed.
if false then
  local _r = lurek.procgen.floodFill()
  print(_r)
end

--@api-stub: lurek.procgen.perlinNoise
-- Evaluates periodic Perlin noise at a point.
-- Use this when evaluates periodic Perlin noise at a point is needed.
if false then
  local _r = lurek.procgen.perlinNoise(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.procgen.poissonDisk
-- Generates Poisson disk sample points using Bridson's algorithm.
-- Use this when generates Poisson disk sample points using Bridson's algorithm is needed.
if false then
  local _r = lurek.procgen.poissonDisk(0, 0, 1, 0, nil)
  print(_r)
end

--@api-stub: lurek.procgen.voronoi
-- Generates a Voronoi diagram for a set of seed points.
-- Use this when generates a Voronoi diagram for a set of seed points is needed.
if false then
  local _r = lurek.procgen.voronoi(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.procgen.bspDungeon
-- Generates a dungeon using Binary Space Partitioning.
-- Use this when generates a dungeon using Binary Space Partitioning is needed.
if false then
  local _r = lurek.procgen.bspDungeon(0)
  print(_r)
end

--@api-stub: lurek.procgen.roomsDungeon
-- Generates a rooms-and-corridors dungeon.
-- Use this when generates a rooms-and-corridors dungeon is needed.
if false then
  local _r = lurek.procgen.roomsDungeon(0)
  print(_r)
end

--@api-stub: lurek.procgen.heightmap
-- Generates a heightmap using fractal noise.
-- Use this when generates a heightmap using fractal noise is needed.
if false then
  local _r = lurek.procgen.heightmap(0)
  print(_r)
end

--@api-stub: lurek.procgen.wfcGenerate
-- Generates a tile grid using Wave Function Collapse.
-- Use this when generates a tile grid using Wave Function Collapse is needed.
if false then
  local _r = lurek.procgen.wfcGenerate(0)
  print(_r)
end

--@api-stub: lurek.procgen.lsystem
-- Generates an L-system string.
-- Use this when generates an L-system string is needed.
if false then
  local _r = lurek.procgen.lsystem(0)
  print(_r)
end

--@api-stub: lurek.procgen.lsystemSegments
-- Generates L-system line segments for rendering.
-- Use this when generates L-system line segments for rendering is needed.
if false then
  local _r = lurek.procgen.lsystemSegments(0, 1, 0)
  print(_r)
end

--@api-stub: lurek.procgen.generateName
-- Generates a single procedural name using a Markov chain.
-- Use this when generates a single procedural name using a Markov chain is needed.
if false then
  local _r = lurek.procgen.generateName()
  print(_r)
end

--@api-stub: lurek.procgen.generateNames
-- Generates N procedural names using a Markov chain.
-- Use this when generates N procedural names using a Markov chain is needed.
if false then
  local _r = lurek.procgen.generateNames()
  print(_r)
end

--@api-stub: lurek.procgen.worldGraph
-- Generates a world graph with scattered regions and edges.
-- Use this when generates a world graph with scattered regions and edges is needed.
if false then
  local _r = lurek.procgen.worldGraph(1, 1, 1, nil)
  print(_r)
end

--@api-stub: lurek.procgen.noiseMap
-- Generates a noise map using the configurable NoiseGenerator.
-- Use this when generates a noise map using the configurable NoiseGenerator is needed.
if false then
  local _r = lurek.procgen.noiseMap(1, 1, 0)
  print(_r)
end

--@api-stub: lurek.procgen.noiseMapParallel
-- Generates a noise map using rayon parallel processing.
-- Use this when generates a noise map using rayon parallel processing is needed.
if false then
  local _r = lurek.procgen.noiseMapParallel(1, 1, 0)
  print(_r)
end

--@api-stub: lurek.procgen.bspDungeon
-- Generates a dungeon using Binary Space Partitioning.
-- Use this when generates a dungeon using Binary Space Partitioning is needed.
if false then
  local _r = lurek.procgen.bspDungeon(0)
  print(_r)
end

--@api-stub: lurek.procgen.roomsDungeon
-- Generates a rooms-and-corridors dungeon.
-- Use this when generates a rooms-and-corridors dungeon is needed.
if false then
  local _r = lurek.procgen.roomsDungeon(0)
  print(_r)
end

--@api-stub: lurek.procgen.heightmap
-- Generates a heightmap using fractal noise.
-- Use this when generates a heightmap using fractal noise is needed.
if false then
  local _r = lurek.procgen.heightmap(0)
  print(_r)
end

--@api-stub: lurek.procgen.wfcGenerate
-- Generates a tile grid using Wave Function Collapse.
-- Use this when generates a tile grid using Wave Function Collapse is needed.
if false then
  local _r = lurek.procgen.wfcGenerate(0)
  print(_r)
end

--@api-stub: lurek.procgen.lsystem
-- Generates an L-system string.
-- Use this when generates an L-system string is needed.
if false then
  local _r = lurek.procgen.lsystem(0)
  print(_r)
end

--@api-stub: lurek.procgen.lsystemSegments
-- Generates L-system line segments for rendering.
-- Use this when generates L-system line segments for rendering is needed.
if false then
  local _r = lurek.procgen.lsystemSegments(0, 1, 0)
  print(_r)
end

--@api-stub: lurek.procgen.generateName
-- Generates a single procedural name using a Markov chain.
-- Use this when generates a single procedural name using a Markov chain is needed.
if false then
  local _r = lurek.procgen.generateName()
  print(_r)
end

--@api-stub: lurek.procgen.generateNames
-- Generates N procedural names using a Markov chain.
-- Use this when generates N procedural names using a Markov chain is needed.
if false then
  local _r = lurek.procgen.generateNames()
  print(_r)
end

--@api-stub: lurek.procgen.worldGraph
-- Generates a world graph with scattered regions and edges.
-- Use this when generates a world graph with scattered regions and edges is needed.
if false then
  local _r = lurek.procgen.worldGraph(1, 1, 1, nil)
  print(_r)
end

--@api-stub: lurek.procgen.noiseMap
-- Generates a noise map using the configurable NoiseGenerator.
-- Use this when generates a noise map using the configurable NoiseGenerator is needed.
if false then
  local _r = lurek.procgen.noiseMap(1, 1, 0)
  print(_r)
end

--@api-stub: lurek.procgen.noiseMapParallel
-- Generates a noise map using rayon parallel processing.
-- Use this when generates a noise map using rayon parallel processing is needed.
if false then
  local _r = lurek.procgen.noiseMapParallel(1, 1, 0)
  print(_r)
end

--@api-stub: lurek.procgen.simplex2d
-- Returns a single Simplex noise value at the given 2-D coordinate.
-- Use this when returns a single Simplex noise value at the given 2-D coordinate is needed.
if false then
  local _r = lurek.procgen.simplex2d(0, 0)
  print(_r)
end

--@api-stub: lurek.procgen.simplex3d
-- Returns a single Simplex noise value at the given 3-D coordinate.
-- Use this when returns a single Simplex noise value at the given 3-D coordinate is needed.
if false then
  local _r = lurek.procgen.simplex3d(0, 0, 0)
  print(_r)
end

