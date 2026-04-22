-- content/examples/procgen.lua
-- Practical usage examples for the lurek.procgen API (29 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.procgen.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/procgen.lua

print("[example] lurek.procgen — 29 API entries")

-- ── lurek.procgen.* free functions ──

--@api-stub: lurek.procgen.cellularAutomata
-- Generates a cave-like map using cellular automata.
-- Call when you need to invoke cellular automata.
local ok, result = pcall(function() return lurek.procgen.cellularAutomata(100, 100, {}) end)
if ok then print("lurek.procgen.cellularAutomata ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.floodFill
-- BFS flood fill on a flat grid of bytes.
-- Call when you need to invoke flood fill.
local ok, result = pcall(function() return lurek.procgen.floodFill() end)
if ok then print("lurek.procgen.floodFill ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.perlinNoise
-- Evaluates periodic Perlin noise at a point.
-- Call when you need to invoke perlin noise.
local ok, result = pcall(function() return lurek.procgen.perlinNoise(0, 0, nil, nil) end)
if ok then print("lurek.procgen.perlinNoise ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.poissonDisk
-- Generates Poisson disk sample points using Bridson's algorithm.
-- Call when you need to invoke poisson disk.
local ok, result = pcall(function() return lurek.procgen.poissonDisk(100, 100, nil, nil, nil) end)
if ok then print("lurek.procgen.poissonDisk ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.voronoi
-- Generates a Voronoi diagram for a set of seed points.
-- Call when you need to invoke voronoi.
local ok, result = pcall(function() return lurek.procgen.voronoi(100, 100, nil, {}) end)
if ok then print("lurek.procgen.voronoi ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.bspDungeon
-- Generates a dungeon using Binary Space Partitioning.
-- Call when you need to invoke bsp dungeon.
local ok, result = pcall(function() return lurek.procgen.bspDungeon({}) end)
if ok then print("lurek.procgen.bspDungeon ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.roomsDungeon
-- Generates a rooms-and-corridors dungeon.
-- Call when you need to invoke rooms dungeon.
local ok, result = pcall(function() return lurek.procgen.roomsDungeon({}) end)
if ok then print("lurek.procgen.roomsDungeon ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.heightmap
-- Generates a heightmap using fractal noise.
-- Call when you need to invoke heightmap.
local ok, result = pcall(function() return lurek.procgen.heightmap({}) end)
if ok then print("lurek.procgen.heightmap ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.wfcGenerate
-- Generates a tile grid using Wave Function Collapse.
-- Call when you need to invoke wfc generate.
local ok, result = pcall(function() return lurek.procgen.wfcGenerate({}) end)
if ok then print("lurek.procgen.wfcGenerate ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.lsystem
-- Generates an L-system string.
-- Call when you need to invoke lsystem.
local ok, result = pcall(function() return lurek.procgen.lsystem({}) end)
if ok then print("lurek.procgen.lsystem ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.lsystemSegments
-- Generates L-system line segments for rendering.
-- Call when you need to invoke lsystem segments.
local ok, result = pcall(function() return lurek.procgen.lsystemSegments({}, nil, nil) end)
if ok then print("lurek.procgen.lsystemSegments ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.generateName
-- Generates a single procedural name using a Markov chain.
-- Call when you need to invoke generate name.
local ok, result = pcall(function() return lurek.procgen.generateName() end)
if ok then print("lurek.procgen.generateName ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.generateNames
-- Generates N procedural names using a Markov chain.
-- Call when you need to invoke generate names.
local ok, result = pcall(function() return lurek.procgen.generateNames() end)
if ok then print("lurek.procgen.generateNames ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.worldGraph
-- Generates a world graph with scattered regions and edges.
-- Call when you need to invoke world graph.
local ok, result = pcall(function() return lurek.procgen.worldGraph(100, 100, 10, nil) end)
if ok then print("lurek.procgen.worldGraph ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.noiseMap
-- Generates a noise map using the configurable NoiseGenerator.
-- Call when you need to invoke noise map.
local ok, result = pcall(function() return lurek.procgen.noiseMap(100, 100, {}) end)
if ok then print("lurek.procgen.noiseMap ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.noiseMapParallel
-- Generates a noise map using rayon parallel processing.
-- Call when you need to invoke noise map parallel.
local ok, result = pcall(function() return lurek.procgen.noiseMapParallel(100, 100, {}) end)
if ok then print("lurek.procgen.noiseMapParallel ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.bspDungeon
-- Generates a dungeon using Binary Space Partitioning.
-- Call when you need to invoke bsp dungeon.
local ok, result = pcall(function() return lurek.procgen.bspDungeon({}) end)
if ok then print("lurek.procgen.bspDungeon ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.roomsDungeon
-- Generates a rooms-and-corridors dungeon.
-- Call when you need to invoke rooms dungeon.
local ok, result = pcall(function() return lurek.procgen.roomsDungeon({}) end)
if ok then print("lurek.procgen.roomsDungeon ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.heightmap
-- Generates a heightmap using fractal noise.
-- Call when you need to invoke heightmap.
local ok, result = pcall(function() return lurek.procgen.heightmap({}) end)
if ok then print("lurek.procgen.heightmap ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.wfcGenerate
-- Generates a tile grid using Wave Function Collapse.
-- Call when you need to invoke wfc generate.
local ok, result = pcall(function() return lurek.procgen.wfcGenerate({}) end)
if ok then print("lurek.procgen.wfcGenerate ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.lsystem
-- Generates an L-system string.
-- Call when you need to invoke lsystem.
local ok, result = pcall(function() return lurek.procgen.lsystem({}) end)
if ok then print("lurek.procgen.lsystem ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.lsystemSegments
-- Generates L-system line segments for rendering.
-- Call when you need to invoke lsystem segments.
local ok, result = pcall(function() return lurek.procgen.lsystemSegments({}, nil, nil) end)
if ok then print("lurek.procgen.lsystemSegments ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.generateName
-- Generates a single procedural name using a Markov chain.
-- Call when you need to invoke generate name.
local ok, result = pcall(function() return lurek.procgen.generateName() end)
if ok then print("lurek.procgen.generateName ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.generateNames
-- Generates N procedural names using a Markov chain.
-- Call when you need to invoke generate names.
local ok, result = pcall(function() return lurek.procgen.generateNames() end)
if ok then print("lurek.procgen.generateNames ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.worldGraph
-- Generates a world graph with scattered regions and edges.
-- Call when you need to invoke world graph.
local ok, result = pcall(function() return lurek.procgen.worldGraph(100, 100, 10, nil) end)
if ok then print("lurek.procgen.worldGraph ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.noiseMap
-- Generates a noise map using the configurable NoiseGenerator.
-- Call when you need to invoke noise map.
local ok, result = pcall(function() return lurek.procgen.noiseMap(100, 100, {}) end)
if ok then print("lurek.procgen.noiseMap ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.noiseMapParallel
-- Generates a noise map using rayon parallel processing.
-- Call when you need to invoke noise map parallel.
local ok, result = pcall(function() return lurek.procgen.noiseMapParallel(100, 100, {}) end)
if ok then print("lurek.procgen.noiseMapParallel ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.simplex2d
-- Returns a single Simplex noise value at the given 2-D coordinate.
-- Call when you need to invoke simplex2d.
local ok, result = pcall(function() return lurek.procgen.simplex2d(0, 0) end)
if ok then print("lurek.procgen.simplex2d ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.procgen.simplex3d
-- Returns a single Simplex noise value at the given 3-D coordinate.
-- Call when you need to invoke simplex3d.
local ok, result = pcall(function() return lurek.procgen.simplex3d(0, 0, 0) end)
if ok then print("lurek.procgen.simplex3d ->", result)
else print("unavailable:", result) end

