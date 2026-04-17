-- content/examples/procgen.lua
-- Lurek2D lurek.procgen API Reference
-- Run with: cargo run -- content/examples/procgen

-- =============================================================================
-- lurek.procgen — Procedural generation: noise, dungeons, names, graphs
--
-- This module provides ready-made generators for common procedural content:
-- noise maps (Perlin, simplex), dungeon layouts (BSP, room-placement),
-- cellular automata caves, Poisson disk sampling, Voronoi diagrams, L-systems
-- for vegetation, Wave Function Collapse for tilesets, and name generators.
-- =============================================================================

-- ---- Stub: lurek.procgen.perlinNoise -------------------------------------
--@api-stub: lurek.procgen.perlinNoise
-- Generate a single Perlin noise value to vary terrain height at a world
-- position.  Use scale to control feature frequency and octaves for detail.
local px, py = 42.5, 78.3
local noise_val = lurek.procgen.perlinNoise(px, py, {
    scale   = 0.02,
    octaves = 4,
    seed    = 12345,
})
print(string.format("perlin at (%.1f, %.1f) = %.4f", px, py, noise_val))
-- Values range -1..1; map to terrain: 0..1 = grass, >0.6 = mountain, <-0.3 = water

-- ---- Stub: lurek.procgen.simplex2d ---------------------------------------
--@api-stub: lurek.procgen.simplex2d
-- Simplex noise is faster than Perlin for real-time terrain variation.
-- Sample a 2D simplex value to modulate tree density in a forest biome.
local tree_noise = lurek.procgen.simplex2d(120.0, 340.0, { seed = 777 })
print(string.format("simplex2d tree density noise: %.4f", tree_noise))
local tree_density = (tree_noise + 1.0) * 0.5   -- remap -1..1 to 0..1
print(string.format("  normalized density: %.2f", tree_density))
if tree_density > 0.6 then
    print("  -> dense forest zone")
elseif tree_density > 0.3 then
    print("  -> sparse trees")
else
    print("  -> clearing")
end

-- ---- Stub: lurek.procgen.simplex3d ---------------------------------------
--@api-stub: lurek.procgen.simplex3d
-- Use 3D simplex noise to animate cloud patterns by scrolling the Z axis
-- over time, creating a smooth parallax cloud layer.
local cloud_x, cloud_y, cloud_time = 200.0, 150.0, 3.5
local cloud_val = lurek.procgen.simplex3d(cloud_x, cloud_y, cloud_time, { seed = 999 })
print(string.format("simplex3d cloud at (%.0f, %.0f, t=%.1f) = %.4f",
    cloud_x, cloud_y, cloud_time, cloud_val))
local cloud_opacity = math.max(0, (cloud_val + 1) * 0.5)
print(string.format("  cloud opacity: %.2f", cloud_opacity))

-- ---- Stub: lurek.procgen.noiseMap ----------------------------------------
--@api-stub: lurek.procgen.noiseMap
-- Generate a full 2D noise map for a 64x64 chunk of terrain.  Each cell
-- contains a -1..1 noise value that drives biome assignment.
local terrain_map = lurek.procgen.noiseMap(64, 64, {
    scale   = 0.05,
    octaves = 4,
    seed    = 42,
    noise_type = "perlin",
})
print("noise map generated: " .. #terrain_map .. " rows")
-- Count biomes in the first row
local water, land, mountain = 0, 0, 0
for _, val in ipairs(terrain_map[1]) do
    if val < -0.2 then water = water + 1
    elseif val > 0.5 then mountain = mountain + 1
    else land = land + 1
    end
end
print(string.format("  row 1 biomes: water=%d land=%d mountain=%d", water, land, mountain))

-- ---- Stub: lurek.procgen.noiseMap ----------------------------------------
--@api-stub: lurek.procgen.noiseMap
-- Generate a second noise map with different parameters for moisture overlay.
-- Combining elevation + moisture produces varied biomes (desert, swamp, tundra).
local moisture_map = lurek.procgen.noiseMap(64, 64, {
    scale   = 0.08,
    octaves = 3,
    seed    = 84,
    noise_type = "simplex",
})
print("moisture map generated for biome blending")
-- Combine: high elevation + low moisture = desert peak
-- low elevation + high moisture = swamp

-- ---- Stub: lurek.procgen.noiseMapParallel --------------------------------
--@api-stub: lurek.procgen.noiseMapParallel
-- Generate a large noise map using parallel threads for worlds that need
-- 256x256 or bigger chunks without blocking the main thread.
local large_map = lurek.procgen.noiseMapParallel(128, 128, {
    scale   = 0.03,
    octaves = 6,
    seed    = 2024,
    threads = 4,
})
print("parallel noise map: " .. #large_map .. " rows (128x128)")

-- ---- Stub: lurek.procgen.noiseMapParallel --------------------------------
--@api-stub: lurek.procgen.noiseMapParallel
-- Generate a parallel noise map with different parameters for cave density.
local cave_density = lurek.procgen.noiseMapParallel(128, 128, {
    scale   = 0.1,
    octaves = 2,
    seed    = 5555,
    threads = 2,
})
print("cave density parallel map generated: " .. #cave_density .. " rows")

-- ---- Stub: lurek.procgen.cellularAutomata --------------------------------
--@api-stub: lurek.procgen.cellularAutomata
-- Run cellular automata to carve organic cave shapes from a random grid.
-- Start with ~45% wall fill and iterate 4-5 times for smooth, natural caves.
local cave = lurek.procgen.cellularAutomata(48, 32, {
    fill_probability = 0.45,
    iterations       = 5,
    birth_limit      = 4,
    death_limit      = 3,
    seed             = 101,
})
print("cellular automata cave: " .. #cave .. " rows x " .. #cave[1] .. " cols")
-- Count open vs wall cells in first row
local open_count = 0
for _, cell in ipairs(cave[1]) do
    if cell == 0 then open_count = open_count + 1 end
end
print("  row 1: " .. open_count .. " open cells out of " .. #cave[1])

-- ---- Stub: lurek.procgen.floodFill ---------------------------------------
--@api-stub: lurek.procgen.floodFill
-- After generating a cave, flood fill from a start point to find the largest
-- connected region.  Small isolated pockets can be filled in as walls.
local region = lurek.procgen.floodFill(cave, 24, 16)
print("flood fill region size: " .. (region.size or #region) .. " cells")
-- If the region is too small, regenerate or connect it

-- ---- Stub: lurek.procgen.poissonDisk -------------------------------------
--@api-stub: lurek.procgen.poissonDisk
-- Scatter trees and rocks across a meadow with even spacing.  Poisson disk
-- sampling prevents clumping while looking natural.
local points = lurek.procgen.poissonDisk(800, 600, {
    min_distance = 40,
    max_attempts = 30,
    seed         = 303,
})
print("Poisson disk points: " .. #points)
for i = 1, math.min(5, #points) do
    local p = points[i]
    print(string.format("  tree at (%.1f, %.1f)", p.x or p[1], p.y or p[2]))
end

-- ---- Stub: lurek.procgen.voronoi -----------------------------------------
--@api-stub: lurek.procgen.voronoi
-- Partition a province map into territories using Voronoi cells.  Each cell
-- becomes a region that can be assigned to a faction.
local regions = lurek.procgen.voronoi(800, 600, {
    num_points = 12,
    seed       = 404,
})
print("Voronoi regions: " .. #regions)
for i, r in ipairs(regions) do
    print(string.format("  region %d: center=(%.0f, %.0f)  area=%d cells",
        i, r.center_x or 0, r.center_y or 0, r.area or 0))
end

-- ---- Stub: lurek.procgen.bspDungeon --------------------------------------
--@api-stub: lurek.procgen.bspDungeon
-- Generate a dungeon using Binary Space Partitioning.  BSP produces clean
-- rectangular rooms connected by corridors -- classic roguelike style.
local dungeon_bsp = lurek.procgen.bspDungeon(60, 40, {
    min_room_size = 5,
    max_room_size = 12,
    padding       = 1,
    seed          = 500,
})
print("BSP dungeon: " .. dungeon_bsp.width .. "x" .. dungeon_bsp.height)
print("  rooms: " .. #dungeon_bsp.rooms)
for i, room in ipairs(dungeon_bsp.rooms) do
    print(string.format("  room %d: (%d,%d) %dx%d",
        i, room.x, room.y, room.w, room.h))
end

-- ---- Stub: lurek.procgen.bspDungeon --------------------------------------
--@api-stub: lurek.procgen.bspDungeon
-- BSP dungeon variant: tighter rooms for a claustrophobic catacomb feel.
local catacomb = lurek.procgen.bspDungeon(40, 30, {
    min_room_size = 3,
    max_room_size = 6,
    padding       = 0,
    seed          = 501,
})
print("catacomb BSP: " .. #catacomb.rooms .. " small rooms")

-- ---- Stub: lurek.procgen.roomsDungeon ------------------------------------
--@api-stub: lurek.procgen.roomsDungeon
-- Room-placement dungeon: rooms are placed randomly and then connected by
-- corridors.  Produces more organic layouts than BSP.
local dungeon_rooms = lurek.procgen.roomsDungeon(60, 40, {
    room_count    = 8,
    min_room_size = 4,
    max_room_size = 10,
    seed          = 600,
})
print("rooms dungeon: " .. dungeon_rooms.width .. "x" .. dungeon_rooms.height)
print("  placed rooms: " .. #dungeon_rooms.rooms)
print("  corridors: " .. #(dungeon_rooms.corridors or {}))

-- ---- Stub: lurek.procgen.roomsDungeon ------------------------------------
--@api-stub: lurek.procgen.roomsDungeon
-- Room-placement variant: many small rooms for a maze-like dungeon.
local maze_dungeon = lurek.procgen.roomsDungeon(50, 50, {
    room_count    = 15,
    min_room_size = 3,
    max_room_size = 5,
    seed          = 601,
})
print("maze dungeon: " .. #maze_dungeon.rooms .. " rooms")

-- ---- Stub: lurek.procgen.heightmap ---------------------------------------
--@api-stub: lurek.procgen.heightmap
-- Generate a heightmap for an overworld.  Heights drive terrain rendering:
-- 0.0 = deep ocean, 0.3 = beach, 0.5 = plains, 0.8 = hills, 1.0 = peaks.
local hmap = lurek.procgen.heightmap(64, 64, {
    scale   = 0.04,
    octaves = 5,
    seed    = 700,
})
print("heightmap: " .. #hmap .. " rows")
-- Sample center tile
local center_h = hmap[32][32]
print(string.format("  center height: %.3f", center_h))
local biome = center_h > 0.8 and "mountain" or center_h > 0.5 and "plains" or "water"
print("  center biome: " .. biome)

-- ---- Stub: lurek.procgen.heightmap ---------------------------------------
--@api-stub: lurek.procgen.heightmap
-- Heightmap variant: island generation using radial falloff.
local island = lurek.procgen.heightmap(64, 64, {
    scale       = 0.06,
    octaves     = 4,
    seed        = 701,
    island_mode = true,
})
print("island heightmap generated: " .. #island .. " rows")

-- ---- Stub: lurek.procgen.wfcGenerate -------------------------------------
--@api-stub: lurek.procgen.wfcGenerate
-- Wave Function Collapse (WFC) generates tile layouts that respect adjacency
-- rules.  Feed it a small sample and it produces arbitrarily large maps.
local wfc_result = lurek.procgen.wfcGenerate(20, 15, {
    sample = {
        { 0, 0, 1, 1, 0 },
        { 0, 1, 1, 0, 0 },
        { 1, 1, 0, 0, 1 },
    },
    tile_size = 3,
    seed      = 800,
})
print("WFC output: " .. #wfc_result .. " rows x " .. #wfc_result[1] .. " cols")

-- ---- Stub: lurek.procgen.wfcGenerate -------------------------------------
--@api-stub: lurek.procgen.wfcGenerate
-- WFC variant: generate a road/river network from a different sample pattern.
local wfc_roads = lurek.procgen.wfcGenerate(16, 16, {
    sample = {
        { 0, 2, 0 },
        { 2, 2, 2 },
        { 0, 2, 0 },
    },
    tile_size = 2,
    seed      = 801,
})
print("WFC road network: " .. #wfc_roads .. " rows")

-- ---- Stub: lurek.procgen.lsystem -----------------------------------------
--@api-stub: lurek.procgen.lsystem
-- L-system string rewriting for fractal vegetation.  Define axiom + rules,
-- iterate, then interpret the result string as drawing commands.
local tree_str = lurek.procgen.lsystem({
    axiom = "F",
    rules = {
        F = "FF+[+F-F-F]-[-F+F+F]",
    },
    iterations = 3,
})
print("L-system string length: " .. #tree_str)
print("  first 60 chars: " .. tree_str:sub(1, 60))

-- ---- Stub: lurek.procgen.lsystem -----------------------------------------
--@api-stub: lurek.procgen.lsystem
-- L-system variant: a bush with different branching rules.
local bush_str = lurek.procgen.lsystem({
    axiom = "X",
    rules = {
        X = "F+[[X]-X]-F[-FX]+X",
        F = "FF",
    },
    iterations = 4,
})
print("bush L-system length: " .. #bush_str)

-- ---- Stub: lurek.procgen.lsystemSegments ---------------------------------
--@api-stub: lurek.procgen.lsystemSegments
-- Convert an L-system string into drawable line segments with positions and
-- angles.  Each segment has (x1,y1,x2,y2) for direct rendering.
local segments = lurek.procgen.lsystemSegments(tree_str, {
    start_x = 400,
    start_y = 500,
    angle   = 25,
    length  = 5,
})
print("tree segments: " .. #segments)
if #segments > 0 then
    local s = segments[1]
    print(string.format("  segment 1: (%.1f,%.1f) -> (%.1f,%.1f)",
        s.x1 or 0, s.y1 or 0, s.x2 or 0, s.y2 or 0))
end

-- ---- Stub: lurek.procgen.lsystemSegments ---------------------------------
--@api-stub: lurek.procgen.lsystemSegments
-- Render the bush with different visual parameters: shorter segments, wider angle.
local bush_segs = lurek.procgen.lsystemSegments(bush_str, {
    start_x = 200,
    start_y = 400,
    angle   = 30,
    length  = 3,
})
print("bush segments: " .. #bush_segs)

-- ---- Stub: lurek.procgen.generateName ------------------------------------
--@api-stub: lurek.procgen.generateName
-- Generate a single fantasy name for an NPC, town, or weapon using Markov
-- chains trained on a syllable pattern.
local npc_name = lurek.procgen.generateName({
    pattern  = "fantasy",
    min_len  = 4,
    max_len  = 8,
    seed     = 900,
})
print("generated NPC name: " .. npc_name)

-- ---- Stub: lurek.procgen.generateName ------------------------------------
--@api-stub: lurek.procgen.generateName
-- Generate a town name using a different pattern for a different flavour.
local town_name = lurek.procgen.generateName({
    pattern = "elvish",
    min_len = 5,
    max_len = 10,
    seed    = 901,
})
print("generated town name: " .. town_name)

-- ---- Stub: lurek.procgen.generateNames -----------------------------------
--@api-stub: lurek.procgen.generateNames
-- Generate a batch of names for populating a roster of enemies or a list
-- of shops in a procedural town.
local enemy_names = lurek.procgen.generateNames(8, {
    pattern = "orcish",
    min_len = 3,
    max_len = 7,
    seed    = 1000,
})
print("generated " .. #enemy_names .. " enemy names:")
for i, name in ipairs(enemy_names) do
    print(string.format("  [%d] %s", i, name))
end

-- ---- Stub: lurek.procgen.generateNames -----------------------------------
--@api-stub: lurek.procgen.generateNames
-- Generate shop names for a procedural marketplace.
local shop_names = lurek.procgen.generateNames(5, {
    pattern = "fantasy",
    min_len = 6,
    max_len = 12,
    seed    = 1001,
})
print("shop names: " .. table.concat(shop_names, ", "))

-- ---- Stub: lurek.procgen.worldGraph --------------------------------------
--@api-stub: lurek.procgen.worldGraph
-- Generate a connected world graph where nodes are regions and edges are
-- travel routes.  Used for overworld maps in strategy or RPG games.
local world = lurek.procgen.worldGraph({
    node_count = 10,
    min_edges  = 1,
    max_edges  = 3,
    seed       = 1100,
})
print("world graph: " .. #world.nodes .. " nodes, " .. #world.edges .. " edges")
for i, node in ipairs(world.nodes) do
    print(string.format("  node %d: (%.0f, %.0f)  name=%s",
        i, node.x or 0, node.y or 0, node.name or "?"))
end

-- ---- Stub: lurek.procgen.worldGraph --------------------------------------
--@api-stub: lurek.procgen.worldGraph
-- World graph variant: denser connectivity for a hub-and-spoke trade network.
local trade_net = lurek.procgen.worldGraph({
    node_count = 6,
    min_edges  = 2,
    max_edges  = 4,
    seed       = 1101,
})
print("trade network: " .. #trade_net.nodes .. " hubs, " .. #trade_net.edges .. " routes")
