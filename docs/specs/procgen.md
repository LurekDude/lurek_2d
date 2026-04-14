# procgen

## General Info

- Module group: `Foundations.`
- Source path: `src/procgen/`
- Lua API path(s): `src/lua_api/procgen_api.rs`
- Primary Lua namespace: `lurek.procgen`
- Rust test path(s): none found in the workspace
- Lua test path(s): none found in the workspace

## Summary

The `procgen` module is Lurek2D's procedural content generation library. It is a Foundations tier module that depends only on `math`, enabling all generators to run headlessly in tests and pre-generation passes without a window or GPU.

Noise: `perlin2d`, `perlin3d`, `perlin4d`, `simplex2d`, `simplex_noise_3d` are direct noise functions. `NoiseGenerator` is a configurable wrapper with `NoiseKind` (Perlin, Simplex, Worley), `FractalType` (fBm, Ridged, Billow, plain), octaves, lacunarity, gain, and frequency. `generate_noise_map_parallel` fills a 2D grid using Rayon for fast multi-threaded generation. `perlin_noise_periodic` generates tileable Perlin noise for seamless textures.

Dungeon generation: `bsp_dungeon(opts)` uses Binary Space Partitioning; `rooms_dungeon(opts)` uses random room placement with connected corridors; `cellular_automata(opts)` applies Game-of-Life cave smoothing. `Heightmap` generates terrain using fractal noise, hydraulic erosion passes, and normalization to [0, 1].

Strategic generation: `voronoi_diagram(points, warp)` generates Voronoi cells with optional domain-warp for organic shapes. `WorldGraph` stores `WorldRegion` nodes and `WorldEdge` connections with MST and pathfinding. `WfcGrid` implements Wave Function Collapse for tile-based constraint-driven map generation. `LSystem` performs string rewriting via production rules for plants, dungeons, and fractal structures. `NameGen` is a Markov-chain name generator trained on a provided word list. `poisson_disk(area, min_dist, tries)` samples points with guaranteed minimum spacing for natural scatter patterns.

**Scope boundary**: Foundations tier. Depends only on `math`. Lua bridge in `src/lua_api/procgen_api.rs`.

## Files

- `bsp.rs`: Binary Space Partitioning dungeon generator.
- `cellular.rs`: Cellular automata map generation with configurable fill, birth, survive, and iteration settings.
- `flood_fill.rs`: Threshold-based BFS flood fill over flat byte grids.
- `heightmap.rs`: Heightmap generation using fractal noise, erosion, and normalization.
- `lcg.rs`: Internal deterministic random generator shared by the generation algorithms.
- `lsystem.rs`: L-system string rewriter for procedural plant and structure generation.
- `mod.rs`: Module root and re-export surface for the public generation functions and option structs.
- `namegen.rs`: Markov chain name generator.
- `noise.rs`: Procedural noise functions and generators: Perlin, Simplex, Worley, fractal combinators.
- `noise_ext.rs`: Periodic Perlin noise that tiles cleanly across configurable wrap periods.
- `poisson.rs`: Bridson-style Poisson-disk sampling for evenly spaced point placement.
- `render.rs`: `NoiseGrid` sampling and visualization helpers for command-queue or CPU-image inspection.
- `rooms.rs`: Rooms-and-corridors dungeon generator with random scatter placement.
- `voronoi.rs`: Voronoi region, nearest-distance, and second-distance field generation with optional warp.
- `wfc.rs`: Wave Function Collapse tile grid generator.
- `world_graph.rs`: World-level topology graph: regions connected by traversable edges.

## Types

- `BspRoom` (`struct`, `bsp.rs`): A room placed within the dungeon.
- `BspDungeon` (`struct`, `bsp.rs`): A generated BSP dungeon.
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
- `NoiseGrid` (`struct`, `render.rs`): Sampled noise buffer that can be exported as render commands or a CPU image.
- `NoiseGrid` (`struct`, `render.rs`): Sampled noise buffer that can be exported as render commands or a CPU image.
- `Room` (`struct`, `rooms.rs`): A placed room in the dungeon.
- `RoomsOpts` (`struct`, `rooms.rs`): Options for rooms-and-corridors generation.
- `RoomsDungeon` (`struct`, `rooms.rs`): The result of rooms-and-corridors generation.
- `VoronoiOpts` (`struct`, `voronoi.rs`): Configuration bundle for Voronoi generation and optional domain warping.
- `WfcTile` (`struct`, `wfc.rs`): A weighted tile for WFC generation.
- `WfcRules` (`struct`, `wfc.rs`): Adjacency rules: maps each tile ID to the set of tile IDs that may appear beside it.
- `WfcOpts` (`struct`, `wfc.rs`): Options for WFC generation.
- `WfcGrid` (`struct`, `wfc.rs`): The generated grid.
- `WorldRegion` (`struct`, `world_graph.rs`): A region (node) in the world graph.
- `WorldEdge` (`struct`, `world_graph.rs`): An edge connecting two regions.
- `WorldGraph` (`struct`, `world_graph.rs`): A world-level topology graph.

## Functions

- `bsp_dungeon` (`bsp.rs`): Generate a BSP dungeon from the given options.
- `cellular_automata` (`cellular.rs`): Generates a cave/dungeon map using cellular automata.
- `flood_fill` (`flood_fill.rs`): BFS flood fill on a flat grid, returning a binary mask of all cells reachable from a seed position whose values satisfy `threshold`.
- `Heightmap::generate` (`heightmap.rs`): Generate a heightmap from the given options.
- `Heightmap::get` (`heightmap.rs`): Get the elevation at `(x, y)`, clamped to valid range.
- `Heightmap::normalize` (`heightmap.rs`): Normalize all elevation values to [0, 1].
- `Heightmap::erode` (`heightmap.rs`): Apply simplified hydraulic erosion: sediment flows from high to low neighbours.
- `Heightmap::to_rgba_bytes` (`heightmap.rs`): Convert the heightmap to RGBA bytes (grayscale: `r = g = b = height * 255`, `a = 255`).
- `Lcg::new` (`lcg.rs`): Creates a new LCG seeded with the given value.
- `Lcg::next` (`lcg.rs`): Returns the next pseudo-random `u64`.
- `Lcg::next_f32` (`lcg.rs`): Returns the next pseudo-random `f32` in [0, 1).
- `LSystem::new` (`lsystem.rs`): Create a new L-system.
- `LSystem::new_from_pairs` (`lsystem.rs`): Create a new L-system from owned-string rule pairs.
- `LSystem::generate` (`lsystem.rs`): Run the rewriting rules for `self.iterations` steps and return the resulting string.
- `LSystem::to_segments` (`lsystem.rs`): Interpret the generated string as turtle-graphics commands and return line segments.
- `NameGen::new` (`namegen.rs`): Build a name generator from training examples.
- `NameGen::generate` (`namegen.rs`): Generate a single name with length in `[min_len, max_len]`.
- `NameGen::generate_n` (`namegen.rs`): Generate `n` names.
- `perlin2d` (`noise.rs`): Generates 2D Perlin noise at the given coordinates.
- `simplex2d` (`noise.rs`): Generates 2D Simplex noise at the given coordinates.
- `simplex_noise_2d` (`noise.rs`): Returns 2D simplex noise using a fixed seed of 0.
- `simplex_noise_3d` (`noise.rs`): Returns 3D simplex noise using a fixed seed of 0.
- `fbm` (`noise.rs`): Generates fractal Brownian motion noise by layering multiple octaves of Perlin noise.
- `perlin3d` (`noise.rs`): Generates 3D Perlin noise at the given coordinates.
- `perlin4d` (`noise.rs`): Generates 4D Perlin noise at the given coordinates.
- `generate_noise_map_parallel` (`noise.rs`): Generate a noise map in parallel using rayon.
- `NoiseGenerator::new` (`noise.rs`): Creates a new generator with the given seed.
- `NoiseGenerator::set_seed` (`noise.rs`): Replaces the seed and rebuilds the permutation table.
- `NoiseGenerator::seed` (`noise.rs`): Returns the current seed.
- `NoiseGenerator::perlin_1d` (`noise.rs`): 1D Perlin noise.
- `NoiseGenerator::perlin_2d` (`noise.rs`): 2D Perlin noise.
- `NoiseGenerator::perlin_3d` (`noise.rs`): 3D Perlin noise.
- `NoiseGenerator::simplex_2d` (`noise.rs`): 2D Simplex noise.
- `NoiseGenerator::simplex_3d` (`noise.rs`): 3D Simplex noise.
- `NoiseGenerator::simplex_4d` (`noise.rs`): 4D Simplex noise.
- `NoiseGenerator::worley_2d` (`noise.rs`): 2D Worley (cellular) noise.
- `NoiseGenerator::worley_3d` (`noise.rs`): 3D Worley (cellular) noise.
- `NoiseGenerator::fbm` (`noise.rs`): Fractal Brownian motion over a 2D point.
- `NoiseGenerator::ridged` (`noise.rs`): Ridged multi-fractal over a 2D point.
- `NoiseGenerator::turbulence` (`noise.rs`): Turbulence noise over a 2D point.
- `NoiseGenerator::warp_domain` (`noise.rs`): Domain warping — offsets input coordinates by noise for organic distortion.
- `NoiseGenerator::generate_map` (`noise.rs`): Generates a 2D noise map of `width * height` values using the given options.
- `perlin_noise_periodic` (`noise_ext.rs`): Periodic Perlin noise that tiles over period (px, py).
- `poisson_disk` (`poisson.rs`): Generates Poisson disk sample points using Bridson's algorithm.
- `NoiseGrid::from_perlin` (`render.rs`): Sample periodic Perlin noise onto a grid and return a plain data buffer.
- `NoiseGrid::to_rgba_bytes` (`render.rs`): Return a greyscale RGBA byte buffer (4 bytes per pixel, `width * height * 4` total).
- `NoiseGrid::from_perlin` (`render.rs`): Sample periodic Perlin noise onto a grid and return a plain data buffer.
- `NoiseGrid::to_rgba_bytes` (`render.rs`): Return a greyscale RGBA byte buffer (4 bytes per pixel, `width * height * 4` total).
- `NoiseGrid::from_perlin` (`render.rs`): Sample periodic Perlin noise onto a grid.
- `NoiseGrid::generate_render_commands` (`render.rs`): Generate render commands visualising the noise grid as a greyscale tile mosaic.
- `NoiseGrid::draw_to_image` (`render.rs`): Render the noise grid to a CPU image.
- `rooms_dungeon` (`rooms.rs`): Generate a rooms-and-corridors dungeon.
- `voronoi_diagram` (`voronoi.rs`): Generates a Voronoi diagram over a `width × height` grid for the given seed points.
- `wfc_generate` (`wfc.rs`): Generate a WFC tile grid.
- `WorldGraph::new` (`world_graph.rs`): Create an empty world graph.
- `WorldGraph::add_region` (`world_graph.rs`): Add a region and return its ID.
- `WorldGraph::add_edge` (`world_graph.rs`): Connect two regions with an edge.
- `WorldGraph::find_path` (`world_graph.rs`): A* pathfinding using Euclidean distance as the heuristic.
- `WorldGraph::reachable_from` (`world_graph.rs`): All regions reachable from `start` within `max_cost` (Dijkstra).
- `WorldGraph::mst` (`world_graph.rs`): Kruskal's Minimum Spanning Tree.
- `WorldGraph::to_regions_list` (`world_graph.rs`): Returns references to all regions.
- `generate_world_graph` (`world_graph.rs`): Scatter `region_count` regions randomly in a `width × height` world and connect each to its k-nearest neighbours (k = 3).

## Lua API Reference

- Binding path(s): `src/lua_api/procgen_api.rs`
- Namespace: `lurek.procgen`

### Module Functions
- `lurek.procgen.cellularAutomata`: Generates a cave-like map using cellular automata.
- `lurek.procgen.floodFill`: BFS flood fill on a flat grid of bytes.
- `lurek.procgen.perlinNoise`: Evaluates periodic Perlin noise at a point.
- `lurek.procgen.poissonDisk`: Generates Poisson disk sample points using Bridson's algorithm.
- `lurek.procgen.voronoi`: Generates a Voronoi diagram for a set of seed points.
- `lurek.procgen.bspDungeon`: Generates a dungeon using Binary Space Partitioning.
- `lurek.procgen.roomsDungeon`: Generates a rooms-and-corridors dungeon.
- `lurek.procgen.heightmap`: Generates a heightmap using fractal noise.
- `lurek.procgen.wfcGenerate`: Generates a tile grid using Wave Function Collapse.
- `lurek.procgen.lsystem`: Generates an L-system string.
- `lurek.procgen.lsystemSegments`: Generates L-system line segments for rendering.
- `lurek.procgen.generateName`: Generates a single procedural name using a Markov chain.
- `lurek.procgen.generateNames`: Generates N procedural names using a Markov chain.
- `lurek.procgen.worldGraph`: Generates a world graph with scattered regions and edges.
- `lurek.procgen.noiseMap`: Generates a noise map using the configurable NoiseGenerator.
- `lurek.procgen.noiseMapParallel`: Generates a noise map using rayon parallel processing.
- `lurek.procgen.bspDungeon`: Generates a dungeon using Binary Space Partitioning.
- `lurek.procgen.roomsDungeon`: Generates a rooms-and-corridors dungeon.
- `lurek.procgen.heightmap`: Generates a heightmap using fractal noise.
- `lurek.procgen.wfcGenerate`: Generates a tile grid using Wave Function Collapse.
- `lurek.procgen.lsystem`: Generates an L-system string.
- `lurek.procgen.lsystemSegments`: Generates L-system line segments for rendering.
- `lurek.procgen.generateName`: Generates a single procedural name using a Markov chain.
- `lurek.procgen.generateNames`: Generates N procedural names using a Markov chain.
- `lurek.procgen.worldGraph`: Generates a world graph with scattered regions and edges.
- `lurek.procgen.noiseMap`: Generates a noise map using the configurable NoiseGenerator.
- `lurek.procgen.noiseMapParallel`: Generates a noise map using rayon parallel processing.
- `lurek.procgen.simplex2d`: Returns a single Simplex noise value at the given 2-D coordinate.
- `lurek.procgen.simplex3d`: Returns a single Simplex noise value at the given 3-D coordinate.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/procgen/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
