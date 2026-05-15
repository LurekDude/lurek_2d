# procgen

## General Info

- Module group: `Foundations`
- Source path: `src/procgen/`
- Lua API path(s): `src/lua_api/procgen_api.rs`
- Primary Lua namespace: `lurek.procgen`
- Rust test path(s): src/procgen/noise_tests.rs (sibling), plus inline #[cfg(test)] in all other .rs files
- Lua test path(s): none found in the workspace

## Summary

The `procgen` module is Lurek2D's procedural content generation library — a Foundations tier module that depends only on `math`, enabling all generators to run headlessly in tests and pre-generation passes without a window or GPU context.

**Noise generators.** Standalone functions `perlin2d`, `perlin3d`, `perlin4d`, `simplex2d`, and `simplex_noise_3d` provide single-sample noise values. `NoiseGenerator` is a configurable multi-octave wrapper with `NoiseKind` (Perlin, Simplex), `FractalType` (Fbm, Ridged, Turbulence), octave count, lacunarity, persistence, and frequency settings. Worley (cellular) noise supports Euclidean, Manhattan, and Chebyshev distance metrics. Periodic Perlin noise (`perlin_noise_periodic`) generates tileable maps that wrap without seams. `generate_noise_map_parallel` fills a 2D grid using Rayon parallel iterators for fast CPU-parallel generation at world-map scale.

**Dungeon and cave generation.** `bsp_dungeon(opts)` partitions a rectangle recursively using Binary Space Partitioning to produce non-overlapping rooms with L-shaped corridors. `rooms_dungeon(opts)` scatters rectangular rooms randomly with configurable room size and margin constraints. `cellular_automata(opts)` applies configurable birth and survival rules (Game of Life style) to smooth a random fill into organic cave or island networks. `flood_fill` performs BFS over a flat byte grid from a seed position for region tagging and connectivity analysis.

**Heightmap terrain.** `Heightmap` generates 2D float elevation grids using fractal noise with `HeightmapOpts`. Post-processing: simplified hydraulic erosion (sediment flows from high-to-low neighbours), `normalize()` to rescale values to [0, 1]. `to_rgba_bytes()` exports the heightmap as a grayscale RGBA image buffer for CPU-side texture generation.

**Voronoi and world graphs.** `voronoi_diagram(points, warp)` generates Voronoi region cells with optional domain-warp distortion for organic shapes. Nearest-distance and second-distance field outputs enable cell-border detection and Delaunay-inspired edges. `WorldGraph` stores `WorldRegion` nodes and `WorldEdge` connections with MST generation and pathfinding support for regional strategy maps with province-level topology.

**Wave Function Collapse.** `WfcGrid` implements WFC with adjacency `WfcRules` and per-tile probability weights. `solve(max_iterations)` runs constraint propagation and backtracking. Output is a 2D tile-ID grid. `WfcRules` can be authored manually or derived from a sample tilemap. Used for dungeon rooms, town layouts, and natural terrain patches.

**L-Systems.** `LSystem` performs parametric string rewriting via production rules: `addRule(symbol, replacement)`, `iterate(n)`, `to_segments(angle_deg)` converts the generated string to turtle-graphics line segments. Starting axiom and production alphabet are configurable. Used for plant generation, fractal coastlines, and procedural architecture.

**Name generation.** `NameGen` trains a second-order Markov chain model on a word list and generates names with configurable min/max length. `train(words)`, `generate()`. Suitable for NPC names, place names, and item descriptions.

**Poisson-disk sampling.** `poisson_disk(area, min_dist, tries)` uses Bridson's algorithm to sample 2D points with a guaranteed minimum spacing for natural object scatter. Returns a `Vec<Vec2>`. Used for tree placement, enemy spawning, and treasure distribution.

**Rendering helpers.** `render.rs` provides `NoiseGrid` sampling and visualisation helpers that produce `RenderCommand` sequences or CPU image buffers for noise previews and debug overlays without requiring a GPU context.

**Lua surface.** `lurek.procgen.perlin(x, y)`, `simplex(x, y)`, `worley(x, y, metric)`. `lurek.procgen.newNoise(opts)` returns a NoiseGenerator userdata with `sample(x, y)`, `map(w, h)`. `bspDungeon(opts)` returns rooms+corridors table. `roomsDungeon(opts)`. `cellularCave(opts)`. `newHeightmap(opts)`. `voronoi(points)`. `newWfc(w, h, rules)`. `newLSystem(axiom)`. `newNameGen()`. `poissonDisk(rect, min_dist)`.

**Scope boundary.** Foundations tier. Depends only on `math`. Lua bridge in `src/lua_api/procgen_api.rs`.

## Files

- `biome.rs`: - Biome classification system mapping height, moisture, and temperature to terrain types.
- `bsp.rs`: Binary Space Partitioning dungeon generator.
- `cellular.rs`: Cellular automata map generation with configurable fill, birth, survive, and iteration settings.
- `color.rs`: - Convert scalar procgen output into pixel-ready RGBA byte buffers.
- `flood_fill.rs`: Threshold-based BFS flood fill over flat byte grids.
- `heightmap.rs`: Heightmap generation using fractal noise, erosion, and normalization.
- `lcg.rs`: Internal deterministic random generator shared by the generation algorithms.
- `lsystem.rs`: L-system string rewriter for procedural plant and structure generation.
- `mod.rs`: Module root and re-export surface for the public generation functions and option structs.
- `namegen.rs`: Markov chain name generator.
- `noise.rs`: Procedural noise functions and generators: Perlin, Simplex, Worley, fractal combinators.
- `poisson.rs`: Bridson-style Poisson-disk sampling for evenly spaced point placement.
- `render.rs`: `NoiseGrid` sampling and visualization helpers for command-queue or CPU-image inspection.
- `rooms.rs`: Rooms-and-corridors dungeon generator with random scatter placement.
- `voronoi.rs`: Voronoi region, nearest-distance, and second-distance field generation with optional warp.
- `wfc.rs`: Wave Function Collapse tile grid generator.
- `world_graph.rs`: World-level topology graph: regions connected by traversable edges.

## Types

- `BiomeType` (`enum`, `biome.rs`): Biome variant covering terrain from ocean to ice cap.
- `BiomeRules` (`struct`, `biome.rs`): Scalar thresholds that drive biome classification; all values are normalised 0..=1.
- `BiomeClassifier` (`struct`, `biome.rs`): Stateless classifier that maps (height, moisture, temperature) to a `BiomeType`.
- `BspRoom` (`struct`, `bsp.rs`): A room placed within the dungeon.
- `BspDungeon` (`struct`, `bsp.rs`): A generated BSP dungeon.
- `BspPrefabStamp` (`struct`, `bsp.rs`): Template shape used to stamp a named prefab into a room during BSP generation.
- `PlacedBspPrefab` (`struct`, `bsp.rs`): A `BspPrefabStamp` placed at a concrete tile position within a room.
- `BspOpts` (`struct`, `bsp.rs`): Options controlling BSP dungeon generation.
- `CellularOpts` (`struct`, `cellular.rs`): Configuration bundle for cellular automata generation.
- `HeightmapOpts` (`struct`, `heightmap.rs`): Options for heightmap generation.
- `Heightmap` (`struct`, `heightmap.rs`): A 2D heightmap with float elevation values.
- `Lcg` (`struct`, `lcg.rs`): Internal deterministic RNG used to keep the public algorithms reproducible.
- `LSystem` (`struct`, `lsystem.rs`): An L-system with an axiom, rewriting rules, and an iteration count.
- `NameGen` (`struct`, `namegen.rs`): A Markov chain name generator.
- `DistType` (`enum`, `noise.rs`): Distance metric for Worley (cellular) noise.
- `NoiseKind` (`enum`, `noise.rs`): Noise algorithm kind used by fractal combinators.
- `FractalType` (`enum`, `noise.rs`): Fractal type for multi-octave noise.
- `MapGenOptions` (`struct`, `noise.rs`): Options for 2D noise map generation.
- `NoiseGenerator` (`struct`, `noise.rs`): Seeded procedural noise generator.
- `NoiseGrid` (`struct`, `render.rs`): Sampled noise buffer that can be exported as render commands or a CPU image.
- `Room` (`struct`, `rooms.rs`): A placed room in the dungeon.
- `RoomsOpts` (`struct`, `rooms.rs`): Options for rooms-and-corridors generation.
- `RoomsDungeon` (`struct`, `rooms.rs`): The result of rooms-and-corridors generation.
- `RoomPrefabStamp` (`struct`, `rooms.rs`): Template shape used to overwrite a room's interior with a named stamp pattern.
- `PlacedRoomPrefab` (`struct`, `rooms.rs`): A `RoomPrefabStamp` placed at a concrete tile position within a room.
- `VoronoiOpts` (`struct`, `voronoi.rs`): Configuration bundle for Voronoi generation and optional domain warping.
- `WfcTile` (`struct`, `wfc.rs`): A weighted tile for WFC generation.
- `WfcRules` (`struct`, `wfc.rs`): Adjacency rules: maps each tile ID to the set of tile IDs that may appear beside it.
- `WfcOpts` (`struct`, `wfc.rs`): Options for WFC generation.
- `WfcGrid` (`struct`, `wfc.rs`): The generated grid.
- `WorldRegion` (`struct`, `world_graph.rs`): A region (node) in the world graph.
- `WorldEdge` (`struct`, `world_graph.rs`): An edge connecting two regions.
- `WorldGraph` (`struct`, `world_graph.rs`): A world-level topology graph.

## Functions

- `BiomeType::as_str` (`biome.rs`): Return the canonical snake_case string token for this biome.
- `BiomeType::color_rgba` (`biome.rs`): Return the representative RGBA color `[r, g, b, 255]` for this biome variant.
- `BiomeClassifier::new` (`biome.rs`): Create a classifier using the provided rules.
- `BiomeClassifier::default_rules` (`biome.rs`): Create a classifier with `BiomeRules::default()`.
- `BiomeClassifier::classify` (`biome.rs`): Classify a single cell and return its `BiomeType`; all inputs must be normalised 0..=1.
- `BiomeClassifier::classify_map` (`biome.rs`): Classify every cell in a flat `width × height_map` grid; missing slice entries default to neutral values.
- `BiomeClassifier::rules` (`biome.rs`): Return a shared reference to the active `BiomeRules`.
- `biome_map_to_rgba` (`biome.rs`): Convert a slice of `BiomeType` values to a flat RGBA byte buffer at 4 bytes per cell.
- `bsp_dungeon` (`bsp.rs`): Generate a BSP dungeon from the given options.
- `bsp_dungeon_with_prefabs` (`bsp.rs`): Generate a BSP dungeon and centre-place `prefabs` (round-robin) in rooms that fit; returns `(dungeon, placements)`.
- `cellular_automata` (`cellular.rs`): Generates a cave/dungeon map using cellular automata.
- `scalar_map_to_rgba_bytes` (`color.rs`): Convert a normalised float slice to a flat grayscale RGBA buffer; clamps each value to 0.0–1.0.
- `flood_fill` (`flood_fill.rs`): BFS flood fill on a flat grid, returning a binary mask of all cells reachable from a seed position whose values satisfy `threshold`.
- `Heightmap::generate` (`heightmap.rs`): Generate a heightmap from `opts` using FBM Perlin noise, normalised and optionally eroded.
- `Heightmap::from_noise_map` (`heightmap.rs`): Build a heightmap from a pre-computed `f64` noise slice; normalises the result.
- `Heightmap::from_cellular` (`heightmap.rs`): Build a heightmap from a cellular automata `u8` grid: cells != `floor_value` map to 1.0, others to 0.0.
- `Heightmap::get` (`heightmap.rs`): Return the cell value at `(x, y)`, clamping out-of-bounds coordinates to the grid edge.
- `Heightmap::normalize` (`heightmap.rs`): Remap all cells to 0.0–1.0 by dividing by the current min/max range; no-op if range < 1e-7.
- `Heightmap::erode` (`heightmap.rs`): Apply `passes` rounds of simple hydraulic erosion: each cell deposits 10 % of its height difference into its lowest 4-connected neighbour.
- `Heightmap::to_rgba_bytes` (`heightmap.rs`): Convert the cell grid to a flat grayscale RGBA byte buffer at 4 bytes per cell.
- `Lcg::new` (`lcg.rs`): Create an LCG seeded with `seed` (internal state = seed + 1 to avoid zero-state).
- `Lcg::next` (`lcg.rs`): Advance the LCG by one step and return the next raw `u64` output.
- `Lcg::next_f32` (`lcg.rs`): Advance and return a uniform float in 0.0–1.0 using the upper 31 bits.
- `LSystem::new` (`lsystem.rs`): Create an L-system from a string axiom and `(char, &str)` rule pairs.
- `LSystem::new_from_pairs` (`lsystem.rs`): Create an L-system from a string axiom and `(char, String)` rule slice.
- `LSystem::generate` (`lsystem.rs`): Apply all production rules `iterations` times and return the resulting string.
- `LSystem::to_segments` (`lsystem.rs`): Interpret the generated string as turtle commands and return `(x1,y1,x2,y2)` line segments.
- `NameGen::new` (`namegen.rs`): Build a chain from `training` words at the given `order` and deterministic `seed`.
- `NameGen::generate` (`namegen.rs`): Sample up to 64 candidate names and return the first one with `min_len..=max_len` characters; returns an empty string when all attempts fail.
- `NameGen::generate_n` (`namegen.rs`): Generate `n` names each satisfying `min_len`/`max_len`; names that fail all attempts are empty strings.
- `perlin2d` (`noise.rs`): Generates 2D Perlin noise at the given coordinates.
- `simplex2d` (`noise.rs`): Generates 2D Simplex noise at the given coordinates.
- `simplex_noise_2d` (`noise.rs`): Returns 2D simplex noise using a fixed seed of 0.
- `simplex_noise_3d` (`noise.rs`): Returns 3D simplex noise using a fixed seed of 0.
- `fbm` (`noise.rs`): Generates fractal Brownian motion noise by layering multiple octaves of Perlin noise.
- `perlin3d` (`noise.rs`): Generates 3D Perlin noise at the given coordinates.
- `perlin4d` (`noise.rs`): Generates 4D Perlin noise at the given coordinates.
- `generate_noise_map_parallel` (`noise.rs`): Generate a noise map in parallel using rayon.
- `NoiseGenerator::new` (`noise.rs`): Create a generator seeded with `seed` and build the permutation table.
- `NoiseGenerator::set_seed` (`noise.rs`): Replace the current seed and rebuild the permutation table.
- `NoiseGenerator::seed` (`noise.rs`): Return the current seed value.
- `NoiseGenerator::perlin_1d` (`noise.rs`): Evaluate 1D Perlin noise at `x`; returns a value roughly in -1.0..1.0.
- `NoiseGenerator::perlin_2d` (`noise.rs`): Evaluate 2D Perlin noise at `(x, y)`; returns a value roughly in -1.0..1.0.
- `NoiseGenerator::perlin_3d` (`noise.rs`): Evaluate 3D Perlin noise at `(x, y, z)`; returns a value roughly in -1.0..1.0.
- `NoiseGenerator::simplex_2d` (`noise.rs`): Evaluate 2D simplex noise at `(x, y)`; scaled to approximately -1.0..1.0.
- `NoiseGenerator::simplex_3d` (`noise.rs`): Evaluate 3D simplex noise at `(x, y, z)`; scaled to approximately -1.0..1.0.
- `NoiseGenerator::simplex_4d` (`noise.rs`): Evaluate 4D simplex noise at `(x, y, z, w)`; scaled to approximately -1.0..1.0.
- `NoiseGenerator::worley_2d` (`noise.rs`): Evaluate 2D Worley noise; returns F1 distance when `f2=false`, F2−F1 when `f2=true`.
- `NoiseGenerator::worley_3d` (`noise.rs`): Evaluate 3D Worley noise; returns F1 distance when `f2=false`, F2−F1 when `f2=true`.
- `NoiseGenerator::fbm` (`noise.rs`): Evaluate FBM fractal at `(x, y)` using `kind` noise; sums `octaves` normalised octaves.
- `NoiseGenerator::ridged` (`noise.rs`): Evaluate ridged multifractal at `(x, y)` using `kind` noise; inverts octaves to produce ridges.
- `NoiseGenerator::turbulence` (`noise.rs`): Evaluate turbulence fractal at `(x, y)` using `kind` noise; sums absolute octave values.
- `NoiseGenerator::warp_domain` (`noise.rs`): Apply domain-warp to `(x, y)` using `perlin_2d` offsets scaled by `strength`; returns warped coordinates.
- `NoiseGenerator::generate_map` (`noise.rs`): Generate a flat `width × height` noise map sequentially using `opts`; returns values in approximately -1.0..1.0.
- `NoiseGenerator::generate_map_parallel` (`noise.rs`): Generate a flat `width × height` noise map using rayon parallel iteration; faster than `generate_map` for large grids.
- `perlin_noise_periodic` (`noise.rs`): Periodic Perlin noise that tiles over period (px, py).
- `poisson_disk` (`poisson.rs`): Generates Poisson disk sample points using Bridson's algorithm.
- `NoiseGrid::from_perlin` (`render.rs`): Build a tileable Perlin noise grid at the given `scale`; scale is clamped to >= 1e-6.
- `NoiseGrid::to_rgba_bytes` (`render.rs`): Convert the cell grid to a flat grayscale RGBA byte buffer at 4 bytes per cell.
- `NoiseGrid::generate_render_commands` (`render.rs`): Generate `SetColor` + `Rectangle` render commands for each cell at `cell_size` pixels; returns an empty vec for empty grids.
- `NoiseGrid::draw_to_image` (`render.rs`): Render the grid into a new `ImageData` as grayscale RGBA pixels.
- `rooms_dungeon` (`rooms.rs`): Generate a rooms-and-corridors dungeon.
- `rooms_dungeon_with_prefabs` (`rooms.rs`): Generate a rooms dungeon, centre-stamp `prefabs` (round-robin) in each room, and return `(dungeon, placements)`.
- `voronoi_diagram` (`voronoi.rs`): Generates a Voronoi diagram over a `width × height` grid for the given seed points.
- `wfc_generate` (`wfc.rs`): Generate a WFC tile grid.
- `WorldGraph::new` (`world_graph.rs`): Create an empty world graph.
- `WorldGraph::add_region` (`world_graph.rs`): Add a named region at `(x, y)` and return its assigned ID.
- `WorldGraph::add_edge` (`world_graph.rs`): Add an edge from `from` to `to` with the given `cost`; bidirectional edges traverse both ways.
- `WorldGraph::find_path` (`world_graph.rs`): Find the shortest path from `from` to `to` using A* with Euclidean heuristic; returns `None` when no path exists.
- `WorldGraph::reachable_from` (`world_graph.rs`): Return all region IDs reachable from `start` within cumulative edge cost `max_cost` using bounded Dijkstra.
- `WorldGraph::mst` (`world_graph.rs`): Compute a minimum spanning tree using Kruskal's algorithm; returns `(from, to, cost)` triples.
- `WorldGraph::to_regions_list` (`world_graph.rs`): Return references to all regions in insertion order.
- `generate_world_graph` (`world_graph.rs`): Scatter `region_count` regions randomly in a `width × height` world and connect each to its k-nearest neighbours (k = 3).

## Lua API Reference

- Binding path(s): `src/lua_api/procgen_api.rs`
- Namespace: `lurek.procgen`

### Module Functions
- `lurek.procgen.cellularAutomata`: Generate a cave or organic map using cellular automata rules.
- `lurek.procgen.floodFill`: Flood-fill a grid from a starting cell, marking all connected cells that pass a threshold test.
- `lurek.procgen.perlinNoise`: Sample periodic 2D Perlin noise at a given coordinate.
- `lurek.procgen.poissonDisk`: Generate evenly-spaced random points using Poisson disk sampling. Useful for placing trees, NPCs, or loot without clustering.
- `lurek.procgen.voronoi`: Compute a Voronoi diagram from a set of seed points. Returns region ownership, distance-to-nearest, and distance-to-second-nearest for each cell.
- `lurek.procgen.bspDungeon`: Generate a dungeon layout using Binary Space Partitioning. Produces non-overlapping rooms connected by corridors.
- `lurek.procgen.bspDungeonWithPrefabs`: Generate a BSP dungeon and stamp named prefab rooms into suitable leaves. Returns dungeon layout plus prefab placement info.
- `lurek.procgen.roomsDungeon`: Generate a dungeon by placing random non-overlapping rooms and connecting them with corridors. Also returns a full tile grid.
- `lurek.procgen.roomsDungeonWithPrefabs`: Generate a rooms-based dungeon and place named prefabs into qualifying rooms. Prefabs can have custom shape masks.
- `lurek.procgen.heightmap`: Generate a fractal heightmap using multi-octave noise with optional hydraulic erosion.
- `lurek.procgen.heightmapFromCellular`: Convert a cellular automata grid into a heightmap by distance-transforming the floor cells.
- `lurek.procgen.wfcGenerate`: Run Wave Function Collapse to generate a grid of tile IDs satisfying adjacency constraints.
- `lurek.procgen.lsystem`: Expand an L-system grammar and return the resulting string. Useful for generating branching structures like trees, rivers, or cave networks.
- `lurek.procgen.lsystemSegments`: Expand an L-system and interpret the result as turtle-graphics commands, returning line segments.
- `lurek.procgen.generateName`: Generate a single random name based on a Markov chain trained from sample names. Great for NPC names, place names, or item names.
- `lurek.procgen.generateNames`: Generate multiple random names in one call using Markov chains trained from sample data.
- `lurek.procgen.worldGraph`: Generate a connected world graph with named regions and weighted edges. Useful for overworld maps, trade routes, or quest connectivity.
- `lurek.procgen.noiseMap`: Generate a 2D noise map with configurable scale, octaves, and offsets. Runs on a single thread.
- `lurek.procgen.noiseMapParallel`: Generate a 2D noise map using multiple threads for faster computation on large maps. Uses seed 0.
- `lurek.procgen.noiseMapParallelSeeded`: Generate a 2D noise map using multiple threads with a specific seed for reproducible results.
- `lurek.procgen.simplex2d`: Sample 2D simplex noise at a point. Returns a value roughly in [-1, 1].
- `lurek.procgen.simplex3d`: Sample 3D simplex noise at a point. The third axis can be used for animation or layering.
- `lurek.procgen.newBiomeClassifier`: Create a BiomeClassifier object with custom threshold rules for mapping height/moisture/temperature to biome types.
- `lurek.procgen.biomeColor`: Get the default RGBA display color for a biome type name. Useful for minimap or debug visualization.

### `BiomeClassifier` Methods
- `BiomeClassifier:classify`: Classify a single point into a biome type based on its environmental parameters.
- `BiomeClassifier:classifyMap`: Classify an entire grid of points into biome types in bulk.
- `BiomeClassifier:type`: Returns the type name of this object.
- `BiomeClassifier:typeOf`: Check whether this object matches a given type name.

## References

- `image`: Imports or references `src/image/`. Cross-group dependency from ``Foundations.`` into `Platform Services`.
- `render`: Imports or references `src/render/`. Cross-group dependency from ``Foundations.`` into `Platform Services`.

## Notes

- Keep this module reference synchronized with `src/procgen/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.

### 2026-05-12 Update

- Added biome classification layer (`src/procgen/biome.rs`):
	- `BiomeType`, `BiomeRules`, `BiomeClassifier`
	- `BiomeClassifier::classify`, `BiomeClassifier::classify_map`
	- `biome_map_to_rgba`
- Added Lua API in `lurek.procgen`:
	- `newBiomeClassifier(opts?)`
	- `biomeColor(name)`
	- Userdata methods: `BiomeClassifier:classify`, `BiomeClassifier:classifyMap`, `BiomeClassifier:type`, `BiomeClassifier:typeOf`.

- Added prefab stamping support for dungeon generators:
	- Rust: `rooms_dungeon_with_prefabs(opts, prefabs, stamp_value)`
	- Rust: `bsp_dungeon_with_prefabs(opts, prefabs)`
	- Lua: `lurek.procgen.roomsDungeonWithPrefabs(opts?, prefabs, stamp_value?)`
	- Lua: `lurek.procgen.bspDungeonWithPrefabs(opts?, prefabs)`
	- Prefab placement metadata is returned to Lua for deterministic post-processing.

- Added Heightmap helper constructors:
	- `Heightmap::from_noise_map(width, height, values)`
	- `Heightmap::from_cellular(width, height, cells, floor_value)`
	- Lua: `lurek.procgen.heightmapFromCellular(width, height, cells, floor_value?)`

- Added seeded parallel map generation:
	- Rust: `NoiseGenerator::generate_map_parallel(width, height, opts)`
	- Lua: `lurek.procgen.noiseMapParallelSeeded(width, height, opts?)`

- Deduplicated scalar-map grayscale conversion:
	- Shared helper: `scalar_map_to_rgba_bytes(values)`
	- Used by `Heightmap::to_rgba_bytes` and `NoiseGrid::to_rgba_bytes`.
